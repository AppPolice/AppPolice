//
//  clevel.c
//  cpulim
//
//  Created by Maksym on 5/19/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

/* TODO
 * 1. Install signal actions for SIGINT, SIGTERM
 *
 */


#include <stdio.h>
#include <stdlib.h>					/* malloc */
#include <string.h>					/* memset */
#include <time.h>					/* nanosleep */
#include <math.h>
#include <signal.h>
#include <libproc.h>				/* proc_pidinfo */
#include <dispatch/dispatch.h>		/* dispatch_queue */

#include "clevel.h"

/**************** Private Declarations ****************/

/* options */
uint64_t osleep_interval = 500000000;		/* make sure it is never zero */
short overbose = 1;

struct proc_taskstats {
	pid_t pid;
	float lim;			/* fraction, 1 is 100% for 1 core */
	uint64_t time;		/* process system_time + user_time */
	int64_t sleep_time;
	int is_sleeping;
	struct proc_taskstats *next;
	struct proc_taskstats *prev;
};

static struct proc_taskstats *proc_taskstats;

static void proc_cpulim_set_run(int pid, float newlim);
static int limiter_running_ok = 0;
static void proc_limiter_resume(void);
static uint64_t sleep_loop_run(void);
static int proc_tasks_calcsleeptime(void);
static uint64_t proc_tasks_execsleeptime(void);
static void proc_task_delete(pid_t pid);
static void proc_task_delete_run(pid_t pid);

static dispatch_queue_t *get_limiter_queue(void);
static dispatch_queue_t *get_updtaskstats_queue(void);

//dispatch_queue_t limiter_queue;
//dispatch_queue_t updtaskstats_queue;

static struct timespec format_time(uint64_t nanoseconds);



/**************** Definitions ********************/

int proc_cpulim_set(int pid, float newlim) {
	short einval = 1;
	pid_t shared_pid = getpid();

	if (pid < 1 || pid == shared_pid || newlim < 0)
		return einval;
	
	/* safely add to the Serial Queue */
	dispatch_queue_t *updtaskstats_queue_ptr = get_updtaskstats_queue();
	dispatch_async(*updtaskstats_queue_ptr, ^{
		proc_cpulim_set_run(pid, newlim);
	});
	
	return 0;
}


static void proc_cpulim_set_run(int pid, float newlim) {
	/* if there are no tasks yet */
	if (proc_taskstats == NULL) {
		if (newlim == 0)
			return;
		
		proc_taskstats = (struct proc_taskstats *)xmalloc(sizeof(struct proc_taskstats));
		proc_taskstats->pid = pid;
		proc_taskstats->lim = newlim;
		proc_taskstats->time = 0;
		proc_taskstats->sleep_time = 0;
		proc_taskstats->is_sleeping = 0;
		proc_taskstats->next = proc_taskstats->prev = NULL;
		
		return;
	}
	
	
	struct proc_taskstats *task;
	struct proc_taskstats *task_prev;
	
	/* if found task with pid -- update it */
	for (task = proc_taskstats; task != NULL; task_prev = task, task = task->next) {
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
	
	struct proc_taskstats *newtask = (struct proc_taskstats *)xmalloc(sizeof(struct proc_taskstats));
	newtask->pid = pid;
	newtask->lim = newlim;
	newtask->time = 0;
	newtask->sleep_time = 0;
	newtask->is_sleeping = 0;
	newtask->prev = task_prev;
	newtask->next = NULL;
	task_prev->next = newtask;
}


void proc_cpulim_resume(void) {
	if (limiter_running_ok)
		return;
	
	limiter_running_ok = 1;
	dispatch_queue_t *limiter_queue_ptr = get_limiter_queue();
	dispatch_async(*limiter_queue_ptr, ^{
		proc_limiter_resume();
	});
}


static void proc_limiter_resume(void) {
	struct timespec sleepspec;
	uint64_t sleepns;
	__block uint64_t loop_slept;
	dispatch_queue_t *updtaskstats_queue_ptr;
	
	/* before resuming, make sure some values are valid */
	if (osleep_interval < 1)
		return;
	
	updtaskstats_queue_ptr = get_updtaskstats_queue();
	while (limiter_running_ok) {
		dispatch_sync(*updtaskstats_queue_ptr, ^{
			loop_slept = sleep_loop_run();
		});
		
		sleepns = osleep_interval - loop_slept;
		if (sleepns > 0) {
			sleepspec = format_time(sleepns);
			nanosleep(&sleepspec, NULL);
		}
	}
}


/*
 * Return total number of nanoseconds slept
 */
static uint64_t sleep_loop_run(void) {
	uint proc_tasks_wlim_num;
	uint64_t sleptns;
	
	proc_tasks_wlim_num = proc_tasks_calcsleeptime();
	if (proc_tasks_wlim_num == 0) {
		if (overbose)
			fputs("\n[Ishimura] Info: There are no proc_tasks with limits.", stdout);
		proc_cpulim_suspend();
		return 0;
	}
	sleptns = proc_tasks_execsleeptime();

	return sleptns;
}


/*
 * Calculate how much time each task should sleep.
 * Return number of tasks that has sleep_time set.
 */
static int proc_tasks_calcsleeptime(void) {
	struct proc_taskinfo ptinfo;
	int error = 0;
	uint64_t time_prev;
	uint64_t time_diff;
	float cpuload;
	struct proc_taskstats *task;
	uint proc_tasks_wlim_num;
	
	proc_tasks_wlim_num = 0;
	for (task = proc_taskstats; task != NULL; task = task->next) {
		if (task->lim == 0)
			continue;
		
		++proc_tasks_wlim_num;
		error = proc_pidinfo(task->pid, PROC_PIDTASKINFO, (uint64_t)0, &ptinfo, PROC_PIDTASKINFO_SIZE);
		if (error < 1) {
			if (overbose)
				fprintf(stdout, "\n[Ishimura] Error: kernel proc_pidinfo returned: %d", error);
			proc_task_delete(task->pid);	/* either pid is wrong or process exited */
			continue;
		}
		
		time_prev = task->time;
		task->time = ptinfo.pti_total_system + ptinfo.pti_total_user;
		
		if (time_prev == 0)
			continue;			/* first run for a task */
		
		time_diff = task->time - time_prev;
		cpuload = (float)time_diff / osleep_interval;

		printf("\nsleep time = %lld + (%llu - %lld) * (%.3f - %.3f) / %0.3f",
			   task->sleep_time,
			   osleep_interval,
			   task->sleep_time,
			   cpuload,
			   task->lim,
			   MAX(cpuload, task->lim));
		
		task->sleep_time = task->sleep_time +
			(osleep_interval - task->sleep_time) * (cpuload - task->lim) / MAX(cpuload, task->lim);
		
		if (task->sleep_time < 0)
			task->sleep_time = 0;
		
		if (overbose)
			printf("\npid # %d, time_prev: %llu, current_time: %llu, time_diff: %llu sleep_time: %llu or %0.3f(s)",
			   task->pid,
			   time_prev,
			   task->time,
			   time_diff,
			   task->sleep_time,
			   (double)task->sleep_time / NANOSEC_PER_SEC);
	}
	
	if (overbose)
		fputs("\n", stdout);
	
	return proc_tasks_wlim_num;
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
	struct proc_taskstats *task;
	
	pt_sleep_min = ULONG_LONG_MAX;
	for (task = proc_taskstats; task != NULL; task = task->next) {
		if (task->sleep_time != 0) {
			if (kill(task->pid, SIGSTOP) == -1) {
				if (overbose)
					fputs("\n[Ishimura] Error: could not send a signal to a process.", stderr);
				continue;
			}
			
			task->is_sleeping = 1;
			there_are_proc_sleeping = 1;
			if (task->sleep_time < pt_sleep_min)
				pt_sleep_min = task->sleep_time;
		}
	}
	
	if (!there_are_proc_sleeping)
		return sleptns;
	
	sleepspec = format_time(pt_sleep_min);
	nanosleep(&sleepspec, NULL);
	sleptns = pt_sleep_min;
	
	while (!all_awake) {
		all_awake = 1;
		pt_sleep_min = ULONG_LONG_MAX;
		
		for (task = proc_taskstats; task != NULL; task = task->next) {
			if (task->sleep_time == 0 || task->is_sleeping == 0)
				continue;
			else if (task->sleep_time == sleptns) {
				kill(task->pid, SIGCONT);
//				task->sleep_time = 0;
				task->is_sleeping = 0;
			} else if (task->sleep_time < pt_sleep_min) {
				pt_sleep_min = task->sleep_time;
				all_awake = 0;
			}
		}
		
		if (!all_awake) {
			sleepspec = format_time(pt_sleep_min - sleptns);
			nanosleep(&sleepspec, NULL);
			sleptns = pt_sleep_min;
		}
		
	}
	
	
	return sleptns;
}


static dispatch_queue_t *get_limiter_queue(void) {
	static dispatch_queue_t limiter_queue;
	static short initialized = 0;
	if (initialized)
		return &limiter_queue;
	
	limiter_queue = dispatch_queue_create("com.ishimura.LimiterQueue", NULL);
	initialized = 1;
	return &limiter_queue;
}


static dispatch_queue_t *get_updtaskstats_queue(void) {
	static dispatch_queue_t updtaskstats_queue;
	static short initialized = 0;
	if (initialized)
		return &updtaskstats_queue;
	
	updtaskstats_queue = dispatch_queue_create("com.ishimura.UpdTaskStatsQueue", NULL);
	initialized = 1;
	return &updtaskstats_queue;
}


void proc_cpulim_suspend(void) {
	limiter_running_ok = 0;
	if (overbose)
		fputs("\n[Ishimura] Info: Limiter going to hibernate.", stdout);
}


/*
 * Function returns only after limiter stops
 */
void proc_cpulim_suspend_wait(void) {
	limiter_running_ok = 0;
	dispatch_queue_t *limiter_queue_ptr = get_limiter_queue();
	dispatch_sync(*limiter_queue_ptr, ^{
		if (overbose)
			fputs("\n[Ishimura] Info: Limiter going to hibernate.", stdout);
	});
}


static void proc_task_delete(pid_t pid) {
	dispatch_queue_t *updtaskstats_queue_ptr = get_updtaskstats_queue();
	dispatch_async(*updtaskstats_queue_ptr, ^{
		proc_task_delete_run(pid);
	});
}


static void proc_task_delete_run(pid_t pid) {
	struct proc_taskstats *task;
	for (task = proc_taskstats; task != NULL; task = task->next) {
		if (task->pid == pid) {
			if (task->next && task->prev) {
				task->prev->next = task->next;
				task->next->prev = task->prev;
			} else if (task->next)
				task->next->prev = NULL;
			else if (task->prev)
				task->prev->next = NULL;
			
//			memset(task, 0xDC, sizeof(struct proc_taskstats));
			if (task == proc_taskstats) {
				if (task->next)
					proc_taskstats = task->next;
				else
					proc_taskstats = NULL;
			}
			
			free(task);
			
			break;
		}
	}
	
	if (overbose)
		fprintf(stdout, "\n[Ishimura] Info: Process '%d' deleted from the task list.", pid);
}


static struct timespec format_time(uint64_t nanoseconds) {
	struct timespec timef;
	if (nanoseconds >= NANOSEC_PER_SEC) {
		timef.tv_sec = floor(nanoseconds / NANOSEC_PER_SEC);
		timef.tv_nsec = nanoseconds % NANOSEC_PER_SEC;
	} else {
		timef.tv_sec = 0;
		timef.tv_nsec = nanoseconds;
	}
	
	return timef;
}


void proc_taskstats_print(void) {
	
	if (proc_taskstats == NULL) {
		printf("\nThere are no tasks\n");
		return;
	}
	
	int task_num = 0;
	struct proc_taskstats *task;

	fputs("\n\n---------------- STATS BEGIN --------------\n", stdout);
	fputs("Task #     PID     Limit      Time           ptr              prevptr          nextptr\n", stdout);
	for (task = proc_taskstats; task != NULL; task = task->next) {
		printf("%-10d %-7d %-10.3f %-14llu %-16p %-16p %p\n",
			   task_num,
			   task->pid,
			   task->lim,
			   task->time,
			   task,
			   task->prev,
			   task->next);

		++task_num;
	}
	printf("\nTasks count: %d\n", task_num);
	fputs("---------------- STATS END --------------\n", stdout);
}

