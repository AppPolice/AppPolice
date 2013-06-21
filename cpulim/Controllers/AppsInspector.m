//
//  AppsInspector.m
//  Ishimura
//
//  Created by Maksym on 5/20/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "AppsInspector.h"
#import "clevel.h"

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



//- (void)tableViewSelectionDidChange:(NSNotification *)notification {
//    // Bold the text in the selected items, and unbold non-selected items
//    [_tableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
//        // Enumerate all the views, and find the NSTableCellViews.
//        // This demo could hard-code things, as it knows that the first cell is always an
//        // NSTableCellView, but it is better to have more abstract code that works
//        // in more locations.
//        //
//        for (NSInteger column = 0; column < rowView.numberOfColumns; column++) {
//            NSView *cellView = [rowView viewAtColumn:column];
//            // Is this an NSTableCellView?
//            if ([cellView isKindOfClass:[NSTableCellView class]]) {
//                NSTableCellView *tableCellView = (NSTableCellView *)cellView;
//                // It is -- grab the text field and bold the font if selected
//                NSTextField *textField = tableCellView.textField;
//                NSInteger fontSize = [textField.font pointSize];
//                if (rowView.selected) {
//                    textField.font = [NSFont boldSystemFontOfSize:fontSize];
//					NSLog(@"%@", rowView);
//                } else {
//                    textField.font = [NSFont systemFontOfSize:fontSize];
//                }
//            }
//        }
//    }];
//}


@end
