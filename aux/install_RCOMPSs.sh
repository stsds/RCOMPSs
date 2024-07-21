#!/bin/bash -e

. /home/zhanx0q/RCOMPSs/RCOMPSs/config.sh

cd /home/zhanx0q/RCOMPSs/RCOMPSs

R CMD build RCOMPSs/

R CMD INSTALL RCOMPSs_1.0.tar.gz
