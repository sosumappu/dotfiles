let
  module = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.prometheus;
    inherit (config.my.modules) ntfy;
  in {
    options = with lib; {
      my.modules.prometheus = {
        port = mkOption {
          type = types.port;
          default = 9090;
        };

        retentionTime = mkOption {
          type = types.str;
          default = "30d";
          example = "90d";
        };

        exporters = {
          node = {
            port = mkOption {
              type = types.port;
              default = 9100;
            };
            enabledCollectors = mkOption {
              type = types.listOf types.str;
              default = [
                "cpu"
                "diskstats"
                "filesystem"
                "loadavg"
                "meminfo"
                "netdev"
                "netstat"
                "os"
                "stat"
                "systemd"
                "time"
                "uname"
              ];
            };
            disabledCollectors = mkOption {
              type = types.listOf types.str;
              default = ["ipvs" "zfs" "infiniband"];
            };
          };

          systemd = {
            port = mkOption {
              type = types.port;
              default = 9558;
            };
            unitWhitelist = mkOption {
              type = types.str;
              default = ".+\\.service";
              example = "(vaultwarden|immich|syncthing).+\\.service";
            };
          };

          process = {
            port = mkOption {
              type = types.port;
              default = 9256;
            };
            groups = mkOption {
              type = types.listOf (types.submodule {
                options = {
                  name = mkOption {type = types.str;};
                  cmdlineMatchers = mkOption {
                    type = types.listOf types.str;
                    default = [];
                  };
                  commMatchers = mkOption {
                    type = types.listOf types.str;
                    default = [];
                  };
                };
              });
              default = [
                {
                  name = "immich";
                  cmdlineMatchers = ["immich" "node /usr/src/app"];
                }
                {
                  name = "vaultwarden";
                  commMatchers = ["vaultwarden"];
                }
                {
                  name = "syncthing";
                  commMatchers = ["syncthing"];
                }
                {
                  name = "adguardhome";
                  commMatchers = ["AdGuardHome"];
                }
              ];
            };
          };
        };

        extraScrapeConfigs = mkOption {
          type = types.listOf types.attrs;
          default = [];
          example = [
            {
              job_name = "berry-node";
              static_configs = [{targets = ["berry:9100"];}];
            }
          ];
        };

        alertmanager = {
          port = mkOption {
            type = types.port;
            default = 9093;
          };

          ntfyTokenFile = mkOption {
            type = types.str;
            default = "/etc/secrets/alertmanager-ntfy-token";
          };

          ntfyTopics = {
            critical = mkOption {
              type = types.str;
              default = "homelab-alerts";
            };
            warning = mkOption {
              type = types.str;
              default = "homelab-alerts";
            };
            info = mkOption {
              type = types.str;
              default = "homelab-info";
            };
          };

          # Timing knobs
          groupWait = mkOption {
            type = types.str;
            default = "30s";
          };
          groupInterval = mkOption {
            type = types.str;
            default = "5m";
          };
          repeatInterval = mkOption {
            type = types.str;
            default = "4h";
          };

          extraRules = mkOption {
            type = types.listOf types.attrs;
            default = [];
            description = "Extra alert rule groups appended after the built-in homelab rules";
          };
        };
      };
    };

    config = with lib; let
      # ------------------------------------------------------------------ #
      # process-exporter config                                              #
      # ------------------------------------------------------------------ #
      processExporterConfig = pkgs.writeText "process-exporter.yaml" (
        builtins.toJSON {
          process_names =
            map (g: {
              name = "{{.Matches}}";
              cmdline = g.cmdlineMatchers;
              comm = g.commMatchers;
            })
            cfg.exporters.process.groups;
        }
      );

      # ------------------------------------------------------------------ #
      # Alert rules                                                          #
      # ------------------------------------------------------------------ #
      defaultRules = [
        {
          name = "homelab.node";
          rules = [
            {
              alert = "HostHighCpuLoad";
              expr = ''100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80'';
              for = "10m";
              labels.severity = "warning";
              annotations.summary = "High CPU on {{ $labels.instance }} ({{ printf \"%.0f\" $value }}%)";
            }
            {
              alert = "HostLowDisk";
              expr = ''(node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 15'';
              for = "5m";
              labels.severity = "warning";
              annotations.summary = "Low disk on {{ $labels.instance }} ({{ printf \"%.0f\" $value }}% free)";
            }
            {
              alert = "HostCriticalDisk";
              expr = ''(node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 5'';
              for = "2m";
              labels.severity = "critical";
              annotations.summary = "Critical disk on {{ $labels.instance }} ({{ printf \"%.0f\" $value }}% free)";
            }
            {
              alert = "HostHighMemory";
              expr = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90";
              for = "10m";
              labels.severity = "warning";
              annotations.summary = "High memory on {{ $labels.instance }} ({{ printf \"%.0f\" $value }}%)";
            }
          ];
        }
        {
          name = "homelab.services";
          rules = [
            {
              alert = "ServiceFailed";
              expr = ''systemd_unit_state{state="failed"} == 1'';
              for = "2m";
              labels.severity = "critical";
              annotations.summary = "{{ $labels.name }} failed on {{ $labels.instance }}";
            }
            {
              alert = "ServiceFrequentRestarts";
              expr = "rate(systemd_unit_restart_total[15m]) > 0.1";
              for = "5m";
              labels.severity = "warning";
              annotations.summary = "{{ $labels.name }} restarting frequently on {{ $labels.instance }}";
            }
          ];
        }
        {
          name = "homelab.backups";
          rules = [
            # Push a timestamp from your restic backupCleanupCommand:
            #   echo "restic_last_success_timestamp_seconds $(date +%s)" | \
            #     curl --data-binary @- http://localhost:9091/metrics/job/restic/instance/$(hostname)
            {
              alert = "BackupTooOld";
              expr = "time() - restic_last_success_timestamp_seconds > 86400 * 2";
              for = "1h";
              labels.severity = "warning";
              annotations.summary = "Backup {{ $labels.job }} hasn't run in 2 days on {{ $labels.instance }}";
            }
          ];
        }
      ];

      rulesFile = pkgs.writeText "homelab-alerts.yaml" (
        builtins.toJSON {groups = defaultRules ++ cfg.alertmanager.extraRules;}
      );

      # ------------------------------------------------------------------ #
      # Alertmanager config — built from my.modules.ntfy                    #
      # ------------------------------------------------------------------ #
      alertmanagerConfig = {
        global = {
          resolve_timeout = "5m";
        };

        route = {
          receiver = "ntfy-warning";
          group_by = ["alertname" "instance" "severity"];
          group_wait = cfg.alertmanager.groupWait;
          group_interval = cfg.alertmanager.groupInterval;
          repeat_interval = cfg.alertmanager.repeatInterval;
          routes = [
            {
              matchers = ["severity=\"critical\""];
              receiver = "ntfy-critical";
            }
            {
              matchers = ["severity=\"warning\""];
              receiver = "ntfy-warning";
            }
            {
              matchers = ["severity=\"info\""];
              receiver = "ntfy-info";
            }
          ];
        };

        receivers = [
          {
            name = "ntfy-critical";
            webhook_configs = [
              {
                url = "${ntfy.baseUrl}/${cfg.alertmanager.ntfyTopics.critical}";
                send_resolved = true;
                http_config.authorization = {
                  type = "Bearer";
                  credentials_file = cfg.alertmanager.ntfyTokenFile;
                };
                # ntfy reads Title and Priority from these custom HTTP headers
                # passed via the webhook body's JSON — we embed them in the
                # message template instead since alertmanager webhooks POST JSON.
                max_alerts = 10;
              }
            ];
          }
          {
            name = "ntfy-warning";
            webhook_configs = [
              {
                url = "${ntfy.baseUrl}/${cfg.alertmanager.ntfyTopics.warning}";
                send_resolved = true;
                http_config.authorization = {
                  type = "Bearer";
                  credentials_file = cfg.alertmanager.ntfyTokenFile;
                };
                max_alerts = 10;
              }
            ];
          }
          {
            name = "ntfy-info";
            webhook_configs = [
              {
                url = "${ntfy.baseUrl}/${cfg.alertmanager.ntfyTopics.info}";
                send_resolved = true;
                http_config.authorization = {
                  type = "Bearer";
                  credentials_file = cfg.alertmanager.ntfyTokenFile;
                };
                max_alerts = 10;
              }
            ];
          }
        ];

        inhibit_rules = [
          # Don't send a warning when a critical for the same alert+instance is firing
          {
            source_matchers = ["severity=\"critical\""];
            target_matchers = ["severity=\"warning\""];
            equal = ["alertname" "instance"];
          }
        ];
      };

      localScrapes = [
        {
          job_name = "node";
          static_configs = [{targets = ["localhost:${toString cfg.exporters.node.port}"];}];
        }
        {
          job_name = "systemd";
          static_configs = [{targets = ["localhost:${toString cfg.exporters.systemd.port}"];}];
        }
        {
          job_name = "process";
          static_configs = [{targets = ["localhost:${toString cfg.exporters.process.port}"];}];
        }
      ];
    in {
      services.prometheus.exporters.node = {
        enable = true;
        inherit (cfg.exporters.node) port enabledCollectors disabledCollectors;
      };

      services.prometheus.exporters.process = {
        enable = true;
        inherit (cfg.exporters.process) port;
        settings.process_names =
          map (g: {
            name = "{{.Matches}}";
            cmdline = g.cmdlineMatchers;
            comm = g.commMatchers;
          })
          cfg.exporters.process.groups;
      };

      services.prometheus.exporters.systemd = {
        enable = true;
        inherit (cfg.exporters.systemd) port;
        extraFlags = [
          "--systemd.collector.unit-include=${cfg.exporters.systemd.unitWhitelist}"
        ];
      };

      services.prometheus = {
        enable = true;
        inherit (cfg) port retentionTime;
        ruleFiles = [rulesFile];
        scrapeConfigs = localScrapes ++ cfg.extraScrapeConfigs;
        alertmanagers = [
          {
            static_configs = [{targets = ["localhost:${toString cfg.alertmanager.port}"];}];
          }
        ];
      };

      services.prometheus.alertmanager = {
        enable = true;
        inherit (cfg.alertmanager) port;
        configuration = alertmanagerConfig;
      };
    };
  };
in {
  flake.modules.nixos.prometheus = module;
}
