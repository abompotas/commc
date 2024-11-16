#!/bin/bash

cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $cwd

#Network interfaces initialization
./init-network.sh

#GUI initialization
./init-gui.sh

#Restart the system
shutdown -r now