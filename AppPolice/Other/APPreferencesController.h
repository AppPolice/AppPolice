//
//  APPreferencesController.h
//  AppPolice
//
//  Created by Maksym on 20/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface APPreferencesController : NSWindowController

@property (assign) IBOutlet NSMatrix *sortByMatrix;
@property (assign) IBOutlet NSMatrix *orderMatrix;
@property (assign) IBOutlet NSButton *showSystemProcessesButton;
@property (assign) IBOutlet NSButton *launchAtLoginButton;

- (IBAction)changeSortByPreferences:(id)sender;
- (IBAction)changeOrderPreferences:(id)sender;
- (IBAction)changeShowSystemProcessesPreferences:(id)sender;
- (IBAction)changeLaunchAtLoginPreferences:(id)sender;

@end
