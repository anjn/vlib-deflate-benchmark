#!/usr/bin/env bash

if [[ $PLATFORM = "" ]] ; then
  echo Error: \$PLATFORM is not set
  exit
fi

time make build TARGET=hw DEVICE=$PLATFORM -j
