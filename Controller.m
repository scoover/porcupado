//
//  Controller.m
//  Porcupado
//
//  Created by Randy on 1/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Controller.h"

@implementation Controller

// preferences
NSString	*prefTimeStampFormat	= @"prefTimeStampFormat";
NSString	*prefDefaultFilter		= @"prefDefaultFilter";
NSString	*prefLastFilter			= @"prefLastFilter";
NSString	*prefTimeStampFormatDef	= @"%y%m%d-%H%M-";

+ (void)initialize {
    [super initialize];

	// register default preferences
    NSDictionary	*prefDict= [NSDictionary dictionaryWithObjects:
		[NSArray arrayWithObjects:prefTimeStampFormatDef, [NSNumber numberWithInt: 0], [NSNumber numberWithInt: 0], nil]
		forKeys:[NSArray arrayWithObjects:prefTimeStampFormat, prefDefaultFilter, prefLastFilter, nil]];
    [[NSUserDefaults standardUserDefaults] registerDefaults:prefDict];
}

+ (int)defaultFilterType {
	NSUserDefaults *	defaults = [NSUserDefaults standardUserDefaults];
	NSNumber *			filterType;
	
	if (defaults) 
		filterType = [defaults objectForKey:prefDefaultFilter];
	
	if (filterType == nil)
		return 0;
	else
		return [filterType intValue];
}

- (void)awakeFromNib {
	NSUserDefaults *	defaults = [NSUserDefaults standardUserDefaults];
	int					filterSelection = 0;
		
	if (defaults) 
		filterSelection = [[defaults objectForKey:prefDefaultFilter] intValue];

	// setup preferences filter nspopupbutton
	[prefFilter removeAllItems];
	[prefFilter addItemWithTitle:@"Last Filter"];
	[[prefFilter menu] addItem:[NSMenuItem separatorItem]];
	[prefFilter addItemsWithTitles:[NSArray arrayWithObjects:
								   @"Everything", 
								   @"JPG: Images", 
								   @"MOV: Movies", 
								   @"MP3: Audio Files", 
								   @"WAV: Audio Files", 
								   nil]];
	[prefFilter selectItemAtIndex:[Controller defaultFilterType]];
}

#pragma mark -
#pragma mark Preferences

+ (NSString *)timestampFormat {
	NSUserDefaults *	defaults = [NSUserDefaults standardUserDefaults];
	NSString *			returnValue = nil;

	if (defaults) 
		returnValue = [defaults objectForKey:prefTimeStampFormat];
	
	if (returnValue == nil)
		return @"Error";
	else
		return returnValue;
}

+ (int)defaultFilter {
	NSUserDefaults *	defaults = [NSUserDefaults standardUserDefaults];
	int					returnValue = -1;
	
	if (!defaults) 
		returnValue = 0;
	else
		returnValue = [self defaultFilterType];
		
	// if the default filter is "Last Filter" then find out what the last filter was
	if(returnValue < 2) 
		returnValue = [[defaults objectForKey:prefLastFilter] intValue];
	else 
		returnValue -= 2;

	return returnValue;
}

+ (void)setLastFilter:(int)indexOfLastFilter {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
	if (defaults) {
		[defaults setObject:[NSNumber numberWithInt:indexOfLastFilter] forKey:prefLastFilter];
		[defaults synchronize];
	}
	else
		NSLog(@"Error accessing preferences...");
}


- (IBAction)openPreferenceWindow:(id)sender {
	NSString *			timestampFormat;
	NSUserDefaults *	defaults = [NSUserDefaults standardUserDefaults];

	if (defaults) 
		timestampFormat = [defaults objectForKey:@"prefTimeStampFormat"];
	if (timestampFormat == nil)
		timestampFormat = @"Error";

	// set preference fields to their current values
	[prefFilter selectItemAtIndex:[Controller defaultFilterType]];
	[prefTimestampText setStringValue:timestampFormat];

	// run the preferences window modally
	[NSApp runModalForWindow:prefWindow];
}

- (IBAction)closePreferenceWindow:(id)sender {
	// check if the user pressed OK
	if (![[sender title] caseInsensitiveCompare:@"Ok"]) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		if (defaults) {
			// save the updated settings and store them
			[defaults setObject:[Controller stringByRemovingWhitespace:[prefTimestampText stringValue]] forKey:prefTimeStampFormat];
			[defaults setObject:[NSNumber numberWithInt:[prefFilter indexOfSelectedItem]] forKey:prefDefaultFilter];
			[defaults synchronize];
		}
		else
			NSLog(@"Error accessing preferences...");
	}

	[prefWindow close];	
}

- (IBAction)restoreDefaultPreferences:(id)sender {
	[prefTimestampText setStringValue:prefTimeStampFormatDef];
	[prefFilter selectItemAtIndex:0];
}

#pragma mark -
#pragma mark Delegates

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
	return YES;
}

- (void)windowWillClose:(NSNotification *)notification {
	// need to stop modal if preferences window is closing (especially from red window close button which isn't trapped with the buttons)
	if([notification object] == prefWindow) 
		[NSApp stopModal];
}

#pragma mark -
#pragma mark Whitespace Management

// whitespace trim guidance here: http://www.cocoabuilder.com/archive/message/cocoa/2008/12/24/226191
+ (NSString *)stringByRemovingCharactersInSet:(NSString *)myString charSet:(NSCharacterSet*)charSet options:(unsigned)mask {
	NSRange				range;
	NSMutableString*	newString = [NSMutableString string];
	unsigned			len = [myString length];

	mask &= ~NSBackwardsSearch;
	range = NSMakeRange (0, len);

	while(range.length) {
		NSRange substringRange;
		unsigned pos = range.location;

		range = [myString rangeOfCharacterFromSet:charSet options:mask range:range];
		if (range.location == NSNotFound)
			range = NSMakeRange (len, 0);

		substringRange = NSMakeRange (pos, range.location - pos);
		[newString appendString:[myString substringWithRange:substringRange]];

		range.location += range.length;
		range.length = len - range.location;
	}

	return newString;
}

+ (NSString *)stringByRemovingWhitespace:(NSString *)myString {
	// create NSCharacterSet with list of illegal file system characters (for Windows)
	return [Controller stringByRemovingCharactersInSet:myString charSet:[NSCharacterSet characterSetWithCharactersInString:@" ?[]/\\=+<>:;\",*|"] options:0];
}

@end
