/*
 *  Copyright 2002-2025 Barcelona Supercomputing Center (www.bsc.es)
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
#ifndef EXTRAE_H_   /* Include guard */
#define EXTRAE_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned extrae_type_t;
typedef unsigned extrae_value_t;

void Extrae_init (void);
void Extrae_fini (void);
void Extrae_flush (void);
void Extrae_eventandcounters (extrae_type_t type, extrae_value_t value);

#ifdef __cplusplus
}
#endif

#endif // EXTRAE_H_
