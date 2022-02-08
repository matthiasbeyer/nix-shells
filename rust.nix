{ cargobins ? false
, channel ? "stable"
, target ? "default"
, ... }:

let
  moz_overlay = import (
    builtins.fetchTarball https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz
  );

  pkgs = import <nixpkgs-unstable> { overlays = [ moz_overlay ]; };

  rustChannelAllTargets = pkgs.rustChannels.stable.rust.override {
    targets = [
      "armv7-unknown-linux-gnueabihf"
    ];
  };

  targets = {
    aarch64-unknown-linux-gnu = {
      rustPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "aarch64-unknown-linux-gnu" ]; })
      ];

      environment = {
      };
    };

    aarch64-unknown-linux-musl = {
      rustPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "aarch64-unknown-linux-musl" ]; })
        pkgs.pkgsCross.aarch64-multiplatform-musl.buildPackages.gcc
      ];

      environment = {
        CC = "aarch64-unknown-linux-musl-gcc";
      };
    };

    arm-unknown-linux-gnueabihf = {
      rustPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "arm-unknown-linux-gnueabihf" ]; })
      ];

      environment = {
      };
    };

    armv7-unknown-linux-gnu = {
      rustPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "armv7-unknown-linux-gnueabihf" ]; })
        pkgs.pkgsCross.armv7l-hf-multiplatform.buildPackages.gcc
      ];

      environment = {
        CC_armv7-unknown-linux-gnueabihf = "armv7l-unknown-linux-gnueabihf-gcc";
        CC = "armv7l-unknown-linux-gnueabihf-gcc";
      };
    };

    armv7-unknown-linux-musleabihf = {
      rustPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "armv7-unknown-linux-musleabihf" ]; })
        pkgs.pkgsCross.armv7l-hf-multiplatform.buildPackages.gcc
      ];

      environment = {
        CC_armv7-unknown-linux-musleabihf = "armv7l-unknown-linux-gnueabihf-gcc";
      };
    };

    default = {
      rustPackages = with (pkgs.rustChannelOf { inherit channel; }); [
        rust-std
        rust-src
        rust
        rustc
        cargo
      ];

      environment = { };
    };
  };
in
pkgs.mkShell {
  buildInputs = targets."${target}".rustPackages
  ++ pkgs.lib.optionals cargobins (with pkgs; [
    cargo-audit
    cargo-bloat
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
  ]);

  LIBCLANG_PATH   = "${pkgs.llvmPackages.libclang}/lib";
} // targets."${target}".environment

