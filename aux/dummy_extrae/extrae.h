/*
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 */

#ifndef EXTRAE_H_ /* Include guard */
#define EXTRAE_H_

#ifdef __cplusplus
extern "C"
{
#endif

    typedef unsigned extrae_type_t;
    typedef unsigned extrae_value_t;

    void Extrae_init(void);
    void Extrae_fini(void);
    void Extrae_flush(void);
    void Extrae_eventandcounters(extrae_type_t type, extrae_value_t value);

#ifdef __cplusplus
}
#endif

#endif // EXTRAE_H_
