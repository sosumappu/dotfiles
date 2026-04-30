{ stdenv
, autoPatchelfHook
, fetchurl
, lib
, system
}:

let
  platform = {
    "x86_64-linux"  = { os = "x86_64-unknown-linux-gnu";};
    "aarch64-linux" = { os = "aarch64-unknown-linux-gnu"; };
    "x86_64-darwin" = { os = "x86_64-apple-darwin"; };
    "aarch64-darwin"= { os = "aarch64-apple-darwin"; };
  }.${system};

in stdenv.mkDerivation rec {
  pname = "kubesess";
  version = "3.0.0";

  src = fetchurl {
    url
                = "https://github.com/Ramilito/kubesess/releases/download/${version}/kubesess_${version}_${platform.os}.tar.gz";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # fake, nix will tell you the real one
  };

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];
  buildInputs      = lib.optionals stdenv.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    mkdir -p $out/bin
    tar xf $src kubesess
    install -m755 kubesess $out/bin/kubesess
  '';
}
