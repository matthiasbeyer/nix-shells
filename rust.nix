{ cargobins ? false
, channel ? "stable"
, stdlibs ? false
, target ? "default"
, ... }:

let
  moz_overlay = import (
    builtins.fetchTarball https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz
  );

  pkgs = import <nixpkgs-unstable> { overlays = [ moz_overlay ]; };

  mkCrossPkgs = triple: libc: (import <nixpkgs> {
    overlays = [ moz_overlay ];
    crossSystem = {
      inherit libc;
      config = triple;
      rustc.config = triple;
    };
  });

  targets = {
    aarch64-unknown-linux-gnu = let
      crossPkgs = mkCrossPkgs "aarch64-unknown-linux-gnu" "glibc";
    in {
      targetPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "aarch64-unknown-linux-gnu" ]; })
        crossPkgs.buildPackages.gcc
      ];

      environment = {
        CC = "aarch64-unknown-linux-gnu-gcc";
      };
    };

    aarch64-unknown-linux-musl = let
      crossPkgs = mkCrossPkgs "aarch64-unknown-linux-musl" "musl";
    in {
      targetPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "aarch64-unknown-linux-musl" ]; })
        crossPkgs.buildPackages.gcc
      ];

      environment = {
        CC = "aarch64-unknown-linux-musl-gcc";
      };
    };

    arm-unknown-linux-gnueabihf = let
      crossPkgs = mkCrossPkgs "arm-unknown-linux-gnueabihf" "glibc";
    in {
      targetPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "arm-unknown-linux-gnueabihf" ]; })
        crossPkgs.buildPackages.gcc
      ];

      environment = {
        CC = "arm-unknown-linux-gnueabihf-gcc";
      };
    };

    armv7-unknown-linux-gnu = let
      crossPkgs = mkCrossPkgs "armv7l-unknown-linux-gnueabihf" "glibc";
    in {
      targetPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "armv7-unknown-linux-gnueabihf" ]; })
        crossPkgs.buildPackages.gcc
      ];

      environment = {
        CC = "armv7l-unknown-linux-gnueabihf-gcc";
      };
    };

    armv7-unknown-linux-musleabihf = let
      crossPkgs = mkCrossPkgs "armv7l-unknown-linux-musleabihf" "musl";
    in {
      targetPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "armv7-unknown-linux-musleabihf" ]; })
        crossPkgs.buildPackages.gcc
      ];

      environment = {
        CC = "armv7l-unknown-linux-musleabihf-gcc";
      };
    };

    default = {
      targetPackages = with (pkgs.rustChannelOf { inherit channel; }); [
        rust-std
        rust-src
        (rust.override { extensions = ["rust-src" ]; })
        rustc
        cargo

        pkgs.llvmPackages.libclang.lib
      ];

      environment = {
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
      };
    };
  };
in
pkgs.mkShell {
  buildInputs = targets."${target}".targetPackages
  ++ pkgs.lib.optionals cargobins (with pkgs; [
    cargo-audit
    cargo-bloat
    cargo-crev
    cargo-deny
    cargo-depgraph
    cargo-deps
    cargo-diet
    cargo-flamegraph
    cargo-geiger
    cargo-graph
    cargo-license
    cargo-modules
    cargo-outdated
    cargo-llvm-lines
    grcov
  ])
  ++ (pkgs.lib.optionals (cargobins && channel == "nightly") (with pkgs; [
    cargo-udeps
  ]))
  ++ (pkgs.lib.optionals stdlibs [
    pkgs.openssl
    pkgs.pkg-config
    pkgs.protobuf
  ]);

  shellHook = ''
    export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

    echo " rustc: ''$(rustc --version)"
    echo " cargo: ''$(cargo --version)"
    echo "... have fun!"
  ''
  + (let
    env = targets."${target}".environment;
    envnames = builtins.attrNames env;
    envslist = builtins.map (name: "export '${name}'=${env."${name}"}") envnames;
    envs = builtins.concatStringsSep "\n" envslist;
  in
    envs
  );

} // targets."${target}".environment

