//
//  MyDocument.m
//  Porcupado
//
//  Created by Randy on 2/7/09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import "MyDocument.h"
#import "FileDragView.h"
#import "Controller.h"

@implementation MyDocument

// NEXT VERSION
// quit before processing: "Are you sure?"
// reg code: http://www.cocoadev.com/index.pl?MDFive or http://cocoa-nut.de/?tag=encryption
//   add framework to build: http://cocoadev.com/forums/comments.php?DiscussionID=435
// more checks on renames (permissions, duplicate names, etc) and rename failure log if errors occur
// only index files where there is a filename match (not all in the same group)
// file modified write: (Error Domain=NSCocoaErrorDomain Code=513 UserInfo=0x16ca4930 "You do not have appropriate access privileges to save file “081115-2015-GB_24.jpg” in folder “GingerBread”.")
//  - "As in the POSIX standard, the application either must own the file or directory or must be running as superuser for attribute changes to take effect. The method attempts to make all changes specified in attributes and ignores any rejection of an attempted modification."
// make drop zone work for individual files or groups of files...

#pragma mark -
#pragma mark String Constants

NSString	*GroupPrefix			= @"GroupPrefixKey";
NSString	*GroupName				= @"GroupNameKey";
NSString	*GroupList				= @"GroupListKey";
NSString	*SxSMediaPath			= @"BPAV/CLPR/";

#pragma mark -
#pragma mark Internal Methods

- (NSMutableArray *)listForGroup:(int) groupIndex {
	return [[groups objectAtIndex:groupIndex] objectForKey:GroupList];
}

- (NSMutableArray *)listForGroupsPopup {
	return [self listForGroup:([groupPopUp indexOfSelectedItem] - (([groupPopUp indexOfSelectedItem] > 2)? 1:0))];
}

// adds newString to NSCombobox combo in alphabetical order and only if newString is unique and not @""
- (BOOL)alphaAddStringToCombobox:(NSString *)newString combobox:(NSComboBox *)combo {
	NSMutableArray *	sortArray = [NSMutableArray arrayWithArray:[combo objectValues]];
	NSEnumerator *		enumerator = [sortArray objectEnumerator];
	NSString *			thisString;
	
	
	if(![newString length]) 
		return NO;
		
	// check for duplicates
	while ((thisString = [enumerator nextObject]))
		if(![thisString compare:newString])
			return NO;

	[sortArray addObject:newString];
	[sortArray sortUsingSelector:@selector(compare:)];
	[combo removeAllItems];
	[combo addItemsWithObjectValues:sortArray];

	return YES;
}

- (NSMutableDictionary *)createGroup:(NSString *)prefix name:(NSString *)name {
	int						i, iCount = [coverFlow focusedIndex];
	NSMutableDictionary		*newGroup = [[NSMutableDictionary alloc] init];
	NSMutableArray			*list = [[NSMutableArray alloc] init];
	NSString				*nameNoSpace, *prefixNoSpace;
	
	for(i=0; i<= iCount; i++) {
		[list addObject:[[self listForGroup:0] objectAtIndex:0]];
		[[self listForGroup:0] removeObjectAtIndex:0];
	}
	
	nameNoSpace = [Controller stringByRemovingWhitespace:name];
	prefixNoSpace = [Controller stringByRemovingWhitespace:prefix];
	
	// check for name/prefix duplicates (add to existing group with name if one already exists)
	for(i = 3; i < [groups count]; i++) 
		if( (![nameNoSpace caseInsensitiveCompare:[[groups objectAtIndex:i] objectForKey:GroupName]]) && 
		   (![prefixNoSpace caseInsensitiveCompare:[[groups objectAtIndex:i] objectForKey:GroupPrefix]])) 
			break;
	
	if( i >= [groups count]) {
		[newGroup setObject:prefixNoSpace forKey:GroupPrefix];
		[newGroup setObject:nameNoSpace forKey:GroupName];
		[newGroup setObject:list forKey:GroupList];
		
		if([[groupPopUp itemArray] count] == 3)
			[[groupPopUp menu] addItem:[NSMenuItem separatorItem]];
		
		[groupPopUp addItemWithTitle: [NSString stringWithFormat:@"%@%@", prefixNoSpace, nameNoSpace]];
		
		[self alphaAddStringToCombobox:nameNoSpace combobox:nameText];
		[self alphaAddStringToCombobox:prefixNoSpace combobox:prefixText];
		
		// add newGroup to groups array
		[groups addObject:newGroup];
		[newGroup release];
	}
	else
		[[[groups objectAtIndex:i] objectForKey:GroupList] addObjectsFromArray:list];
	
	[list release];
	
	[self reloadCoverFlow:nil];
	[coverFlow setSelectedIndex:0];
	[nameText setStringValue:@""];
	[typePopUp setEnabled:NO];
	[Controller setLastFilter:[typePopUp indexOfSelectedItem]];
	
	return newGroup;
}

- (NSDate *)getDateFromMiniDVFilename:(NSString *)filename {
    NSError *error = NULL;
    NSDate *extractedDate = nil;
    
    NSRegularExpression *regexExpression = [NSRegularExpression regularExpressionWithPattern:@"([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}_[0-9]{2}_[0-9]{2}).MOV" options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *matches = [regexExpression firstMatchInString:filename options:(NSMatchingOptions)0 range:NSMakeRange(0, filename.length)];
    
    if(matches) {
        NSString *matchString = [filename substringWithRange:[matches rangeAtIndex:1]];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd HH_mm_ss z"];
        extractedDate = [dateFormat dateFromString:[NSString stringWithFormat:@"%@ PDT",matchString]];
        NSLog(@"getDateFromMiniDVFilename: %@ --> %@",matchString, [extractedDate description]);
    }
    
    return extractedDate;
}

-(void)getXDCamModifiedDates {
	NSEnumerator *	fcEnumerator = [folderContents objectEnumerator];
	NSEnumerator *	xdcamDMGEnumerator;
	CFBrowserItem *	item; 
	NSString *		xdcamPath;
	NSError *		error = NULL;
	
	// create array from destination path of files with extension ".mov"
	NSArray	*XDCamDMGArray = [[NSArray alloc] 
							  initWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:
											 [NSString stringWithFormat:@"%@/%@", xdcamFolder, SxSMediaPath] error:nil]];
    
//    NSLog(@"xdcamFolder: %@",[xdcamFolder description]);
//    NSLog(@"SxSMediaPath: %@",[SxSMediaPath description]);
//    NSLog(@"XDCamDMGArray: %@\n",[XDCamDMGArray description]);
	
	while ((item = [fcEnumerator nextObject])) 
		if((![[[item path] pathExtension] caseInsensitiveCompare:@"MOV"]) && (![[item pairExtension] caseInsensitiveCompare:@"XML"])) {
			xdcamDMGEnumerator = [XDCamDMGArray objectEnumerator];
//            NSLog(@"Search location: %@",[NSString stringWithFormat:@"%@/%@", xdcamFolder, SxSMediaPath]);
			
            while ((xdcamPath = [xdcamDMGEnumerator nextObject])) {
//                NSLog(@"Compare A1: %@",[[[item path] lastPathComponent] stringByDeletingPathExtension]);
//                NSLog(@"Compare A2: %@",[NSString stringWithFormat:@"%@_%@", [xdcamFolder lastPathComponent],[xdcamPath lastPathComponent] ]);
//                NSLog(@"Compare B1: %@",[[[item path] lastPathComponent] stringByDeletingPathExtension]);
//                NSLog(@"Compare B2: %@\n",[NSString stringWithFormat:@"%@_%@",
//                                           [xdcamFolder lastPathComponent],[[xdcamPath lastPathComponent] substringToIndex:[[xdcamPath lastPathComponent] length]-3 ]]);
                
                // Removed [xdcamFolder lastPathComponent] from case comparison to make work in Mountain Lion
                // Old code worked before and is archived via comments
                
//				if((![[[[item path] lastPathComponent] stringByDeletingPathExtension]
//					 caseInsensitiveCompare:[NSString stringWithFormat:@"%@_%@", [xdcamFolder lastPathComponent],[xdcamPath lastPathComponent] ]]) || 
//				   (![[[[item path] lastPathComponent] stringByDeletingPathExtension] 
//					  caseInsensitiveCompare:[NSString stringWithFormat:@"%@_%@",
//					[xdcamFolder lastPathComponent],[[xdcamPath lastPathComponent] substringToIndex:[[xdcamPath lastPathComponent] length]-3 ]]])) {
				if((![[[[item path] lastPathComponent] stringByDeletingPathExtension]
                      caseInsensitiveCompare:[NSString stringWithFormat:@"%@",[xdcamPath lastPathComponent] ]]) ||
				   (![[[[item path] lastPathComponent] stringByDeletingPathExtension]
					  caseInsensitiveCompare:[NSString stringWithFormat:@"%@",
                                              [[xdcamPath lastPathComponent] substringToIndex:[[xdcamPath lastPathComponent] length]-3 ]]])) {
								  [item setModifiedDate:[[[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@/%@%@",xdcamFolder, SxSMediaPath, xdcamPath] error:&error] fileModificationDate]];
					break;
				}
            }
		}
}

#pragma mark -
#pragma mark NSDocument Methods

- (id)init {
	int			i;
    self = [super init];
	
    if (self) {
		folder = nil;
		contentsPath = nil;
		xdcamFolder = nil;
		folderContents = [NSMutableArray new];
		groups = [NSMutableArray new];
		
		// add 0:ungrouped group, 1:deletion group, and 2:skipped group
		for(i=0;i<3;i++) {
			[groups addObject:[[NSMutableDictionary alloc] init]];
			[[groups objectAtIndex:i] setObject:[[NSMutableArray alloc] init] forKey:GroupList];
			//[[[groups objectAtIndex:i] objectForKey:GroupList] release];
			[[groups objectAtIndex:i] release];
		}
    }

    return self;
}

- (void)dealloc {
	[folderContents release];
	[groups release];
	[contentsPath release];
	
	if(xdcamFolder != nil)
		[xdcamFolder release];
	
	[super dealloc];
}

- (void)awakeFromNib {
	[folderDrop setDelegate:self];
	[folderDrop setIcons:[[NSBundle bundleForClass:[self class]] imageForResource:@"Bullseye"]
			 checkedIcon:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"folder" ofType:@"png"]]];
	[folderDrop setTargetToFolder];
	
	[xdcamFolderDrop setDelegate:self];
	[xdcamFolderDrop setIcons:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"bullseye" ofType:@"png"]]
				  checkedIcon:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"folder" ofType:@"png"]]];
	[xdcamFolderDrop setTargetToFolder];
	
	// setup activity filtering
	[typePopUp removeAllItems];
	[typePopUp addItemsWithTitles:[NSArray arrayWithObjects:
								   @"Everything", 
								   @"JPG: Images", 
								   @"MOV: Movies", 
								   @"MP3: Audio Files", 
								   @"WAV: Audio Files", 
								   nil]];
	[typePopUp selectItemAtIndex:[Controller defaultFilter]];
	
	// setup group list
	[groupPopUp removeAllItems];
	[groupPopUp addItemsWithTitles:[NSArray arrayWithObjects:
									[NSString stringWithFormat:@"%@1: Ungrouped Items",[NSString stringWithUTF8String:"\xE2\x8C\x98"]], 
									[NSString stringWithFormat:@"%@2: Deleted Items",[NSString stringWithUTF8String:"\xE2\x8C\x98"]], 
									[NSString stringWithFormat:@"%@3: Skipped Items",[NSString stringWithUTF8String:"\xE2\x8C\x98"]], 
									nil]];
	[groupPopUp selectItemAtIndex:0];
	
	// setup coverFlow
	[coverFlow setDelegate:self];
	[coverFlow setDataSource:self];
	
	[typePopUp setEnabled:YES];
	[fileCount setStringValue:@""];
	
	[groupNameWindow makeFirstResponder:prefixText];
}

- (NSString *)windowNibName {
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

//- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
//	NSLog(@"windowTitleForDocumentDisplayName");
//	
//	if(folder == nil) 
//		return @"Porcupado | Asset Renamer";
//	else
//		return folder;
//}

//- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
//    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.
//    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
//    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
//
//    if ( outError != NULL ) 
//		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
//
//	return nil;
//}

//- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
//    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.
//    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
//    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
//    
//    if ( outError != NULL ) 
//		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
//
//    return YES;
//}


#pragma mark -
#pragma mark File Navigation Support
// returns the CFBrowserItem if one exists with same filenname and extension as the one passed (otherwise nil)
- (CFBrowserItem *) searchFolderContents:(NSString *)fileName extension:(NSString *)fileExtension {
	NSString *		searchFile = [NSString stringWithFormat:@"%@.%@", fileName,fileExtension];
	NSEnumerator *enumerator = [folderContents objectEnumerator];
	CFBrowserItem *	item; 

	while ((item = [enumerator nextObject]))
		if(![[[item path] lastPathComponent] caseInsensitiveCompare:searchFile])
			return item;

	return nil;
}

- (void)navigateToPath:(NSString *)path resetSelection:(BOOL)resetSelection {
	BOOL			isDirectory = NO;
	BOOL			bXDCam = NO;
	int				i;
	CFBrowserItem *	matchItem; 
	NSDictionary *	extensionPairDict = [NSDictionary dictionaryWithObjects:
		[NSArray arrayWithObjects:@"JPG", @"MOV", @"MOV", nil] 
		forKeys:[NSArray arrayWithObjects:@"CR2", @"THM", @"XML", nil]];
	NSEnumerator *	enumerator;
	NSString *		keyExtString;
	
	// check that the path points to a folder
	[[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
	
	if(!isDirectory || ![[path pathExtension] isEqualToString:@""]) {
		[[NSWorkspace sharedWorkspace] openFile:path];
		return;
	}
	else {
		[contentsPath release];
		contentsPath = [path copy];
	}

	// clear the *.* folder contents
	[folderContents removeAllObjects];
	// get a list of files in the folder
	NSArray *fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:contentsPath error:nil];
	
	for (NSString *fileName in fileList) {
		// check if the file is a system file
		if([fileName hasPrefix:@"."])
			continue;

		// create a new CFBrowserItem for the file location
		CFBrowserItem *item = [[CFBrowserItem alloc] initWithPath:[contentsPath stringByAppendingPathComponent:fileName]];
		// add the object to the folder contents
		[folderContents addObject:item];
		// release the CFBrowserItem so that it is not double retained (it was added to the array folderContents)
		[item release];
	}
	
	// review the full list of files for hidden file pairs (as specified in the extensionPairDict dictionary)
	for(i = 0; i < [folderContents count]; i++) {
		matchItem = nil;
		enumerator = [extensionPairDict keyEnumerator];

		// iterate through  extensionPairDict dictionary and check for matches of each file extension
		while ((keyExtString = [enumerator nextObject])) {
			if(![[[[folderContents objectAtIndex:i] path] pathExtension] caseInsensitiveCompare:keyExtString]) {
				matchItem = [self searchFolderContents:[[[[folderContents objectAtIndex:i] path] lastPathComponent] stringByDeletingPathExtension] extension:[extensionPairDict objectForKey:keyExtString]];
				
				if(matchItem != nil) {
					// hide this element
					[[folderContents objectAtIndex:i] setIsHidden:YES];
					// matching object has CR2 extension
					[matchItem setPairExtension:keyExtString];
					
					// if match extension is "MOV" and file extension is "XML", then there are XDCam matches that require DMG folder pair
					if((![[extensionPairDict objectForKey:keyExtString] caseInsensitiveCompare:@"MOV"]) && 
						(![keyExtString caseInsensitiveCompare:@"XML"]))
						bXDCam = YES;
				}
			}
		}
	}

	// set to MOV filter if xdcam file pairs are in folderContents
	if (bXDCam)
		[typePopUp selectItemAtIndex:2];

	// filter folderContents and show in coverflow
	[self updateCoverFlowContents:self];
	
	if(resetSelection) 
		[coverFlow setSelectedIndex:0];
		
	if ((bXDCam) && (xdcamFolder == nil))
		[NSApp beginSheet: xdcamFolderWindow
		   modalForWindow: mainWindow
			modalDelegate: self
		   didEndSelector: nil
			  contextInfo: NULL];
	else if(bXDCam)
		[self getXDCamModifiedDates];
}

#pragma mark -
#pragma mark Cover Flow

- (NSUInteger)numberOfItemsInImageFlow:(IKImageFlowView *)sender {
	return [[self listForGroupsPopup] count];
}

- (id)imageFlow:(IKImageFlowView *)sender itemAtIndex:(NSInteger)index {
	return [[self listForGroupsPopup] objectAtIndex:index];
}

- (void)imageFlow:(IKImageFlowView *)sender cellWasDoubleClickedAtIndex:(NSInteger)index {
	[self navigateToPath:[[[self listForGroup:0] objectAtIndex:index] path] resetSelection:YES];
}

//- (NSUInteger)imageFlow:(IKImageFlowView *)browser writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard {
//	return [self _writeFilenamesAtIndexes:indexes toPasteboard:pasteboard];
//}

//- (void)imageFlow:(IKImageFlowView *)sender didSelectItemAtIndex:(NSInteger)index {
//	_canIgnoreChangeNotification = YES;
//}

#pragma mark -
#pragma mark IBActions

//- (IBAction)reload:(id)sender {
//	[self navigateToPath:contentsPath resetSelection:NO];
//}

- (IBAction)reloadCoverFlow:(id)sender {
	if(([groupPopUp indexOfSelectedItem] == 1) || ([groupPopUp indexOfSelectedItem] == 2)) {
		[nameText setStringValue:@""];
		[prefixText setStringValue:@""];
		[nameText setEnabled:NO];
		[prefixText setEnabled:NO];
	}
	else { 
		[nameText setEnabled:YES];
		[prefixText setEnabled:YES];
	}
	
	if([[self listForGroupsPopup] count])
		[fileCount setStringValue:[NSString stringWithFormat:@"%ld asset%@",[[self listForGroupsPopup] count],([[self listForGroupsPopup] count] != 1)? @"s":@""]];
	else
		[fileCount setStringValue:@""];
	
	[coverFlow reloadData];
}

- (IBAction)updateCoverFlowContents:(id)sender {
	NSEnumerator *	enumerator = [folderContents objectEnumerator];
	CFBrowserItem *	item; 
	NSString *		filterExtension = nil;
	
	// clear the ungrouped list
	[[self listForGroup:0] removeAllObjects];
	
	// PERFORM FILTERING HERE!!!!
	switch ([typePopUp indexOfSelectedItem]) {
			//	0: "Everything" 
		case 0:
			break;
			//	1: "JPG: Images" 
		case 1:
			filterExtension = @"JPG";
			break;
			//	2: "MOV: Movies" 
		case 2:
			filterExtension = @"MOV";
			break;
			//	3: "MP3: Audio Files" 
		case 3:
			filterExtension = @"MP3";
			break;
			//	4: "WAV: Audio Files" 
		case 4:
			filterExtension = @"WAV";
			break;
	}
	
	while ((item = [enumerator nextObject]))
		if(![item isHidden]) {
			if(filterExtension == nil)
				[[self listForGroup:0] addObject:item];
			else if(![[[item path] pathExtension] caseInsensitiveCompare:filterExtension])
				[[self listForGroup:0] addObject:item];
		}
	
	[self reloadCoverFlow:nil];
	[coverFlow setSelectedIndex:0];
}

- (IBAction)deleteActiveCFAsset:(id)sender {
	if([groupPopUp indexOfSelectedItem] != 1) {
		// show previous item if last item is being hidden
		if(([coverFlow focusedIndex] == [[self listForGroupsPopup] count]-1) && [coverFlow focusedIndex])
			[coverFlow setSelectedIndex:([coverFlow focusedIndex]-1)];
		
		[[[groups objectAtIndex:1] objectForKey:GroupList] addObject:[[self listForGroupsPopup] objectAtIndex:[coverFlow focusedIndex]]];
		[[self listForGroupsPopup] removeObjectAtIndex:[coverFlow focusedIndex]];
		[self reloadCoverFlow:nil];
		
		if(![groupPopUp indexOfSelectedItem])
			[self checkForCompletionAndProcess:sender];
		
		[typePopUp setEnabled:NO];
		[Controller setLastFilter:[typePopUp indexOfSelectedItem]];
	}
}

- (IBAction)skipActiveCFAsset:(id)sender {
	if([groupPopUp indexOfSelectedItem] != 2) {
		// show previous item if last item is being hidden
		if(([coverFlow focusedIndex] == [[self listForGroupsPopup] count]-1) && [coverFlow focusedIndex])
			[coverFlow setSelectedIndex:([coverFlow focusedIndex]-1)];
		
		[[[groups objectAtIndex:2] objectForKey:GroupList] addObject:[[self listForGroupsPopup] objectAtIndex:[coverFlow focusedIndex]]];
		[[self listForGroupsPopup] removeObjectAtIndex:[coverFlow focusedIndex]];
		[self reloadCoverFlow:nil];
		
		if(![groupPopUp indexOfSelectedItem])
			[self checkForCompletionAndProcess:sender];
		
		[typePopUp setEnabled:NO];
		[Controller setLastFilter:[typePopUp indexOfSelectedItem]];
	}
}

- (IBAction)ungroupActiveCFAsset:(id)sender {
	if([groupPopUp indexOfSelectedItem]) {
		// show previous item if last item is being hidden
		if(([coverFlow focusedIndex] == [[self listForGroupsPopup] count]-1) && [coverFlow focusedIndex])
			[coverFlow setSelectedIndex:([coverFlow focusedIndex]-1)];
		
		[[[groups objectAtIndex:0] objectForKey:GroupList] addObject:[[self listForGroupsPopup] objectAtIndex:[coverFlow focusedIndex]]];
		[[self listForGroupsPopup] removeObjectAtIndex:[coverFlow focusedIndex]];
		[self reloadCoverFlow:nil];
	}
}

- (IBAction)checkForCompletionAndProcess:(id)sender {
	int		iAssetCounts[3], i;
	
	if(![[self listForGroup:0] count]) {
		// get asset counts
		iAssetCounts[0] = [groups count] - 3;
		iAssetCounts[1] = [[[groups objectAtIndex:2] objectForKey:GroupList] count];
		iAssetCounts[2] = [[[groups objectAtIndex:1] objectForKey:GroupList] count];
		
		NSAlert			*alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"Ok"];
		[alert addButtonWithTitle:@"Cancel"];
		[alert setMessageText:@"Review Changes..."];
		[alert setInformativeText:
		 [NSString stringWithFormat:@"%d\tGroup%@ to rename\n%d\tAsset%@ to skip\n%d\tAsset%@ to delete",
		  iAssetCounts[0], (iAssetCounts[0]!=1)? @"s":@"",
		  iAssetCounts[1], (iAssetCounts[1]!=1)? @"s":@"",
		  iAssetCounts[2], (iAssetCounts[2]!=1)? @"s":@""]];
		[alert setAlertStyle:NSWarningAlertStyle];
		
		int result = [alert runModal];
		[alert release];
		
		if (result != NSAlertFirstButtonReturn) {
			if([groups count]>3) {
				[groupPopUp selectItemAtIndex:4];
				[self reloadCoverFlow:self];
			}
			
			return;
		}
		
		// remove the ungroupped group
		[groups removeObjectAtIndex:0];
		[groupPopUp removeItemAtIndex:0];
		
		// delete objects in groups index
		NSEnumerator *	enumerator = [[[groups objectAtIndex:0] objectForKey:GroupList] objectEnumerator];
		CFBrowserItem *	item; 
		
		while ((item = [enumerator nextObject])) {
			// move to the trash
			[[NSFileManager defaultManager] removeItemAtPath:[item path] error:nil];
			
			if([item pairExtension] != nil) 
				[[NSFileManager defaultManager] removeItemAtPath:
				 [NSString stringWithFormat:@"%@.%@",[[item path] stringByDeletingPathExtension],[item pairExtension]] error:nil];
		}
		
		// remove the delete group
		[groups removeObjectAtIndex:0];
		// remove the skip group (was 1, is 0 after delete group remove)
		[groups removeObjectAtIndex:0];
		
		NSEnumerator *			groupEnumerator = [groups objectEnumerator];
		NSMutableDictionary *	activeGroup;
		NSError *				error = NULL;
		NSMutableString *		newPath;
		
		while ((activeGroup = [groupEnumerator nextObject])) {
			i = 0;
			
			enumerator = [[activeGroup objectForKey:GroupList] objectEnumerator];
			
			while ((item = [enumerator nextObject])) {
                // see if the filename can be read as miniDV --> FCP import filename format
                NSDate *miniDVDate = [self getDateFromMiniDVFilename:[[item path] lastPathComponent]];

                // overwrite file system timestamp if filename is a miniDV filename
                if(miniDVDate)
                    // set file modified date from filename date (i.e. translate ingest/capture date to record date in filename
                    [[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:miniDVDate forKey:NSFileModificationDate] ofItemAtPath:[item path] error:&error];
				// set the item.modifiedDate if the existing modified date doesn't match (helpful for xdcam assets)
				else if([[[[NSFileManager defaultManager] attributesOfItemAtPath:[item path] error:&error] fileModificationDate] compare:[item modifiedDate]]) {
					//					if(error != NULL) {
					//						NSLog(@"attributesOfItemAtPath: %@",[error description]);
					//						error = NULL;
					//					}
					
					//NSLog(@"%@ = %@ (%@)",[[item modifiedDate] description],[[[NSFileManager defaultManager] attributesOfItemAtPath:newPath error:&error] fileModificationDate], [error description]);
					//NSLog(@"%d: %@",[[NSFileManager defaultManager] changeFileAttributes:[NSDictionary dictionaryWithObject:[item modifiedDate] forKey:NSFileModificationDate] atPath:[item path]], [item path]);
					[[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:[item modifiedDate] forKey:NSFileModificationDate] ofItemAtPath:[item path] error:&error];
					
					// FAILS here with setAttributes
					//					if(error != NULL) {
					//						NSLog(@"path: %@",[item path]);
					//						NSLog(@"setAttributes: %@",[error description]);
					//						error = NULL;
					//					}
				}
				
				// create first part of filename
				newPath = [NSMutableString stringWithFormat:@"%@/%@%@%@",
						   [[item path] stringByDeletingLastPathComponent],
                           [(miniDVDate)? miniDVDate:[item modifiedDate] descriptionWithCalendarFormat:[Controller timestampFormat] timeZone:nil
																	   locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]],
						   [activeGroup objectForKey:GroupPrefix],
						   [activeGroup objectForKey:GroupName]];
				
				// add an indexed number (i) to the filename if the group has more than one entry
				if([[activeGroup objectForKey:GroupList] count] - 1) 
					[newPath appendFormat:[NSString stringWithFormat:@"_%%0%dd",((int)log10([[activeGroup objectForKey:GroupList] count]))+1], ++i];
				
				// add the extension to the filename
				[newPath appendFormat:@".%@", [[item path] pathExtension]];
				
				// rename the file
				[[NSFileManager defaultManager] moveItemAtPath:[item path] toPath:newPath error:nil];
				//NSLog(@"exists? %d: %@",[[NSFileManager defaultManager] fileExistsAtPath:newPath], newPath);
				
				if([item pairExtension] != nil) {
					newPath = [NSMutableString stringWithFormat:@"%@.%@",[newPath stringByDeletingPathExtension],[item pairExtension]];
					
					[[NSFileManager defaultManager] moveItemAtPath:
					 [NSString stringWithFormat:@"%@.%@",[[item path] stringByDeletingPathExtension],[item pairExtension]] toPath:newPath error:nil];
					
					// set the item.modifiedDate if the existing modified date doesn't match (helpful for xdcam assets)
					if([[[[NSFileManager defaultManager] attributesOfItemAtPath:newPath error:&error] fileModificationDate] compare:[item modifiedDate]]) 
						[[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:[item modifiedDate] forKey:NSFileModificationDate] ofItemAtPath:newPath error:&error];
					
				}
			}
		}
		
		[mainWindow close];
	}
}

- (IBAction)closeNameSheetPress:(id)sender {
    [NSApp endSheet:groupNameWindow];
	[groupNameWindow close];
}

- (IBAction)closeXDCamFolderSheetPress:(id)sender {
    [NSApp endSheet:xdcamFolderWindow];
	[xdcamFolderWindow close];
}

- (IBAction)addGroupPress:(id)sender {
	NSInteger	returnCode = NSModalResponseOK;
	
	if(!([[nameText stringValue] length]) && !([[prefixText stringValue] length])) 
		returnCode = NSRunAlertPanel(@"Prefix and name fields are both blank.", @"", @"Proceed", @"Cancel", nil);
	
	if(returnCode != NSModalResponseCancel) {
		// rename operation if groupPopUp not pointing to "Ungrouped"
		if([groupPopUp indexOfSelectedItem]) {
			NSString	*nameNoSpace, *prefixNoSpace;
			int			iThisIndex = [groupPopUp indexOfSelectedItem];
			
			nameNoSpace = [Controller stringByRemovingWhitespace:[nameText stringValue]];
			prefixNoSpace = [Controller stringByRemovingWhitespace:[prefixText stringValue]];
			
			// update name and prefix in dictionary 
			[[groups objectAtIndex:iThisIndex-1] setObject:nameNoSpace forKey:GroupName];
			[[groups objectAtIndex:iThisIndex-1] setObject:prefixNoSpace forKey:GroupPrefix];
			
			[groupPopUp removeItemAtIndex:iThisIndex];
			[groupPopUp insertItemWithTitle:[NSString stringWithFormat:@"%@%@",prefixNoSpace, nameNoSpace] atIndex:iThisIndex];
			[groupPopUp selectItemAtIndex:iThisIndex];
			
			[self closeNameSheetPress:sender];
		}
		// otherwise, it is a create group operation...
		else {
			[self createGroup:[prefixText stringValue] name:[nameText stringValue]];
			[self closeNameSheetPress:sender];
			[self checkForCompletionAndProcess:sender];
		}
	}
}

- (IBAction)getGroupNamePress:(id)sender {
	[groupAssetCount setStringValue:[NSString stringWithFormat:@"%ld asset%@",[coverFlow focusedIndex]+1, ([coverFlow focusedIndex])? @"s":@""]];
	
	[NSApp beginSheet: groupNameWindow
	   modalForWindow: mainWindow
		modalDelegate: self
	   didEndSelector: nil
		  contextInfo: NULL];
}

- (IBAction)jumpToFirst:(id)sender {
	[coverFlow setSelectedIndex:0];
	[self reloadCoverFlow:sender];
}

- (IBAction)jumpToLast:(id)sender {
	[coverFlow setSelectedIndex:[[self listForGroupsPopup] count]-1];
	[self reloadCoverFlow:sender];
}

- (IBAction)renameGroupPress:(id)sender {
	[nameText setStringValue:[[groups objectAtIndex:([groupPopUp indexOfSelectedItem]-1)] objectForKey:GroupName]];
	[prefixText setStringValue:[[groups objectAtIndex:([groupPopUp indexOfSelectedItem]-1)] objectForKey:GroupPrefix]];
	
	[self getGroupNamePress:sender];
}

- (IBAction)quickLookView:(id)sender {
	if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) 
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    else
        [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
}

- (IBAction)changeView:(id)sender {
	if(![[sender title] compare:@"Ungrouped"])
		[groupPopUp selectItemAtIndex:0];
	else if(![[sender title] compare:@"Deleted"])
		[groupPopUp selectItemAtIndex:1];
	else if(![[sender title] compare:@"Skipped"])
		[groupPopUp selectItemAtIndex:2];
	else if((![[sender title] compare:@"Next"]) && ([groupPopUp indexOfSelectedItem] < [[groupPopUp itemArray] count]-1))
		[groupPopUp selectItemAtIndex:([groupPopUp indexOfSelectedItem]+(([groupPopUp indexOfSelectedItem]==2)? 2:1))];
	else if((![[sender title] compare:@"Previous"]) && ([groupPopUp indexOfSelectedItem]))
		[groupPopUp selectItemAtIndex:([groupPopUp indexOfSelectedItem]-(([groupPopUp indexOfSelectedItem]==4)? 2:1))];
	
	[coverFlow setSelectedIndex:0];
	[self reloadCoverFlow:sender];
}

#pragma mark -
#pragma mark FileDragView Delegate

- (BOOL)folderDragNotification:(NSView *)sender draggingInfo:(id <NSDraggingInfo>)info {
	BOOL			isDir;
	
	if(sender == folderDrop) {
		// don't allow multiple folder drops
		if(folder != nil) 
			return NO;
		
		folder = [NSString stringWithFormat:@"%@/",[folderDrop getPath]];
		[mainWindow setTitle:folder];
		[self navigateToPath:[NSString stringWithFormat:@"%@/", [folderDrop getPath]] resetSelection:YES];
	}
	else {
		if(!([[NSFileManager defaultManager] fileExistsAtPath:
			[NSString stringWithFormat:@"%@/%@",[xdcamFolderDrop getPath], SxSMediaPath] isDirectory:&isDir]) || !isDir)
				return NO;

		xdcamFolder = [[NSString alloc] initWithString:[xdcamFolderDrop getPath]];
		[self getXDCamModifiedDates];
	    [self closeXDCamFolderSheetPress:sender];
		[self reloadCoverFlow:nil];
	}
	
	return YES;
}

#pragma mark -
#pragma mark Menu Validation

-(BOOL)validateMenuItem:(NSMenuItem *)theMenuItem {
	// handle general case
    BOOL enable = [self respondsToSelector:[theMenuItem action]]; 

	// trap special cases
    if ([theMenuItem action] == @selector(quickLookView:))
        enable = [self numberOfItemsInImageFlow:coverFlow] > 0;
    else if ([theMenuItem action] == @selector(getGroupNamePress:))
        enable = ([self numberOfItemsInImageFlow:coverFlow] > 0) && (![groupPopUp indexOfSelectedItem]);
    else if ([theMenuItem action] == @selector(deleteActiveCFAsset:))
        enable = ([self numberOfItemsInImageFlow:coverFlow] > 0) && ([groupPopUp indexOfSelectedItem]!=1);
    else if ([theMenuItem action] == @selector(skipActiveCFAsset:))
        enable = ([self numberOfItemsInImageFlow:coverFlow] > 0) && ([groupPopUp indexOfSelectedItem]!=2);
    else if ([theMenuItem action] == @selector(changeView:)) {
		if(![[theMenuItem title] compare:@"Ungrouped"])
			enable = [groupPopUp indexOfSelectedItem];
		else if(![[theMenuItem title] compare:@"Deleted"])
			enable = [groupPopUp indexOfSelectedItem] != 1;
		else if(![[theMenuItem title] compare:@"Skipped"])
			enable = [groupPopUp indexOfSelectedItem] != 2;
		else if(![[theMenuItem title] compare:@"Next"])
			enable = [groupPopUp indexOfSelectedItem] < [[groupPopUp itemArray] count]-1;
		else if(![[theMenuItem title] compare:@"Previous"])
			enable = [groupPopUp indexOfSelectedItem] > 0;
	}
	else if ([theMenuItem action] == @selector(ungroupActiveCFAsset:))
        enable = ([self numberOfItemsInImageFlow:coverFlow] > 0) && ([groupPopUp indexOfSelectedItem]);
	else if ([theMenuItem action] == @selector(checkForCompletionAndProcess:))
		enable = ((![[self listForGroup:0] count]) && (![typePopUp isEnabled]));
	else if ([theMenuItem action] == @selector(renameGroupPress:))
        enable = [groupPopUp indexOfSelectedItem] > 3;
	
    return enable;
}


#pragma mark - Quick Look panel support

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel {
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
    // This document is now responsible of the preview panel
    // It is allowed to set the delegate, data source and refresh panel.
    previewPanel = [panel retain];
    panel.delegate = self;
    panel.dataSource = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
    // This document loses its responsisibility on the preview panel
    // Until the next call to -beginPreviewPanelControl: it must not
    // change the panel's delegate, data source or refresh it.
    [previewPanel release];
    previewPanel = nil;
}

#pragma mark -  Quick Look panel data source

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    return 1;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index {
    return [NSURL fileURLWithPath:[[[self listForGroupsPopup] objectAtIndex:[coverFlow focusedIndex]] path]];
}

#pragma mark - Quick Look panel delegate

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event {
//    // redirect all key down events to the table view
//    if ([event type] == NSKeyDown) {
//        [downloadsTableView keyDown:event];
//        return YES;
//    }

    return NO;
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item {
	NSRect selectionFrame = [coverFlow selectedImageFrame];
    
    selectionFrame = [coverFlow convertRectToBase:selectionFrame];
    selectionFrame.origin = [[coverFlow window] convertBaseToScreen:selectionFrame.origin];
    return selectionFrame;
}

// This delegate method provides a transition image between the table view and the preview panel
- (id)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect {
    return [[NSImage alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[[self listForGroupsPopup] objectAtIndex:[coverFlow focusedIndex]] path]]];
}

@end
