//
//  proc_cpulim.c
//  proc_cpulim
//
//  Created by Maksym on 5/19/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//


#include <stdio.h>
#include <stdlib.h>					/* malloc */
#include <string.h>					/* memset */
#include <time.h>					/* nanosleep */
#include <math.h>
#include <signal.h>
#include <libproc.h>				/* proc_pidinfo */
#include <dispatch/dispatch.h>		/* dispatch_queue */
#include <libkern/OSAtomic.h>
#include <errno.h>					/* errno */

#include "proc_cpulim.h"


#define TASK_SCHEDULE_INTERVAL_MIN 1000000		// 1ms
#define DISPATCH_QUEUE_LIMITER 0
#define DISPATCH_QUEUE_UPDTASKSTATS	1


/**************** Private Declarations ****************/

/* options */
static short opt_verbose_level = 0;

struct proc_taskstats_s {
	pid_t pid;
	float lim;			/* fraction, 1 is 100% for 1 core */
	uint64_t time;		/* process system_time + user_time */
	uint64_t sleep_time;
	int is_sleeping;
	struct proc_taskstats_s *next;
};
typedef struct proc_taskstats_s *proc_taskstats_t;

static proc_taskstats_t _proc_taskstats_list;	/* pointer to the first task in list */

/* This option corresponds for how often proc_cpulim will wake up to monitor processes.
 Value is in nanoseconds, for example 200000000 means proc_cpulim will be awake
 every 0.2s to reschedule processes for sleep time. This value should never be zero. */
static uint64_t _task_schedule_interval = 30000000;		// default is 30ms
static int _keep_limiter_running;
// Global variable _keep_limiter_running specifies whether limiter should run
// or not. When _keep_limiter_running is set to 0 limiter could still be running
// until all tasks in queue are processed. _limit_is_running on other other hand
// tells whether limiter is running at this moment or not.
static int _limiter_is_running;
static volatile int32_t _managing_dispatch_queue_locked;	// safely create, return or release queue

static void do_proc_cpulim_set(int pid, float newlim);
static void proc_limiter_resume(void);
static uint64_t do_sleep_loop(void);
static uint proc_tasks_calcsleeptime(void);
static uint64_t proc_tasks_execsleeptime(void);
static void proc_task_delete(pid_t pid);
static void do_proc_task_delete(pid_t pid);
static void reset_all_taskstats(void);

// Internally count the number of queue operators.
// When the number reaches zero call libdispatch's release.
typedef struct {
	dispatch_queue_t queue;
	int refcnt;
} _proc_cpulim_dispatch_queue_t;
// These variables should never be used directly! Instead
// use get_dispatch_queue() with proper type specified:
//		DISPATCH_QUEUE_LIMITER or
//		DISPATCH_QUEUE_UPDTASKSTATS
// The call needs to be paired with according release_dispatch_queue().
static _proc_cpulim_dispatch_queue_t _limiter_queue;
static _proc_cpulim_dispatch_queue_t _updtaskstats_queue;

static dispatch_queue_t get_dispatch_queue(int type);
static void release_dispatch_queue(int type);

static struct timespec timespec_from_ns(int64_t nanoseconds);





int proc_cpulim_set(int pid, float newlim) {
	short einval = 1;
	pid_t shared_pid = getpid();

	if (pid < 1 || pid == shared_pid || newlim < 0)
		return einval;
	
	dispatch_queue_t updtaskstats_queue = get_dispatch_queue(DISPATCH_QUEUE_UPDTASKSTATS);
	
//	fputs("\nSetting new lim on queue", stdout);
//	fflush(stdout);
//	dispatch_debug(updtaskstats_queue, "setting queue");
	
	dispatch_async(updtaskstats_queue, ^{
		do_proc_cpulim_set(pid, newlim);
		release_dispatch_queue(DISPATCH_QUEUE_UPDTASKSTATS);
	});
	
	return 0;
}


/*
 *
 */
static void do_proc_cpulim_set(int pid, float newlim) {
	/* if there are no tasks yet */
	if (_proc_taskstats_list == NULL) {
		if (newlim == 0)
			return;
		
		proc_taskstats_t task;
		task = (proc_taskstats_t)xmalloc(sizeof(struct proc_taskstats_s));
		task->pid = pid;
		task->lim = newlim;
		task->time = 0;
		task->sleep_time = 0;
		task->is_sleeping = 0;
		task->next = NULL;
		_proc_taskstats_list = task;	// make list point to the first task
		
		return;
	}
	
	
	proc_taskstats_t task;
	
	
	/* if found task with pid -- update it */
	for (task = _proc_taskstats_list; task != NULL; task = task->next) {
		if (task->pid == pid) {
			if (newlim == 0)
				proc_task_delete(pid);
			else
				task->lim = newlim;
			return;
		}
	}
	
	
	/* if no task with such pid */
	if (newlim == 0)
		return;
	
	proc_taskstats_t head = _proc_taskstats_list;
	proc_taskstats_t newtask = (proc_taskstats_t)xmalloc(sizeof(struct proc_taskstats_s));
	newtask->pid = pid;
	newtask->lim = newlim;
	newtask->time = 0;
	newtask->sleep_time = 0;
	newtask->is_sleeping = 0;
	newtask->next = head;
	_proc_taskstats_list = newtask;
}


/*
 *
 */
void proc_cpulim_resume(void) {
	if (_keep_limiter_running)
		return;
	
	if (_limiter_is_running) {
		if (opt_verbose_level) {
			fputs("[proc_cpulim] Info: Limiter is still running. Try when it's fully stopped.\n", stdout);
			fflush(stdout);
		}
		return;
	}
	
	
	_limiter_is_running = 1;
	_keep_limiter_running = 1;
	dispatch_queue_t limiter_queue = get_dispatch_queue(DISPATCH_QUEUE_LIMITER);
	
	dispatch_async(limiter_queue, ^{
		proc_limiter_resume();
		
		// The code below is going to be executed only after proc_limiter_resume() has returned.
		// It will return only if proc_cpulim_suspend() or proc_cpulim_suspend_wait() has been called
		// and the value of '_keep_limiter_running' has been set to 0.
		// Either of the 'suspend' functions could be called either:
		//    - by the user directly; or
		//    - internally, when there are no tasks left with non-zero limit level.
			
		release_dispatch_queue(DISPATCH_QUEUE_LIMITER);
		_limiter_is_running = 0;
	});
}


/*
 *
 */
static void proc_limiter_resume(void) {
	struct timespec sleepspec;
	int64_t sleepns;
	__block uint64_t loop_slept;
	dispatch_queue_t updtaskstats_queue;
	
	/* before resuming, make sure some values are valid */
	if (_task_schedule_interval < 1)
		return;
	
	updtaskstats_queue = get_dispatch_queue(DISPATCH_QUEUE_UPDTASKSTATS);
	
//	fputs("\nResuming on queue:\n", stdout);
//	fflush(stdout);
//	dispatch_debug(updtaskstats_queue, "resuming queue");

	dispatch_async(updtaskstats_queue, ^{
		reset_all_taskstats();
	});
	
	while (_keep_limiter_running) {
		// While the processes, that need to, are sleeping tasks info data is being read.
		//	We protect it by making all read/write changes to this info only happend
		//	in serial dispatch queue "updtaskstats_queue".
		dispatch_sync(updtaskstats_queue, ^{
			loop_slept = do_sleep_loop();
		});
		
		sleepns = (int64_t)(_task_schedule_interval - loop_slept);
		if (sleepns > 0) {
			sleepspec = timespec_from_ns(sleepns);
			nanosleep(&sleepspec, NULL);
		}
	}
	
	release_dispatch_queue(DISPATCH_QUEUE_UPDTASKSTATS);
}


/*
 * Return total number of nanoseconds slept
 */
static uint64_t do_sleep_loop(void) {
	uint ntasks_with_lim;
	uint64_t sleptns;
	
	ntasks_with_lim = proc_tasks_calcsleeptime();
	if (ntasks_with_lim == 0) {
		if (opt_verbose_level)
			fputs("[proc_cpulim] Info: There are no process tasks with limits.\n", stdout);
		proc_cpulim_suspend();
		return 0;
	}
	sleptns = proc_tasks_execsleeptime();

	return sleptns;
}


/*
 * Calculate how much time each task should sleep.
 * Return number of tasks that have sleep_time set.
 */
static uint proc_tasks_calcsleeptime(void) {
	struct proc_taskinfo ptinfo;
	int numbytes;			// number of bytes returned by proc_pidinfo()
	uint64_t time_prev;
	uint64_t time_diff;
	int64_t sleep_time;
	int64_t work_time;
	float cpuload;
	proc_taskstats_t task;
	uint ntasks_with_lim;
	
	ntasks_with_lim = 0;
	for (task = _proc_taskstats_list; task != NULL; task = task->next) {
		if (task->lim == 0)
			continue;
		
		++ntasks_with_lim;
		errno = 0;
		numbytes = proc_pidinfo(task->pid, PROC_PIDTASKINFO, (uint64_t)0, &ptinfo, PROC_PIDTASKINFO_SIZE);
		if (numbytes <= 0) {
			if (errno == ESRCH && opt_verbose_level)
				(void) fprintf(stdout, "[proc_cpulim] Info: process %d not found. Removing from the list\n", task->pid);
			proc_task_delete(task->pid);
			continue;
		}
		
		time_prev = task->time;
		task->time = ptinfo.pti_total_system + ptinfo.pti_total_user;

		
		if (time_prev == 0) {
			continue;			/* first run for a task */
		}
		
		
		time_diff = task->time - time_prev;
		cpuload = (float)time_diff / _task_schedule_interval;

		work_time = (int64_t)(_task_schedule_interval - task->sleep_time);
		if (work_time == 0) {
			// If work_time of a process is nearly zero (highloaded and throttled extensively) flipping it to an opposite value
			//	of sleep_time won't be a big deal because of the expression (cpuload - task->lim) ---> to zero, so the sleep_time
			//	will balance in the same ranges.
			//	But in this case, if the limit is raised the sleep_time will be able to correlate with the new limit. In other words
			//	sleep_time will be dropping from nearly '_task_schedule_interval' values down letting process run freely.
			//	Otherwise, zero value of work_time will hang the process sleeping '_task_schedule_interval' nanoseconds always
			//	despite raising the limit. E.g:
			//		sleep_time = sleep_time + 0 * (0.01 - 0.5) / 0.5;	will yield constant sleep_time
			work_time = (int64_t)_task_schedule_interval;
		}
		sleep_time = (int64_t)floor(task->sleep_time + work_time * (cpuload - task->lim) / MAX(cpuload, task->lim));

		if (sleep_time < 0) {
			sleep_time = 0;
		} else if (sleep_time > (int64_t)_task_schedule_interval) {
			sleep_time = (int64_t)_task_schedule_interval;
		}
		
		task->sleep_time = (uint64_t)sleep_time;

		if (opt_verbose_level)
			printf("pid # %d, time_prev: %llu, current_time: %llu, time_diff: %llu sleep_time: %llu or %0.3f(s) Worktime(ns): %lld\n",
				task->pid,
				time_prev,
				task->time,
				time_diff,
				task->sleep_time,
				(double)task->sleep_time / NANOSEC_PER_SEC,
				work_time
			);
	}
	
	if (opt_verbose_level)
		fputs("\n", stdout);
	
	return ntasks_with_lim;
}


/*
 * Put process tasks to sleep.
 * Return total number of nanoseconds slept.
 */
static uint64_t proc_tasks_execsleeptime(void) {
	uint64_t sleptns = 0;
	short there_are_proc_sleeping = 0;
	short all_awake = 0;
	uint64_t pt_sleep_min;
	struct timespec sleepspec;
	proc_taskstats_t task;
	
	pt_sleep_min = ULONG_LONG_MAX;
	for (task = _proc_taskstats_list; task != NULL; task = task->next) {
		if (task->sleep_time != 0) {
			if (kill(task->pid, SIGSTOP) == -1) {
				if (opt_verbose_level)
					fputs("[proc_cpulim] Error: could not send a signal to a process.\n", stderr);
				continue;
			}
			
			task->is_sleeping = 1;
			there_are_proc_sleeping = 1;
			if (task->sleep_time < pt_sleep_min)
				pt_sleep_min = task->sleep_time;
		}
	}
	
	if (! there_are_proc_sleeping)
		return sleptns;
	
	sleepspec = timespec_from_ns((int64_t)pt_sleep_min);
	nanosleep(&sleepspec, NULL);
	sleptns = pt_sleep_min;
	
	while (! all_awake) {
		all_awake = 1;
		pt_sleep_min = ULONG_LONG_MAX;
		
		for (task = _proc_taskstats_list; task != NULL; task = task->next) {
			if (task->sleep_time == 0 || task->is_sleeping == 0)
				continue;
			else if (task->sleep_time == sleptns) {
				kill(task->pid, SIGCONT);
				task->is_sleeping = 0;
			} else if (task->sleep_time < pt_sleep_min) {
				pt_sleep_min = task->sleep_time;
				all_awake = 0;
			}
		}
		
		if (! all_awake) {
			sleepspec = timespec_from_ns((int64_t)(pt_sleep_min - sleptns));
			nanosleep(&sleepspec, NULL);
			sleptns = pt_sleep_min;
		}
		
	}
	
	
	return sleptns;
}


/*
 *
 */
static dispatch_queue_t get_dispatch_queue(int type) {
	// Non-blocking spinner until the queue management is finished
	while (! OSAtomicCompareAndSwap32Barrier(0, 1, &_managing_dispatch_queue_locked))
		;

	dispatch_queue_t retval = NULL;
	
	if (type == DISPATCH_QUEUE_LIMITER) {
		if (_limiter_queue.queue) {
			_limiter_queue.refcnt += 1;
			retval = _limiter_queue.queue;
		} else {
			_limiter_queue.queue = dispatch_queue_create("com.proc_cpulim.LimiterQueue", DISPATCH_QUEUE_SERIAL);
			_limiter_queue.refcnt = 1;
			retval = _limiter_queue.queue;
		}
	} else if (type == DISPATCH_QUEUE_UPDTASKSTATS) {
		if (_updtaskstats_queue.queue) {
			_updtaskstats_queue.refcnt += 1;
			retval = _updtaskstats_queue.queue;
		} else {
			_updtaskstats_queue.queue = dispatch_queue_create("com.proc_cpulim.UpdTaskStatsQueue", DISPATCH_QUEUE_SERIAL);
			_updtaskstats_queue.refcnt = 1;
			retval = _updtaskstats_queue.queue;
		}

	}
	
	_managing_dispatch_queue_locked = 0;
	return retval;
}


/*
 *
 */
static void release_dispatch_queue(int type) {
	while (! OSAtomicCompareAndSwap32Barrier(0, 1, &_managing_dispatch_queue_locked))
		;
	
	if (type == DISPATCH_QUEUE_LIMITER) {
		_limiter_queue.refcnt -= 1;
		if (_limiter_queue.refcnt < 1) {
			// dispatch_debug(_limiter_queue.queue, " <--- RELEASING limiter queue");
			dispatch_release(_limiter_queue.queue);
			_limiter_queue.queue = NULL;
		}
	} else if (type == DISPATCH_QUEUE_UPDTASKSTATS) {
		_updtaskstats_queue.refcnt -= 1;
		if (_updtaskstats_queue.refcnt < 1) {
			// dispatch_debug(_updtaskstats_queue.queue, " <--- RELEASING updtaskstats queue");
			dispatch_release(_updtaskstats_queue.queue);
			_updtaskstats_queue.queue = NULL;
		}
	}
	
	_managing_dispatch_queue_locked = 0;
}


/*
 *
 */
void proc_cpulim_suspend(void) {
	_keep_limiter_running = 0;
	if (opt_verbose_level)
		fputs("[proc_cpulim] Info: Limiter going to hibernate.\n", stdout);
}


/*
 * Function returns only after limiter stops
 */
void proc_cpulim_suspend_wait(void) {
	if (! _keep_limiter_running)
		return;
	
	dispatch_queue_t limiter_queue = get_dispatch_queue(DISPATCH_QUEUE_LIMITER);
	_keep_limiter_running = 0;
	// dispatch_SYNC is used here:
	// Submits a block object for execution on a dispatch queue and waits until that block completes
	dispatch_sync(limiter_queue, ^{
		if (opt_verbose_level)
			fputs("[proc_cpulim] Info: Limiter going to hibernate.\n", stdout);
	});
	
	release_dispatch_queue(DISPATCH_QUEUE_LIMITER);
}


/*
 *
 */
static void proc_task_delete(pid_t pid) {
	dispatch_queue_t updtaskstats_queue = get_dispatch_queue(DISPATCH_QUEUE_UPDTASKSTATS);
	dispatch_async(updtaskstats_queue, ^{
		do_proc_task_delete(pid);
		release_dispatch_queue(DISPATCH_QUEUE_UPDTASKSTATS);
	});
}


static void do_proc_task_delete(pid_t pid) {
	proc_taskstats_t head = _proc_taskstats_list;
	proc_taskstats_t task;
	proc_taskstats_t prev_task = NULL;
	for (task = head; task != NULL; prev_task = task, task = task->next) {
		if (task->pid == pid) {
			// if it's the first task in the list simply make the head point to the next task
			if (task == head) {
				_proc_taskstats_list = task->next;
			} else if (prev_task) {				// if it's not the only task in the list
				prev_task->next = task->next;
			}
			
			free(task);
			
			break;
		}
		
	}
	
	if (opt_verbose_level)
		fprintf(stdout, "[proc_cpulim] Info: Process '%d' deleted from the task list.\n", pid);
}


/*
 *
 */
static void reset_all_taskstats(void) {
	proc_taskstats_t task;
	for (task = _proc_taskstats_list; task != NULL; task = task->next) {
		task->time = 0;
		task->sleep_time = 0;
		task->is_sleeping = 0;
	}
}


/*
 *
 */
static struct timespec timespec_from_ns(int64_t nanoseconds) {
	struct timespec timef;
	if (nanoseconds >= NANOSEC_PER_SEC) {
		timef.tv_sec = (int)floor(nanoseconds / NANOSEC_PER_SEC);
		timef.tv_nsec = nanoseconds % NANOSEC_PER_SEC;
	} else {
		timef.tv_sec = 0;
		timef.tv_nsec = nanoseconds;
	}
	
	return timef;
}


/*
 *
 */
int proc_cpulim_schedule_interval(unsigned int new_interval, unsigned int *old_interval) {
	if (old_interval) {
		*old_interval = (unsigned int)_task_schedule_interval;
	}
	
	if (new_interval) {
		if (new_interval < TASK_SCHEDULE_INTERVAL_MIN)
			return(1);
		
		if (_limiter_is_running) {
			dispatch_queue_t updtaskstats_queue = get_dispatch_queue(DISPATCH_QUEUE_UPDTASKSTATS);
			dispatch_async(updtaskstats_queue, ^{
				_task_schedule_interval = new_interval;
				release_dispatch_queue(DISPATCH_QUEUE_UPDTASKSTATS);
			});
		} else {
			_task_schedule_interval = new_interval;
		}
	}
	
	return(0);
}


/*
 *
 */
void proc_taskstats_print(void) {
	fputs("\n\n---------------- STATS BEGIN --------------", stdout);
	
	if (_proc_taskstats_list) {
		int task_num = 0;
		proc_taskstats_t task;
		
		fputs("\nTask #     PID     Limit      Time           ptr              nextptr\n", stdout);
		for (task = _proc_taskstats_list; task != NULL; task = task->next) {
			printf("%-10d %-7d %-10.3f %-14llu %-16p %p\n",
				   task_num,
				   task->pid,
				   task->lim,
				   task->time,
				   task,
				   task->next);

			++task_num;
		}
		fprintf(stdout, "\nTasks count: %d", task_num);
	} else {
		printf("\nThere are no tasks");
	}
	
	if (_limiter_queue.queue) {
		fprintf(stdout, "\n\nLimiter queue:\n");
		dispatch_debug(_limiter_queue.queue, "");
	} else {
		fprintf(stdout, "\n\nLimiter queue: NULL");
	}
	
	if (_updtaskstats_queue.queue) {
		fprintf(stdout, "\nUpdtaskstats queue:\n");
		dispatch_debug(_updtaskstats_queue.queue, "");
	} else {
		fprintf(stdout, "\nUpdtaskstats queue: NULL");
	}

	
	fputs("\n---------------- STATS END --------------\n", stdout);
}
