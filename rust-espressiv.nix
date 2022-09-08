{ ... }:

let
  moz_overlay = import (
    builtins.fetchTarball https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz
  );

  pkgs = import <nixpkgs-unstable> { overlays = [ moz_overlay ]; };

  cargo-espflash = pkgs.callPackage ./cargo-espflash.nix { };
  ldproxy = pkgs.callPackage ./ldproxy.nix { };

  channel = pkgs.rustChannelOf {
    channel = "nightly";
    date = "2022-03-10";
  };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    channel.rust-std
    channel.rust-src
    (channel.rust.override { extensions = ["rust-src" ]; })
    channel.rustc
    channel.cargo

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
    cargo-llvm-lines

    cargo-espflash
    ldproxy

    llvm
    libclang
    clang
    openssl
    pkg-config
  ];

  shellHook = ''
    export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

    echo " rustc: ''$(rustc --version)"
    echo " cargo: ''$(cargo --version)"
    echo "... have fun!"
  '';

  LIBCLANG_PATH   = "${pkgs.llvmPackages.libclang}/lib";
}
