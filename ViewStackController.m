//
//  ViewStackController.m
//  Porcupado
//
//  Created by Randy on 1/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ViewStackController.h"

// external string constants
NSString *const VSCViewKey =				@"VSCViewKey";
// internal string constants
NSString *const VSCStillExistsKey =			@"VSCStillExistsKey";
NSString *const VSCIsHiddenKey =			@"VSCIsHiddenKey";
NSString *const VSCPosition =				@"VSCPosition";
NSString *const VSCAlignment =				@"VSCAlignment";
  NSString *const VSCAlignmentLeft =		  @"VSCAlignment_Left";
  NSString *const VSCAlignmentCenter =		  @"VSCAlignment_Center";
  NSString *const VSCAlignmentRight =		  @"VSCAlignment_Right";

@implementation ViewStackController

// ANIMATION STEPS
// 1 Fade out existing windows that will be hidden.
// 2 If window is growing, resize the window larger.
// 3 If auxilliary views are moving out out, move them out. Also, translate existing views.
// 4 If auxilliary views are moving in, move them in. Also, fade in new windows. 
// 5 If the window is shrinking, resize the window smaller.

// IMMEDIATE CHANGES
// nsmatrix stretches on move (button 4) sometimes
// nsmatrix sometimes disappears off screen
// deal with memory management on viewanimations and animationarrays
// clean out extra comments
// comment code

// FUTURE CHANGES
// make growing vs. shrinking WINDOW happen at different times in animation stack
// make aux view in vs out happen at different times in animation stack

- init {
    return [self initWith:nil view:nil];
}

- initWith:(NSWindow *)thisWindow view:(NSView *)thisView {    
	if ((self = [super init])) {
		window = thisWindow;
		view = thisView;
		history = [[NSMutableArray alloc] init];

		iAnimationIndex = 0;
		
		// set default values
		[self setVerticalPadding:15.0];
		[self setTopAndBottomPad:0.0];
		[self setDuration:0.25];
		[self setLeftRightPadding:0.0];

		// set resize masks which are critical to view placement working properly
		if(window != nil) 
			[[window contentView]  setAutoresizingMask:0];


		if (view != nil)
			[view  setAutoresizingMask:12];
    }

    return self;
}

- (void)dealloc {
	[history dealloc];
	[super dealloc];
}

- (void)setDuration:(float)newDuration {
	fDuration = newDuration;
}

- (void)setVerticalPadding:(float)newVerticalPadding {
	fVertPad = newVerticalPadding;
}

- (void)setTopAndBottomPad:(float)newTopAndBottomPad {
	fTopBottomPad = newTopAndBottomPad;
}

- (void)setLeftRightPadding:(float)newLeftRightPad {
	fLeftRightPad = newLeftRightPad;
}

- (void)getViewHeightAndWidth:(NSSize *)thisSize {
	int				i = 0;
	
	thisSize->width = 0.0;
	thisSize->height = 0.0;
	
	NSDictionary	*currentDict;
	NSEnumerator	*enumerator = [history objectEnumerator];

	while (currentDict = [enumerator nextObject]) 
		if([[currentDict objectForKey:VSCStillExistsKey] boolValue]) {
			if(thisSize->width < [[currentDict objectForKey:VSCViewKey] frame].size.width)
				thisSize->width = [[currentDict objectForKey:VSCViewKey] frame].size.width;
				
			thisSize->height += [[currentDict objectForKey:VSCViewKey] frame].size.height;
			i++;
		}

	thisSize->height += ((i - 1) * fVertPad) + fTopBottomPad * 2;
	thisSize->width += 2 * fLeftRightPad;
}

- (void)buildViewStack:(NSArray *)viewStack {
	NSSize				viewSize;
	NSMutableDictionary	*currentDict, *vsDict;
	NSView				*currentView;
	NSEnumerator		*vsEnumerator = [viewStack objectEnumerator];
	NSEnumerator		*enumerator;
	float				fXPos;
	
	[self getViewHeightAndWidth:&viewSize];
	viewSize.height -= fTopBottomPad;
	
	while (vsDict = [vsEnumerator nextObject]) {
		enumerator = [history objectEnumerator];

		while (currentDict = [enumerator nextObject]) {
			currentView = [currentDict objectForKey:VSCViewKey];
			
			if([currentView isEqual:[vsDict objectForKey:VSCViewKey]])
				break;
		}
		
		if([[currentDict objectForKey:VSCStillExistsKey] boolValue]) {
			if(![(NSString *)[currentDict objectForKey:VSCAlignment] compare:VSCAlignmentRight])
				fXPos = viewSize.width - [currentView frame].size.width - fLeftRightPad;
			else if(![(NSString *)[currentDict objectForKey:VSCAlignment] compare:VSCAlignmentCenter])
				fXPos = (viewSize.width - [currentView frame].size.width)/2;
			else
				fXPos = 0.0 + fLeftRightPad;

			[currentDict setObject:[NSValue valueWithPoint:NSMakePoint(fXPos, viewSize.height - [currentView frame].size.height)]
				forKey:VSCPosition];

			viewSize.height -= [currentView frame].size.height;
			viewSize.height -= fVertPad;
		}
	}
}

- (void)addToViewHistory:(NSArray *)viewStack {
	int					i, j;
	BOOL				bFound;
	NSMutableDictionary	*thisDict;

	if((window == nil) || (view == nil))
		return;		
	
	// clear out all the view still exists flags
	for(i = 0; i < [history count]; i++)
		[[history objectAtIndex:i] setObject:[NSNumber numberWithBool:NO] forKey:VSCStillExistsKey];	
		
	// step through viewStack and flag views that are active
	for(i = 0; i < [viewStack count]; i++) {
		bFound = NO;
		
		for(j = 0; j < [history count]; j++)
			if([[[history objectAtIndex:j] objectForKey:VSCViewKey] isEqual:[[viewStack objectAtIndex:i] objectForKey:VSCViewKey]]) {
				[[history objectAtIndex:j] setObject:[NSNumber numberWithBool:YES] forKey:VSCStillExistsKey];	
				bFound = YES;
				break;
			}
		
		// if the viewStack object doesn't exist in the history object, add it
		if(!bFound) {
			// copy the dictionary object 
			thisDict = [[NSMutableDictionary alloc] initWithDictionary:[viewStack objectAtIndex:i]];
			// set the still-exists key to YES
			[thisDict setObject:[NSNumber numberWithBool:YES] forKey:VSCStillExistsKey];	
			// set the is-hidden key to YES
			[thisDict setObject:[NSNumber numberWithBool:YES] forKey:VSCIsHiddenKey];	
			
			// set alignment to left unless specified otherwise
			if([thisDict objectForKey:VSCAlignment] == nil)
				[thisDict setObject:VSCAlignmentLeft forKey:VSCAlignment];	
			
			// add the object ot the history object
			[history addObject:thisDict];
			// since the "copy" and "addObject" operations both increased the retain count, perform one release
			[thisDict release];
		}
	}
}

- (void)doNextAnimation {
	int					i,j;
	BOOL				bIsHidden, bExistsInNewViewStack;
	NSView				*existingView, *currentView;
	NSEnumerator		*enumerator;
	NSMutableDictionary	*currentDict;
	
	for(i=0;i<[viewAnimations count];i++)
		if([viewAnimations objectAtIndex:i])
			NSLog(@"%@",[[viewAnimations objectAtIndex:i] description]);

	if(!iAnimationIndex && [[[viewAnimations objectAtIndex:0] viewAnimations] count]) {
		// step through history and setup necessary animations
		for(i = 0; i < [history count]; i++) {
			currentDict = [history objectAtIndex:i];
			bIsHidden = [[currentDict objectForKey:VSCIsHiddenKey] boolValue];
			bExistsInNewViewStack = [[currentDict objectForKey:VSCStillExistsKey] boolValue];
			
			// change status to hidden
			if (!bExistsInNewViewStack && !bIsHidden) 
				[currentDict setObject:[NSNumber numberWithBool:YES] forKey:VSCIsHiddenKey];	
		}
		
		// if window setFrame is performed here on shrinking window, there is no flash in the window title bar
		// it is not clear why...?
		if (!NSEqualRects([window frame],newWindowFrame)) {
			[view setAutoresizingMask: NSViewMaxXMargin | NSViewMaxYMargin];
			[view setFrame:newViewFrame];
		}
		
		[[viewAnimations objectAtIndex:0] startAnimation];
		iAnimationIndex=1;
		return;
	}
	else if(!iAnimationIndex)
		iAnimationIndex=1;
	
	if (!NSEqualRects([window frame], newWindowFrame)) {
		[view setAutoresizingMask: NSViewMaxXMargin | NSViewMaxYMargin];
		[view setFrame:newViewFrame];
		[window setFrame:newWindowFrame display:YES];
	}

	for(j = 1; j <= 2; j++) {
		if((iAnimationIndex == j) && [[[viewAnimations objectAtIndex:j] viewAnimations] count]) {
			if(j == 2) {
				for(i = 0; i < [history count]; i++) {
					currentDict = [history objectAtIndex:i];
					bIsHidden = [[currentDict objectForKey:VSCIsHiddenKey] boolValue];
					bExistsInNewViewStack = [[currentDict objectForKey:VSCStillExistsKey] boolValue];

					// if element is active and hidden
					if(bExistsInNewViewStack && bIsHidden) {
						// set the view's start position
						[[currentDict objectForKey:VSCViewKey] setFrameOrigin:[[currentDict objectForKey:VSCPosition] pointValue]];
						
						enumerator = [[view subviews] objectEnumerator];
				
						// check if the view is already added to "view"
						while (existingView = [enumerator nextObject])
							if([currentView isEqual:existingView])
								break;
								
						// only addSubview if the view is not already added to "view"
						if(existingView == nil) {
							// hide the subview so it doesn't flash at 100% alpha on addSubView
							[[currentDict objectForKey:VSCViewKey] setHidden:YES];
							[view addSubview:[currentDict objectForKey:VSCViewKey]];
						}
						
						// change status from hidden
						[currentDict setObject:[NSNumber numberWithBool:NO] forKey:VSCIsHiddenKey];	
					}
				}
			}
					
			[[viewAnimations objectAtIndex:j] startAnimation];
			iAnimationIndex++;
			return;
		}
		else if(iAnimationIndex==j) 
			iAnimationIndex++;
	}
	
	if(iAnimationIndex == 3)
		[viewAnimations release];
}

- (void)updateFromHistory:(NSArray *)viewStack animate:(BOOL)animate {
	NSSize				viewSize;
	NSPoint				viewOrigin = [view frame].origin;
	int					i;
	NSMutableDictionary	*currentDict;
	BOOL				bIsHidden, bExistsInNewViewStack;
	NSView				*thisView, *existingView;
	NSMutableArray		*animationArrays = [[NSMutableArray alloc] init];
	
	// store the viewstack in the history array
	[self addToViewHistory:viewStack];

	if((window == nil) || (view == nil) || (![history count]))
		return;

	if(animate) 
		for(i = 0; i < 3; i++)
			[animationArrays addObject:[[NSMutableArray alloc] init]];
	
	// get view stack height
	[self getViewHeightAndWidth:&viewSize];
	
	// set the view size and location
	newViewFrame.size.height = viewSize.height;
	newViewFrame.size.width = viewSize.width;
	newViewFrame.origin.x = viewOrigin.x;
	newViewFrame.origin.y = viewOrigin.y;
		
	// include window-to-view gap in viewSize (use contentRectForFrameRect to account for window bar height)
	viewSize.height += [NSWindow contentRectForFrameRect:[window frame] styleMask:[window styleMask]].size.height - [view frame].size.height;
	viewSize.width += [window frame].size.width - [view frame].size.width;
	
	// determine content-only portion of window (i.e. without the window title bar)
    newWindowFrame = [NSWindow contentRectForFrameRect:[window frame] styleMask:[window styleMask]];
    newWindowFrame.origin.y += newWindowFrame.size.height;
	newWindowFrame.origin.y -= viewSize.height;
    newWindowFrame.size.height = viewSize.height;
    newWindowFrame.size.width = viewSize.width;
    // convert content-only coordinates to full-window coordinates (i.e. with the window title bar)
    newWindowFrame = [NSWindow frameRectForContentRect:newWindowFrame styleMask:[window styleMask]];
	
	// set the window size and position if not animating
    if(!animate)
		[window setFrame:newWindowFrame display:YES];
	
	// update non-"view"/viewStack controls... step through 
	NSEnumerator	*enumerator = [[[window contentView] subviews] objectEnumerator];
	NSView			*currentView;

	while (currentView = [enumerator nextObject]) {
		if(currentView == view)
			continue;
			
		viewOrigin = [currentView frame].origin;
		if(animate) {
			viewOrigin.x -= [window frame].size.width - newWindowFrame.size.width;
			viewOrigin.y -= [window frame].size.height - newWindowFrame.size.height;
		}
		
		// move the view laterally if it is to the right of the view stack view
		if([currentView frame].origin.x + [currentView frame].size.width >
			[view frame].origin.x + [view frame].size.width)
			viewOrigin.x += newViewFrame.size.width - [view frame].size.width; 

		// move the view vertically if it is below the view stack view
		if([currentView frame].origin.y + [currentView frame].size.height < [view frame].origin.y) {
			viewOrigin.y += [view frame].size.height - newViewFrame.size.height;
		}
			
		// if animation is active, setup animated move
		if(animate) {
			[[animationArrays objectAtIndex:1] addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				currentView, NSViewAnimationTargetKey, [NSValue valueWithRect:NSMakeRect(viewOrigin.x, viewOrigin.y, 
				[currentView frame].size.width, [currentView frame].size.height)], 
				NSViewAnimationEndFrameKey, nil]];
		}
		// otherwise, just put the view where it needs to be...
		else
			[currentView setFrameOrigin:viewOrigin];
	}	
	
	// set view size and position 
	if(!animate) [view setFrame:newViewFrame];
	// determine view locations for active views
	[self buildViewStack:viewStack];

	// step through history and setup necessary animations
	for(i = 0; i < [history count]; i++) {
		currentDict = [history objectAtIndex:i];
		bIsHidden = [[currentDict objectForKey:VSCIsHiddenKey] boolValue];
		bExistsInNewViewStack = [[currentDict objectForKey:VSCStillExistsKey] boolValue];
		thisView = [currentDict objectForKey:VSCViewKey];

		// if element is active and hidden
		if(bExistsInNewViewStack && bIsHidden) {
			// set the view's start position
			if(!animate) [thisView setFrameOrigin:[[currentDict objectForKey:VSCPosition] pointValue]];
			
			enumerator = [[view subviews] objectEnumerator];
	
			// check if the view is already added to "view"
			while (existingView = [enumerator nextObject])
				if([currentView isEqual:existingView])
					break;
					
			// only addSubview if the view is not already added to "view"
			if(existingView == nil)
				if(!animate) [view addSubview:[currentDict objectForKey:VSCViewKey]];
			
			// if animation is active, setup fade in
			if(animate) 
				[[animationArrays objectAtIndex:2] addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					thisView, NSViewAnimationTargetKey, 
					NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil]];
			
			// change status from hidden
			if(!animate) [currentDict setObject:[NSNumber numberWithBool:NO] forKey:VSCIsHiddenKey];	
		}
		// if element is active and not hidden but has moved
		else if (bExistsInNewViewStack && !bIsHidden &&//) { //  && 
			(([thisView frame].origin.x != [[currentDict objectForKey:VSCPosition] pointValue].x) || 
			([thisView frame].origin.y != [[currentDict objectForKey:VSCPosition] pointValue].y))) {

			// if animation is active, setup animated move
			if(animate) {
				[[animationArrays objectAtIndex:1] addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					thisView, NSViewAnimationTargetKey, 
					[NSValue valueWithRect:NSMakeRect(
						[[currentDict objectForKey:VSCPosition] pointValue].x, 
						[[currentDict objectForKey:VSCPosition] pointValue].y, 
						[thisView frame].size.width, 
						[thisView frame].size.height)], 
					NSViewAnimationEndFrameKey, nil]];
			}
			else
				[thisView setFrameOrigin:[[currentDict objectForKey:VSCPosition] pointValue]];
		}
		else if (!bExistsInNewViewStack && !bIsHidden) {
			// if animation is active, setup fade out
			if(animate) 
				[[animationArrays objectAtIndex:0] addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					thisView, NSViewAnimationTargetKey, 
					NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil]];
			
			// change status to hidden
			if(!animate) [currentDict setObject:[NSNumber numberWithBool:YES] forKey:VSCIsHiddenKey];	
		}
		else if (!bExistsInNewViewStack && bIsHidden)
			;
	}

	if(animate) {
		viewAnimations = [[NSMutableArray alloc] init];

		for(i=0;i<3;i++) {
			[viewAnimations addObject:[[NSViewAnimation alloc] initWithViewAnimations:[animationArrays objectAtIndex:i]]];
			[(NSViewAnimation *)[viewAnimations objectAtIndex:i] setDuration:fDuration * (([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)? 10:1)];   
			[[viewAnimations objectAtIndex:i] setAnimationCurve:NSAnimationEaseInOut]; 
			[[viewAnimations objectAtIndex:i] setAnimationBlockingMode:NSAnimationNonblockingThreaded];
			[[viewAnimations objectAtIndex:i] setDelegate:self];
		}

		iAnimationIndex = 0;
		[animationArrays release];
		[self doNextAnimation];
	}
}

- (void)updateWindowWithViewStack:(NSArray *)viewStack {
	if((window == nil) || (view == nil) || (![history count]))
		return;		

	// update window and view positions 
	[self updateFromHistory:viewStack animate:YES];
}

- (void)initWindowWithViewStack:(NSArray *)viewStack {
	if((window == nil) || (view == nil))
		return;
	
	// update window and view positions 
	[self updateFromHistory:viewStack animate:NO];
}

- (void)animationDidEnd:(NSAnimation *)thisAnimation {
	// NSLog(@"animationDidEnd");
	[self doNextAnimation];
}

@end
