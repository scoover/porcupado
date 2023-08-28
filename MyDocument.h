//
//  MyDocument.h
//  Porcupado
//
//  Created by Randy on 2/7/09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "CFBrowserItem.h"
#import "IKImageFlowView.h"
// Quartz framework provides the QLPreviewPanel public API
#import <Quartz/Quartz.h>

@class IKImageFlowView;

@interface MyDocument : NSDocument <QLPreviewPanelDataSource, QLPreviewPanelDelegate> {
	// primary window and view objects
    IBOutlet id					mainWindow;
	NSString *					folder;
	NSString *					xdcamFolder;
	NSMutableArray *			folderContents;
	NSMutableArray *			groups;

	// outlets
    IBOutlet id					typePopUp;
    IBOutlet id					restartButton;
    IBOutlet id					backButton;
    IBOutlet id					forwardButton;
    IBOutlet id					finishButton;
	IBOutlet id					folderDrop;
    IBOutlet id					fileCount;
    IBOutlet id					prefixText;
    IBOutlet id					nameText;
    IBOutlet id					groupPopUp;
    IBOutlet id					groupNameWindow;
	IBOutlet id					xdcamFolderWindow;
    IBOutlet id					groupAssetCount;
	IBOutlet id					xdcamFolderDrop;
	
	// coverflow objects
	// BOOL						_canIgnoreChangeNotification;
	NSString *					contentsPath;
	IBOutlet IKImageFlowView *	coverFlow;
	
	
    QLPreviewPanel* previewPanel;
}

- (IBAction)addGroupPress:(id)sender;
- (IBAction)getGroupNamePress:(id)sender;
- (IBAction)renameGroupPress:(id)sender;
- (IBAction)closeNameSheetPress:(id)sender;
- (IBAction)quickLookView:(id)sender;
- (IBAction)ungroupActiveCFAsset:(id)sender;
- (IBAction)changeView:(id)sender;
- (IBAction)checkForCompletionAndProcess:(id)sender;
- (IBAction)closeXDCamFolderSheetPress:(id)sender;
- (IBAction)jumpToFirst:(id)sender;
- (IBAction)jumpToLast:(id)sender;

- (IBAction)updateCoverFlowContents:(id)sender;
- (IBAction)deleteActiveCFAsset:(id)sender;
- (IBAction)skipActiveCFAsset:(id)sender;
- (IBAction)reloadCoverFlow:(id)sender;

- (BOOL)folderDragNotification:(NSView *)sender draggingInfo:(id <NSDraggingInfo>)info;
-(void)getXDCamModifiedDates;
- (NSMutableDictionary *)createGroup:(NSString *)prefix name:(NSString *)name;

@end
