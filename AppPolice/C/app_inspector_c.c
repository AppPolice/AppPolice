//
//  app_inspector_c.c
//  AppPolice
//
//  Created by Maksym on 30/10/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#include <stdio.h>
#include <sys/sysctl.h>				/* sysctl() */
#include <unistd.h>					/* sysconf(_SC_NPROCESSORS_ONLN) */
#include <libproc.h>				/* proc_pidinfo() */
#include <pwd.h>					/* getpwuid() */
#include <mach/mach.h>				/* mach_absolute_time() */
#include <mach/mach_time.h>
#include <errno.h>					/* errno */
//#include <string.h>				/* strerror() */

#include "app_inspector_c.h"



/*
 * Return number of CPUs in computer
 */
int system_ncpu(void) {
	static int ncpu = 0;
	if (ncpu)
		return ncpu;
	
#ifdef _SC_NPROCESSORS_ONLN
	ncpu = (int)sysconf(_SC_NPROCESSORS_ONLN);
#else
	int mib[2];
	mib[0] = CTL_HW;
	mig[1] = HW_NCPU;
	size_t len = sizeof(ncpu);
	sysctl(mib, 2, &ncpu, &len, NULL, 0);
#endif
	return ncpu;
}


/*
 *
 */
char *get_proc_username(pid_t pid) {
	int numbytes;
	struct passwd *pwdinfo;
	struct proc_bsdshortinfo bsdinfo;
	
	errno = 0;
	numbytes = proc_pidinfo(pid, PROC_PIDT_SHORTBSDINFO, (uint64_t)0, &bsdinfo, PROC_PIDT_SHORTBSDINFO_SIZE);
	if (numbytes <= 0) {
		if (errno == EPERM)
			(void) fprintf(stderr, "\nUser is not permitted to get info about process: %d", pid);
		return NULL;
	}
	pwdinfo = getpwuid(bsdinfo.pbsi_uid);
	
	return pwdinfo->pw_name;
}


/*
 *
 */
uid_t get_proc_uid(pid_t pid) {
	int numbytes;
	struct proc_bsdshortinfo bsdinfo;
	
	errno = 0;
	numbytes = proc_pidinfo(pid, PROC_PIDT_SHORTBSDINFO, (uint64_t)0, &bsdinfo, PROC_PIDT_SHORTBSDINFO_SIZE);
	if (numbytes <= 0) {
		if (errno == EPERM)
			(void) fprintf(stderr, "\nUser is not permitted to get info about process: %d", pid);
		return UINT32_MAX;
	}
	
	return bsdinfo.pbsi_uid;
}


/*
 *
 */
uint64_t get_proc_cputime(pid_t pid) {
	int numbytes;
	struct proc_taskinfo ptinfo;
	
	errno = 0;
	numbytes = proc_pidinfo(pid, PROC_PIDTASKINFO, (uint64_t)0, &ptinfo, PROC_PIDTASKINFO_SIZE);
	if (numbytes <= 0) {
		if (errno == EPERM)
			(void) fprintf(stderr, "User is not permitted to get info about process: %d\n", pid);
		//		else
		//			(void) fprintf(stderr, "\nGet process %d info error: %s", pid, strerror(errno));
		return 0;
	}
	
	return (ptinfo.pti_total_user + ptinfo.pti_total_system);
}


/*
 *
 */
uint64_t get_timestamp(void) {
	uint64_t timestamp;
	uint64_t mach_time;
	static mach_timebase_info_data_t sTimebaseInfo;
	
	// See "Mach Absolute Time Units" for instructions:
	// https://developer.apple.com/library/mac/qa/qa1398/
	mach_time = mach_absolute_time();
	if (sTimebaseInfo.denom == 0) {
		(void) mach_timebase_info(&sTimebaseInfo);
	}
	timestamp = mach_time * sTimebaseInfo.numer / sTimebaseInfo.denom;
	return timestamp;
}


/*
 *
 */
int proc_name_from_path(char name[], const char path[], int maxlen) {
	int pos = -1;
	int i = 0;
	for (i = 0; path[i] != '\0'; ++i) {
		if (path[i] == '/')
			pos = i;
	}
	if (pos == -1)
		return 0;
	
	i = 0;
	++pos;
	// Copy substring
	while ((name[i++] = path[pos++]) && i < maxlen)
		;
	// Make sure the string is always properly terminated
	name[maxlen - 1] = '\0';
	return (i - 1);
}
