#!/usr/bin/env bash

if [[ $PLATFORM = "" ]] ; then
  echo Error: \$PLATFORM is not set
  exit
fi

make build TARGET=hw DEVICE=$PLATFORM
