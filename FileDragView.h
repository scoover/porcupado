//
//  FileDragView.h
//  DragTest
//
//  Created by rhulett on 9/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>

@interface FileDragView : NSImageView {
	NSString		*path;
	id				delegate;
	NSTimer			*resetTimer;          
	NSImage			*emptyIcon, *fullIcon;
	NSString		*fileType;
}

- (NSString *)getPath;
- (void)setDelegate:(id)val;
- (id)delegate;
- (BOOL)hasPath;
- (void)reset;
- (void)setIcons:(NSImage *)dragIcon checkedIcon:(NSImage *)checkedIcon;
- (void)setTargetToFolder;
- (void)setTargetToFileExtension:(NSString *)extension;

- (CAKeyframeAnimation *)shakeAnimation:(NSRect)frame;

@end

@interface NSObject (FolderDragView)
// return BOOL indicating whether path is acceptable
- (BOOL)folderDragNotification:(NSView *)sender draggingInfo:(id <NSDraggingInfo>)info;
@end