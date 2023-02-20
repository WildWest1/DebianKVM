#!/bin/bash
# Brings up default nic by default
# Or takes it down if -r is only arg
# Else supply any interface

INT="ens1"

Up() {
  ip a s $INT >/dev/null 2>&1
  [ $? -ne 0 ] && echo "$INT is not a valid interface (use -d for down)" && exit 1
  echo Starting $INT...
  ip link set $INT up
  dhclient $INT
  if [ $? -eq 0 ]; then 
    echo Done!
    exit 0
  else
    echo Failed.
    exit 1
  fi
}

Down() {
  echo Shutting down $INT...
  dhclient -r $INT
  ip link set $INT down
  if [ $? -eq 0 ]; then 
    echo Done!
    exit 0
  else
    echo Failed.
    exit 1
  fi  
}

if [ $# -eq 0 ]; then
  Up
fi

if [ $# -eq 1 ]; then
  if [[ "$1" == "-d" || "$1" == "d" ]]; then
    Down
  else
    INT="$1"
    Up
  fi
fi

if [ $# -eq 2 ]; then
  INT="$1"
  Down
fi
