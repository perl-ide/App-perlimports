#!/usr/bin/env bash

# This only needs to be run if author/script/perlimports has changed or if new
# changes to the PPI fork have been pulled in.

set -eux

ROOT_DIR=$PWD

cd inc/PPI || exit
dzil build --in "$ROOT_DIR/.ppi_build"
fatpack-simple --dir "$ROOT_DIR/.ppi_build/lib" -o "$ROOT_DIR/script/perlimports" "$ROOT_DIR/author/script/perlimports"
