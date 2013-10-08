//
//  clevel.h
//  cpulim
//
//  Created by Maksym on 5/19/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//


#include "subroutines.h"

// Clocks per second OSX uses for processes.
// It could be a better option to use "sysctl hw.tbfrequency" (time base frequency)
// to find out the value for different computers.
#define NANOSEC_PER_SEC 1000000000


int proc_cpulim_set(int pid, float newlim);
void proc_cpulim_resume(void);
void proc_cpulim_suspend(void);
void proc_cpulim_suspend_wait(void);	/* function returns only after limiter stoped */


/* should be private */
void proc_taskstats_print(void);