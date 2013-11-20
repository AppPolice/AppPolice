//
//  main.m
//  cpulim
//
//  Created by Maksym on 5/19/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <signal.h>
#include "C/proc_cpulim.h"
#include "C/selfprofile.h"

int gAPAllLimitsPaused;

void install_signal_handlers(void);
void termination_handler(int signum);
void tstp_handler(int signum);
void cont_handler(int signum);


int main(int argc, char *argv[]) {
#ifdef PROFILE_APPLICATION
	profiling_start();
	if (atexit(profiling_print_stats) != 0)
		fputs("[AppPolice] Error: Could not establish atexit() method", stderr);
#endif


	// print dispatch_debug() logs to stderr
	// setenv("LIBDISPATCH_LOG", "stderr", 1);

	
	install_signal_handlers();
	
	return NSApplicationMain(argc, (const char **)argv);
}



void install_signal_handlers(void) {
	struct sigaction term_action, tstp_action, cont_action;
	
	term_action.sa_handler = termination_handler;
	sigfillset(&term_action.sa_mask);
	term_action.sa_flags = 0;
	
	tstp_action.sa_handler = tstp_handler;
	sigfillset(&tstp_action.sa_mask);
	tstp_action.sa_flags = 0;
	
	cont_action.sa_handler = cont_handler;
	sigfillset(&cont_action.sa_mask);
	cont_action.sa_flags = 0;
	
	sigaction(SIGINT, &term_action, NULL);
	sigaction(SIGTERM, &term_action, NULL);
	sigaction(SIGHUP, &term_action, NULL);
	sigaction(SIGCONT, &cont_action, NULL);
	sigaction(SIGTSTP, &tstp_action, NULL);
}



void termination_handler(int signum) {
	struct sigaction new_action;
	
	fputs("[AppPolice] Info: Termination signal received. Let processes run freely.\n", stdout);
	fflush(stdout);
	proc_cpulim_suspend_wait();
	
	// set default action and re-raise signal
	new_action.sa_handler = SIG_DFL;
	sigfillset(&new_action.sa_mask);
	new_action.sa_flags = 0;
	sigaction(signum, &new_action, NULL);
	raise(signum);
}


void tstp_handler(int signum) {
	struct sigaction new_action;
	
	fputs("[AppPolice] Info: SIGTSTP signal received. Let processes run freely.\n", stdout);
	fflush(stdout);
	proc_cpulim_suspend_wait();
	
	// set default action and re-raise signal
	new_action.sa_handler = SIG_DFL;
	sigemptyset(&new_action.sa_mask);
	new_action.sa_flags = 0;
	sigaction(signum, &new_action, NULL);
	raise(signum);
}


void cont_handler(int signum) {
	struct sigaction tstp_action;
	
	// Restore the SIGTSTP handler back
	tstp_action.sa_handler = tstp_handler;
	sigfillset(&tstp_action.sa_mask);
	tstp_action.sa_flags = 0;
	sigaction(SIGTSTP, &tstp_action, NULL);

	fputs("[AppPolice] Info: SIGCONT signal received. Resume all limits.\n", stdout);
	fflush(stdout);
	if (! gAPAllLimitsPaused)
		proc_cpulim_resume();
}

