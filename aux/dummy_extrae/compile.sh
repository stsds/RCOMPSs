#!/usr/bin/env bash

# Copyright (c) 2025- King Abdullah University of Science and Technology,
# All rights reserved.
# RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_DIR="$(pwd)"

cd ${SCRIPT_DIR}

if [ -f "extrae.o" ]; then
    rm "extrae.o"
fi
if [ -f "libextrae.so" ]; then
    rm "libextrae.so"
fi

# Compile step by step
#gcc -c -fPIC extrae.cc -o extrae.o
#gcc extrae.o -shared -o libpthread.so
# Compile in a sigle line
gcc -shared -o libpthread.so -fPIC extrae.cc

cd ${CURRENT_DIR}
