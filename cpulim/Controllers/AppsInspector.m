//
//  AppsInspector.m
//  Ishimura
//
//  Created by Maksym on 5/20/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "AppsInspector.h"
#import "proc_cpulim.h"

@implementation AppsInspector


- (IBAction)setPidLimit:(NSButton *)sender {
	int pid = [pidTF intValue];
	float lim = [limTF floatValue];
	proc_cpulim_set(pid, lim);
	proc_cpulim_resume();
}

- (IBAction)deletePid:(NSButton *)sender {
//	int pid = [pidDeleteTF intValue];
//	proc_task_delete(pid);
}

- (IBAction)procCPULimiterResume:(NSButton *)sender {
	proc_cpulim_resume();
}

- (IBAction)procCPULimiterSuspend:(NSButton *)sender {
	proc_cpulim_suspend();
}

- (IBAction)printStats:(NSButton *)sender {
	proc_taskstats_print();
}


- (IBAction)exitApp:(NSButton *)sender {
	[NSApp terminate: nil];
}


- (IBAction)activateOtherApp:(id)sender {
//	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
//	NSArray *runningApps = [ws runningApplications];
	int appId = [activateAppTextField intValue];
	
//	int i, c;
//	pid_t pid;
//	for (i = 0, c = (int)[runningApps count]; i < c; ++i) {
//		pid = [runningApps[i] processIdentifier];
//		if (pid > 0) {
//			NSLog(@"%d - %@ has priority %d", pid, [runningApps[i] localizedName], getpriority(PRIO_PROCESS, pid));
//		}
//	}
	
	NSRunningApplication *ap = [NSRunningApplication runningApplicationWithProcessIdentifier:appId];
	if (ap == nil) {
		NSLog(@"\nError: process %d doesn't have ID", appId);
	} else {
//		NSDate *launchDate = [ap launchDate];
//		NSLog(@"\n%@  - launch date: %@", [ap localizedName], [launchDate description]);
		[ap activateWithOptions:NSApplicationActivateAllWindows];
	}
}



@end
