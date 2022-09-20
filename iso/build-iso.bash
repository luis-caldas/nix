#!/usr/bin/env bash

# get our folder now
folder_now="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"

nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix "$@"
