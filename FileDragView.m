//
//  FileDragView.m
//  DragTest
//
//  Created by rhulett on 9/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "FileDragView.h"

// A few important notes:
//   1) QuartzCore.framework must be included in project
//   2) checkmark.png must be included in project

// NOTES HERE: http://www.cocoadev.com/index.pl?FakeImageView


@implementation FileDragView

- (void)updateIcon {
	NSImage		*icon;
		
	if(resetTimer) 
		resetTimer = nil;

	if([self hasPath])
		icon = fullIcon;
	else
		icon = emptyIcon;
	
	if(icon == nil)
		return;

	[self setImage:icon];
}

- (void)clearIcon {
	if(path != nil)
		[path release];
	
	path = nil;
	[self updateIcon];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
	if (self) {
		[self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
		path = nil;
		delegate = nil;
		fileType = nil;
		emptyIcon = nil;
		fullIcon = nil;
		[self updateIcon];
	}

    return self;
}

- (void)setIcons:(NSImage *)dragIcon checkedIcon:(NSImage *)checkedIcon {
	if(emptyIcon != nil)
		[emptyIcon release];
	if(fullIcon != nil)
		[fullIcon release];
		
	emptyIcon = dragIcon;
	fullIcon = checkedIcon;
		
	if(![self image])
		[self updateIcon];
}

- (void)setTargetToFolder {
	if(fileType!=nil)
		[fileType release];
	
	fileType = [[NSString alloc] initWithString:@"folder"];
}

- (void)setTargetToFileExtension:(NSString *)extension {
	if(fileType)
		[fileType release];
	
	[extension retain];
	fileType = extension;
}

- (void)reset {
	resetTimer = [NSTimer scheduledTimerWithTimeInterval:1.25
		target:self	selector:@selector(clearIcon) userInfo:NULL repeats:NO];
}

- (void)dealloc {
	if(fileType)
		[fileType release];
    
	[super dealloc];
}

- (NSString *)getPath {
	return path;
}

- (void)setDelegate:(id)val {
    delegate = val;
}

- (id)delegate {
    return delegate;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	if ([[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]]) {
		return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	BOOL			isDir, returnValue = NO;
	NSPasteboard	*pboard = [sender draggingPasteboard];
    
	if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		
		// do not accept multiple files/folders
		if([files count] != 1)
			return NO;
			
		if((fileType != nil) && (![fileType compare:@"folder"])) { 
			if(([[NSFileManager defaultManager] fileExistsAtPath:[files objectAtIndex:0] isDirectory:&isDir]) && !isDir)
				return NO;
		}
		else if((fileType!=nil) && [[[files objectAtIndex:0] pathExtension] caseInsensitiveCompare:fileType])
			return NO;
		
		if(path != nil)
			[path release];
		path = [[NSString alloc] initWithString:[files objectAtIndex:0]];
		returnValue = YES;
	    
		if ( [delegate respondsToSelector:@selector(folderDragNotification:draggingInfo:)] ) 
			if(![delegate folderDragNotification:self draggingInfo:sender])
				returnValue = NO;
		
		if(returnValue) {
			// change icon
			[self updateIcon];
			[self setAnimations:[NSDictionary dictionaryWithObject:[self shakeAnimation:[self  frame]] forKey:@"frameOrigin"]];
			[[self animator] setFrameOrigin:[self frame].origin];
		}
		else {
			[path release];
			path = nil;
		}
	}
	
    return returnValue;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return YES;
}

- (BOOL)hasPath {
	return ([path length]>0);
}

static int numberOfShakes = 4;
static float durationOfShake = 0.55f;
static float vigourOfShake = 0.06f;

- (CAKeyframeAnimation *)shakeAnimation:(NSRect)frame {
	float vigor;
	int index;
	
	vigor = vigourOfShake;
    CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation];
    CGMutablePathRef shakePath = CGPathCreateMutable();
    CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));

	for (index = 0; index < numberOfShakes; ++index)  {
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * vigor, NSMinY(frame));
		vigor *= 0.77;
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * vigor, NSMinY(frame));
		vigor *= 0.77;
	}

    CGPathCloseSubpath(shakePath);
    shakeAnimation.path = shakePath;
    shakeAnimation.duration = durationOfShake;
    return shakeAnimation;
}

@end
