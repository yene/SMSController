//
//  Controller.m
//  smslib
//
//  Created by Jan Galler on 20.02.11.
//  Copyright 2011 PQ-Developing.com. All rights reserved.
//

#import "Controller.h"

@implementation Controller
@synthesize mode, resultMotion;

- (id) init
{
	self = [super init];
	if (self != nil) {
	
		
		// 0: Start-mode
		// 1: Stop-mode
		self.mode = 0;
		
		[self motionLog:@"fail"];
        
       
        
	}
	return self;
}

- (void)changeDesktopBackground {
    //@"com.apple.desktop"
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults addSuiteNamed:@"com.apple.desktop"];
    NSString *wallpaperFolder = [[userDefaults valueForKeyPath:@"Background.0.DSKDesktopPrefPane.UserFolderPaths"] objectAtIndex:0];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:wallpaperFolder error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.jpg' OR self ENDSWITH '.png'"];
    NSMutableArray *onlyPictures = [NSMutableArray arrayWithArray:[dirContents filteredArrayUsingPredicate:fltr]];
    
    
    NSURL *oldImage = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:[NSScreen mainScreen]];
    
    // TODO: remove current wallpaper form list
    NSUInteger indexToRemove = [onlyPictures indexOfObject:[[oldImage path] lastPathComponent]];
    [onlyPictures removeObjectAtIndex:indexToRemove];
    
    int r = arc4random() % [onlyPictures count];
    NSString *newPicture = [onlyPictures objectAtIndex:r];
    newPicture = [NSString stringWithFormat:@"%@/%@", wallpaperFolder, newPicture];
    NSURL *asdf = [NSURL fileURLWithPath:newPicture];
    
    NSDictionary *oldSettings = [[NSWorkspace sharedWorkspace] desktopImageOptionsForScreen:[NSScreen mainScreen]];
    BOOL bla = [[NSWorkspace sharedWorkspace] setDesktopImageURL:asdf forScreen:[NSScreen mainScreen] options:oldSettings error:nil];
    
    NSLog(@"bla %i", bla);
}

- (void)windowWillClose:(NSNotification *)aNotification {
	[NSApp terminate:self];
}

-(void)awakeFromNib{
	[smsWindow center];
	[smsWindow setDelegate:self];
}

-(void)speekText:(NSString *)text{
	
	NSSpeechSynthesizer *syn = [[NSSpeechSynthesizer alloc] init];
	NSString *voiceID = [[NSSpeechSynthesizer availableVoices] objectAtIndex:20];
    [syn setVoice:voiceID];
	
	[syn startSpeakingString:text];
	[syn release];
	
}

// Start or stop calculating
-(IBAction)pushEnter:(id)sender{
	
	if ([[enterButton title]isEqualToString:@"Stop"]) {
		[enterButton setTitle:@"Start"];
		self.mode = 0;
		
	//	[self speekText:@"stop sudden motion observer"];
		
		[self cleanDisplay];
	}else if([[enterButton title]isEqualToString:@"Start"]){
		[enterButton setTitle:@"Stop"];
		self.mode = 1;
		
		[self speekText:@"start sudden motion observer"];
		
		[self performSelectorInBackground:@selector(loopData) withObject:nil];
	}

}

// Set values to interface
-(void)setFloatValues:(NSDictionary *)dict{
	
	// Get data
	double xValue = [[dict objectForKey:@"xValue"] floatValue];
	double yValue = [[dict objectForKey:@"yValue"] floatValue];
	double zValue = [[dict objectForKey:@"zValue"] floatValue];
	
	// Make them positiv
	xValue = (xValue - 0.1);
	zValue = (zValue - 1.04);
	xValue = sqrt(pow(xValue, 2));
	yValue = sqrt(pow(yValue, 2));
	zValue = sqrt(pow(zValue, 2));
	
	// Set values to the interface
	[xField setStringValue:[NSString stringWithFormat:@"%f",xValue]];
	[yField setStringValue:[NSString stringWithFormat:@"%f",yValue]];
	[zField setStringValue:[NSString stringWithFormat:@"%f",zValue]];
	
	/*
	 NSLog(@"|X|:%f",xValue);
	 NSLog(@"|Y|:%f",yValue);
	 NSLog(@"|Z|:%f",zValue);
	 */
	
	//Values für resultMotion
	/*
	 rmx
	 rmy
	 rmz
	 */
	// Try some calculations
	self.resultMotion = ((xValue + yValue + zValue)*10);
	//NSLog(@"Result: %f",resultMotion);
	
	// Set the result to the indicator
	[smsIndicator setDoubleValue:self.resultMotion];
	[self securityStuff];
	[self logMovement];
}

-(void)securityStuff{
	if ([smsSound state] == NSOnState ){ 
		NSSound *warningSound = [NSSound soundNamed:@"SMSControllerSoundWarning"];
		NSSound *alarmSound = [NSSound soundNamed:@"SMSControllerSoundAlarm"];
		
		if (self.resultMotion >= 2 && self.resultMotion <= 3) {
			//NSLog(@"Warning");
			if ([warningSound isPlaying] == YES ||[alarmSound isPlaying] == YES) {
			}else {
				[self speekText:@"warning"];
				//[warningSound play];
                [self changeDesktopBackground];
			}
		}else if (self.resultMotion >= 3) {
			//NSLog(@"ALARM");
			if ([warningSound isPlaying] == YES ||[alarmSound isPlaying] == YES) {
			}else {
				//[self speekText:@"alarm"];
				//[alarmSound play];
			}
		}
		
	}

	
}

-(void)logMovement{
	if ([smsLog state] == NSOnState ){
		[self motionLog:[NSString stringWithFormat:@"%@: %f",@"total movement",self.resultMotion]];
	}
}

// Make a loop to get the SMS data
-(void)loopData{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	while (self.mode == 1) {
        [self test];
		[NSThread sleepForTimeInterval:0.1];
	}
	
	[pool release];
}

-(NSString *)logDate{
	NSDate *now = [NSDate date];
	return [NSString stringWithFormat:@"%@",now];
}

-(void)motionLog:(NSString *)text{
	
	NSString *homeDir = NSHomeDirectory();
    NSString* fullPath = [homeDir stringByAppendingPathComponent:@"/Library/Logs/MovementSecurity	.log"];
	
	NSString *oldContent = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];
	
	if (oldContent == nil) {
		[[NSFileManager defaultManager] createFileAtPath:fullPath contents:nil attributes:nil];
		NSLog(@"Logfile created");
		NSString *new = [NSString stringWithFormat:@"%@: %@",[self logDate],text];
		[new writeToFile:fullPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
	}else {
		NSString *new = [NSString stringWithFormat:@"%@: %@",[self logDate],text];
		
		NSString *content = [NSString stringWithFormat:@"%@\n%@",oldContent,new];
		
		[content writeToFile:fullPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
	}
	
}

- (int)test {
	int i, length, result;
	log = [[NSMutableString alloc] init];
	
	[log appendString:@"\n========== SMSTest Report ==========\n"];
    
	// Start up SMS access
	result = smsStartup(self, @selector(logMessage:));
	if (result != SMS_SUCCESS) {
		// Couldn't start calibration.
		[log appendString:@"\n========== end ==========\n"];
        //		printf([log cString]);
		NSLog(@"%@",log);
		return result;
	}
	
	// Fetch and display raw data
	[log appendString:@"\nRaw data:"];
	length = smsGetBufferLength();
	char *buffer = malloc(length);
	smsGetBufferData(buffer);
	for (i = 0; i < length; i++) {
		if (i % 16 == 0) {
			[log appendString:@"\n"];
		}
		[log appendString:[NSString stringWithFormat:@"%02.2hhx ", buffer[i]]];
	}
	[log appendString:@"\n\n"];
	
	// Load calibration
	[log appendString:@"Loading any saved calibration: "];
	if (smsLoadCalibration()) {
		[log appendString:@"success.\n\n"];
	} else {
		[log appendString:@"no saved calibration.\n\n"];
	}
	
	// Fetch and display calibration
	[log appendString:smsGetCalibrationDescription()];
	
	// Fetch and display one sample of calibrated acceleration
	[log appendString:@"\nFetching calibrated data: "];
	result = smsGetData(&accel);
	if (result != SMS_SUCCESS) {
		[log appendString:@"failed.\n"];
		[log appendString:@"\n========== end ==========\n"];
        //		printf([log cString]);
		NSLog(@"%@",log);
		return result;
	}
	[log appendString:@"success.\n"];
	[log appendString:[NSString stringWithFormat:@"    X axis:%f\n", accel.x]];
	[log appendString:[NSString stringWithFormat:@"    Y axis:%f\n", accel.y]];
	[log appendString:[NSString stringWithFormat:@"    Z axis:%f\n", accel.z]];
	
	[log appendString:@"\n========== end ==========\n"];
    //	printf([log cString]);
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f",accel.x],@"xValue",[NSString stringWithFormat:@"%f",accel.y],@"yValue",[NSString stringWithFormat:@"%f",accel.z],@"zValue",nil];
	
    [self performSelectorOnMainThread:@selector(setFloatValues:) withObject:dict waitUntilDone:YES];
    
	return 0;
}

- (void)logMessage: (NSString *)theString {
	[log appendString:theString];
}


// Clean display by pressing 'stop'
-(void)cleanDisplay{
	[xField setStringValue:@""];
	[yField setStringValue:@""];
	[zField setStringValue:@""];
	[smsIndicator setDoubleValue:0];
}

@end
