let
  module = {
    generic = {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }: let
      inherit (config.home-manager.users."${config.my.username}") xdg;

      kubectl-with-plugins = inputs.krew2nix.packages.${pkgs.system}.kubectl.withKrewPlugins (plugins: with plugins; [
        access-matrix
        blame
        cost
        datree
        deprecations
        get-all
        images
        konfig
        kubescape
        kyverno
        modify-secret
        neat
        node-shell
        outdated
        rbac-tool
        resource-capacity
        score
        slice
        sniff
        tree
        tunnel
        view-allocations
        who-can
      ]);

     in {
      config = with lib; {
        my.user.packages = with pkgs; [
          datree
          yq
          k9s
          k3d
          kubectx        # ships kubectx + kubens together
          kubecolor
          kustomize
          popeye
          stern
          krew
          kubernetes-helm
          kubectl-with-plugins
          kubesess
          openshift
        ];
      };
    };

    homeManager = _: {
      xdg.configFile = {
        "k9s" = {
          recursive = true;
          source = ../../../../config/k9s;
        };
      };
    };
  };
in {
  flake = {
    modules = {
      generic.kubernetes = module.generic;
      homeManager.kubernetes = module.homeManager;
    };
  };
}
