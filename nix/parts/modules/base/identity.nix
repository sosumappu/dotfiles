{lib, ...}:
with lib; let
  mkOptStr = value:
    mkOption {
      type = with types; uniq str;
      default = value;
    };
in {
  options.my = {
    name = mkOptStr "Adel Arab";
    timezone = mkOptStr "Europe/Paris";
    username = mkOptStr "localhost";
    website = mkOptStr "";
    github_username = mkOptStr "sosumappu";
    email = mkOptStr "";
    company = mkOptStr "";
    devFolder = mkOptStr "dev";
    syncFolder = mkOptStr "sync";
    nix_managed = mkOptStr "vim: set nomodifiable : Nix managed - DO NOT EDIT - see source inside ~/.dotfiles or use `:set modifiable` to force.";
    hostConfigHome = mkOptStr "";
  };
}
