//
//  selfprofile.c
//  proc_cpulim
//
//  Created by Maksym on 5/22/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#include "selfprofile.h"

#ifdef PROFILE_APPLICATION

#include <stdio.h>
#include <time.h>

static clock_t clocks_start, clocks_end;
static time_t time_start, time_end;


void profiling_start(void) {
	clocks_start = clock();
	time(&time_start);
}


void profiling_print_stats(void) {
	double cpu_time_used;
	clocks_end = clock();
	cpu_time_used = ((double)(clocks_end - clocks_start)) / CLOCKS_PER_SEC;
	
	time(&time_end);
	
	fputs("\n\n------- STATS --------\n", stdout);
	fprintf(stdout, "CPU time: %f\nTotal clocks: %lu\n", cpu_time_used, (clocks_end - clocks_start));
	fprintf(stdout, "Elapsed time from launch: %lu second(s)", (time_end - time_start));
	fputs("\n-----------------------\n", stdout);
}

#endif
