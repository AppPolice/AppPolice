//
//  AppsInspector.h
//  Ishimura
//
//  Created by Maksym on 5/20/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppsInspector : NSObject
{
	IBOutlet NSTextField *pidTF;
	IBOutlet NSTextField *limTF;
	IBOutlet NSTextField *pidDeleteTF;
	NSMutableArray *tableData;
	IBOutlet NSTableView *secondTableView;
}

- (IBAction)setPidLimit:(NSButton *)sender;
- (IBAction)deletePid:(NSButton *)sender;
- (IBAction)procCPULimiterResume:(NSButton *)sender;
- (IBAction)procCPULimiterSuspend:(NSButton *)sender;
- (IBAction)printStats:(NSButton *)sender;
- (IBAction)exitApp:(NSButton *)sender;


@end
