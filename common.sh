#!/bin/bash

# Variables and functions used by multiple other scripts

#Black        0;30     Dark Gray     1;30
#Red          0;31     Light Red     1;31
#Green        0;32     Light Green   1;32
#Brown/Orange 0;33     Yellow        1;33
#Blue         0;34     Light Blue    1;34
#Purple       0;35     Light Purple  1;35
#Cyan         0;36     Light Cyan    1;36
#Light Gray   0;37     White         1;37

BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
LTGRAY='\033[0;36m'
DKGRAY='\033[1;30m'
LTRED='\033[1;31m'
LTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LTBLUE='\033[1;34m'
LTPURPLE='\033[1;35m'
LTCYAN='\033[1;36m'
WHITE='\033[1;37m'
NONE='\033[0m' # Return to default

TYPE="qcow2"
GetVmFileType() {
    RSTATUS=1 # FAILED TO GET TYPE
    if [ -z $1 ]; then
        echo "GetVmFileType Required Param: FILENAME"
    else
        if [[ "$FILENAME" =~ "." ]]; then
            EXT=$(echo $FILENAME | awk -F'.' '{ print $2 }')
            if [[ -n $EXT ]]; then
                RSTATUS=0 # SUCCEEDED IN GETTING TYPE
                if [ $EXT == "img" ]; then
                    TYPE="raw"
                elif [[ $EXT = "qcow2" || $EXT = "raw" || $EXT == "qcow" ]]; then
                    TYPE=$EXT
                fi
            fi
        fi
    fi
    return RSTATUS
}
