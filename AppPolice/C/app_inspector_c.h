//
//  app_inspector_c.h
//  AppPolice
//
//  Created by Maksym on 30/10/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#ifndef AppPolice_app_inspector_c_h
#define AppPolice_app_inspector_c_h

#include <sys/types.h>
#include <stdint.h>

// Return number of CPUs in computer
int system_ncpu(void);

// Return pointer to a string containing username of a provided process id
char *get_proc_username(pid_t pid);

// Return process uid if successful or, UINT32_MAX otherwise.
uid_t get_proc_uid(pid_t pid);

// Return current CPU time for a process id
uint64_t get_proc_cputime(pid_t pid);

// Return timestemp in nanoseconds
uint64_t get_timestamp(void);

// Sets "logind" into provided |name| buffer for the path
// like "/System/Library/CoreServices/logind"
// Returns the number of chars written
int proc_name_from_path(char name[], const char path[], int maxlen);



#endif
