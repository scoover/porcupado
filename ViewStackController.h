//
//  ViewStackController.h
//  Porcupado
//
//  Created by Randy on 1/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *const VSCViewKey;
extern NSString *const VSCAlignment;
extern NSString *const VSCAlignmentLeft;
extern NSString *const VSCAlignmentCenter;
extern NSString *const VSCAlignmentRight;

@interface ViewStackController : NSWindowController {
	NSWindow		*window;
	NSView			*view;
	NSMutableArray	*viewAnimations;
	
	float			fVertPad;
	float			fDuration;
	float			fTopBottomPad;
	float			fLeftRightPad;

	int				iAnimationIndex;
	NSRect			newWindowFrame;
	NSRect			newViewFrame;
	NSMutableArray	*history;
}

- initWith:(NSWindow *)thisWindow view:(NSView *)thisView;

- (void)setDuration:(float)newDuration;
- (void)setTopAndBottomPad:(float)newTopAndBottomPad;
- (void)setVerticalPadding:(float)newVerticalPadding;
- (void)setLeftRightPadding:(float)newLeftRightPad;

- (void)initWindowWithViewStack:(NSArray *)viewStack;
- (void)updateWindowWithViewStack:(NSArray *)viewStack;

@end
