{ cargobins ? false
, channel ? "stable"
, target ? "default"
, ... }:

let
  moz_overlay = import (
    builtins.fetchTarball https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz
  );

  pkgs = import <nixpkgs-unstable> { overlays = [ moz_overlay ]; };

  targets = {
    aarch64-unknown-linux-gnu = let
      crossPkgs = import <nixpkgs> {
        overlays = [ moz_overlay ];
        crossSystem = {
          config = "aarch64-unknown-linux-gnu";
          libc = "glibc";

          rustc.config = "aarch64-unknown-linux-gnu";
        };
      };
    in {
      rustPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "aarch64-unknown-linux-gnu" ]; })
        crossPkgs.buildPackages.gcc
      ];

      environment = {
      };
    };

    aarch64-unknown-linux-musl = let
      crossPkgs = import <nixpkgs> {
        overlays = [ moz_overlay ];
        crossSystem = {
          config = "aarch64-unknown-linux-musl";
          libc = "musl";

          rustc.config = "aarch64-unknown-linux-musl";
        };
      };
    in {
      rustPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "aarch64-unknown-linux-musl" ]; })
        crossPkgs.buildPackages.gcc
      ];

      environment = {
        CC = "aarch64-unknown-linux-musl-gcc";
      };
    };

    arm-unknown-linux-gnueabihf = let
      crossPkgs = import <nixpkgs> {
        overlays = [ moz_overlay ];
        crossSystem = {
          config = "arm-unknown-linux-gnueabihf";
          libc = "glibc";

          rustc.config = "arm-unknown-linux-gnueabihf";
        };
      };
    in {
      rustPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "arm-unknown-linux-gnueabihf" ]; })
        crossPkgs.buildPackages.gcc
      ];

      environment = {
      };
    };

    armv7-unknown-linux-gnu = let
      crossPkgs = import <nixpkgs> {
        overlays = [ moz_overlay ];
        crossSystem = {
          config = "armv7l-unknown-linux-gnueabihf";
          libc = "glibc";

          rustc.config = "armv7-unknown-linux-gnueabihf";
        };
      };
    in {
      rustPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "armv7-unknown-linux-gnueabihf" ]; })
        crossPkgs.buildPackages.gcc
      ];

      environment = {
        CC_armv7-unknown-linux-gnueabihf = "armv7l-unknown-linux-gnueabihf-gcc";
        CC = "armv7l-unknown-linux-gnueabihf-gcc";
      };
    };

    armv7-unknown-linux-musleabihf = let
      crossPkgs = import <nixpkgs> {
        overlays = [ moz_overlay ];
        crossSystem = {
          config = "armv7l-unknown-linux-musleabihf";
          libc = "musl";

          rustc.config = "armv7l-unknown-linux-musleabihf";
        };
      };
    in {
      rustPackages = [
        (pkgs.rustChannels.stable.rust.override { targets = [ "armv7-unknown-linux-musleabihf" ]; })
        crossPkgs.buildPackages.gcc
      ];

      environment = {
        CC_armv7-unknown-linux-musleabihf = "armv7l-unknown-linux-gnueabihf-gcc";
        CC = "armv7l-unknown-linux-gnueabihf-gcc";
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
