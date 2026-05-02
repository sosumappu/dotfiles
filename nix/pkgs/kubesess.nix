{
  stdenv,
  autoPatchelfHook,
  fetchurl,
  lib,
  system,
}: let
  platform =
    {
      "x86_64-linux" = {os = "x86_64-unknown-linux-gnu";};
      "aarch64-linux" = {os = "aarch64-unknown-linux-gnu";};
      "x86_64-darwin" = {os = "x86_64-apple-darwin";};
      "aarch64-darwin" = {os = "aarch64-apple-darwin";};
    }.${
      system
    };
in
  stdenv.mkDerivation rec {
    pname = "kubesess";
    version = "3.0.0";

    src = fetchurl {
      url = "https://github.com/Ramilito/kubesess/releases/download/${version}/kubesess_${version}_${platform.os}.tar.gz";
      hash = "sha256-cWBNPRRRn2xLuBEzvf8l6I1djSRpPC5jYChLtbivEB0=";
    };

    sourceRoot = "."; # tarball has multiple top-level entries

    nativeBuildInputs = lib.optionals stdenv.isLinux [autoPatchelfHook];
    buildInputs = lib.optionals stdenv.isLinux [stdenv.cc.cc.lib];

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      install -Dm755 target/${platform.os}/release/kubesess $out/bin/kubesess
    '';
  }
