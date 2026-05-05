# NOTE:
# I don't plan to use this to store secrets or private keys/vars/etc... because
# it's not 100% safe.
#
# - https://github.com/ryantm/agenix#threat-modelwarnings
# - https://github.com/FiloSottile/age/issues/578
#
# Instead I use it to store info that's not really secret, but I'd rather keep
# it private.
#
# I prefer to regenerate keys, env vars, tokens, etc... on every new machine
# I get. It's annoying but more secure.
#
# Agenix secrets configuration
# Defines which SSH public keys can decrypt which secrets
#
# To encrypt a new secret:
#   agenix -e <secret-name>.age
#
# To rekey all secrets after adding/removing keys:
#   agenix -r
let
  # Host SSH keys (from /etc/ssh/ssh_host_ed25519_key.pub)
  # Run: cat /etc/ssh/ssh_host_ed25519_key.pub
  erdnase = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILGtpDc+d2hinuG8VTlxhc5infICbdDoWFroRzeqwIEO erdnase";
  berry = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPdEk0bNeXOQMISdnWVM7SYZDiKERUwF9DC1jtB168n berry";
  silvana = "";

  allHosts = [erdnase berry silvana];

  # These are in 1Password
  # work = "";
  personal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF1uj9DgHdyYxOezFk2GhrgdFR8DWoXXVr/O2g2CMfG adel";

  allUsers = [personal];

  allKeys = allHosts ++ allUsers;
in {
  "cloudflared.json.age".publicKeys = [personal berry];
  "npmrc.age".publicKeys = allKeys;
}
