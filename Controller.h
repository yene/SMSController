//
//  Controller.h
//  smslib
//
//  Created by Jan Galler on 20.02.11.
//  Copyright 2011 PQ-Developing.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#import "smslib.h"

@class SMSTester;
@interface Controller : NSObject {
	IBOutlet id xField;
	IBOutlet id yField;
	IBOutlet id zField;
	IBOutlet id enterButton;
	IBOutlet id smsIndicator;
	IBOutlet id smsWindow;
	IBOutlet id smsSound;
	IBOutlet id smsLog;
	
	SMSTester *smsTester;
	int mode;
	double resultMotion;
    NSMutableString *log;
	sms_acceleration accel;

}

@property()int mode;
@property()double resultMotion;

-(IBAction)pushEnter:(id)sender;
-(void)setFloatValues:(NSNotification *)notification;
-(void)loopData;
-(void)cleanDisplay;
-(void)securityStuff;
-(void)speekText:(NSString *)text;
-(NSString *)logDate;
-(void)logMovement;
-(void)motionLog:(NSString *)text;
- (void)logMessage: (NSString *)theString;
- (int)test;

@end
