#!/bin/bash

# Add physical ethernet adapter to bridge

if [ -z $1 ]; then
  echo
  echo -e "${RED}Ethernet adapter required param$NONE"
  echo
  exit 1
fi

ip link set $1 master vrbr192
ip a show vrbr192
