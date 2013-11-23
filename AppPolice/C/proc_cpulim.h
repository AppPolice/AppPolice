//
//  proc_cpulim.h
//  as part of AppPolice
//
//  Created by Maksym on 5/19/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#ifndef _PROC_CPULIM_H
#define _PROC_CPULIM_H

#include "subroutines.h"

// Clocks per second OSX uses for processes.
// It could be a better option to use "sysctl hw.tbfrequency" (time base frequency)
// to find out the value for different computers.
#define NANOSEC_PER_SEC 1000000000

/* 
  Note, to use dispatch_debug() an appropriate env. variable must be set:
  setenv("LIBDISPATCH_LOG", "stderr", 1);
  A proper place for this call could be in the application main file.
*/


/* 
 newlim is the fraction of percents. For example 1 corresponds to 100%
 of permitted cpu load, 0.5 to 50% and 2.5 to 250% (in multicore environment).
 Return 0 if limit set successful, and 1 if provided parameters are invalid. */
int proc_cpulim_set(int pid, float newlim);
void proc_cpulim_resume(void);
void proc_cpulim_suspend(void);
/* function returns only after limiter stoped */
void proc_cpulim_suspend_wait(void);

/*
 
 Set the task schedule interval--how often processes should be
 inquired about their work times.
 
 new_interval	If provided new interval is set. Value is in 
				nanoseconds and should not be smaller then 1ms.
 old_interval	If pointer is given old value is written into it.
 
 Return (0) if interval was changed and (1) otherwise.
 
*/
int proc_cpulim_schedule_interval(unsigned int new_interval, unsigned int *old_interval);

/* should be private */
void proc_taskstats_print(void);

#endif
