#!/usr/bin/env bash

if [[ $# -lt 1 ]] ; then
  echo Usage: $0 INPUT_FILE
  exit
fi

if [[ $PLATFORM = "" ]] ; then
  echo Error: \$PLATFORM is not set
  exit
fi

INPUT=$1
XCLBIN=${XCLBINL:-./build_dir.hw.$PLATFORM/compress_decompress.xclbin}

make host TARGET=hw DEVICE=$PLATFORM
./build_dir.hw.$PLATFORM/deflate -sx $XCLBIN -c $INPUT
