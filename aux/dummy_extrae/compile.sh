#!/usr/bin/env bash
#
#  Copyright 2002-2025 Barcelona Supercomputing Center (www.bsc.es)
#            2023-2025 King Abdullah University of Science and Technology (www.kaust.edu.sa)
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

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
