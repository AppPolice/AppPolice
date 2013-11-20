//
//  selfprofile.h
//  Ishimura
//
//  Created by Maksym on 5/22/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//


// It is for profiling currently running application in general
#if defined(DEBUG) && !defined(PROFILE_APPLICATION)
# define PROFILE_APPLICATION
#endif

/*
 * Methods for profiling our own App
 */

// Call this method to mark the beginning of profiling.
void profiling_start(void);

// Print profiling stats as of the current moment.
void profiling_print_stats(void);
