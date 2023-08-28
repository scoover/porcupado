//
//  Controller.h
//  Porcupado
//
//  Created by Randy on 1/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Controller : NSObject {
	IBOutlet id					prefTimestampText;
	IBOutlet id					prefWindow;
	IBOutlet id					prefFilter;
}

+ (NSString *)stringByRemovingCharactersInSet:(NSString *)myString charSet:(NSCharacterSet*)charSet options:(unsigned)mask;
+ (NSString *)stringByRemovingWhitespace:(NSString *)myString;

+ (NSString *)timestampFormat;
+ (int)defaultFilter;
+ (void)setLastFilter:(int)indexOfLastFilter;

- (IBAction)openPreferenceWindow:(id)sender;
- (IBAction)closePreferenceWindow:(id)sender;
- (IBAction)restoreDefaultPreferences:(id)sender;

@end
