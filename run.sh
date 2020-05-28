#!/usr/bin/env bash
set -e

if [[ $# -lt 1 ]] ; then
  echo Usage: $0 INPUT_FILE
  exit
fi

if [[ $PLATFORM = "" ]] ; then
  echo Error: \$PLATFORM is not set
  exit
fi

PLATFORM=$(basename $PLATFORM | sed 's/\.xpfm$//')
INPUT=$1; shift
XCLBIN=${XCLBIN:-./build_dir.hw.$PLATFORM/compress_decompress.xclbin}

make host TARGET=hw DEVICE=$PLATFORM
time ./build_dir.hw.$PLATFORM/deflate -x $XCLBIN -i $INPUT $*
