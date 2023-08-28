// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// The software is provided "as is", without warranty of any kind, express or
// implied, including but not limited to the warranties of merchantability,
// fitness for a particular purpose and non-infringement. In no event shall the
// authors or copyright holders be liable for any claim, damages or other
// liability, whether in an action of contract, tort or otherwise, arising from,
// out of or in connection with the software or the use or other dealings in
// the software.
// 

#define USEEXIF

#import "CFBrowserItem.h"
#import "NSImage+QuickLook.h"
#import <Quartz/Quartz.h>

NSSize const iconSize = (NSSize){512, 512};

@implementation CFBrowserItem

- (void)dealloc {
	if(pairExtension != nil)
		[pairExtension release];

	[modifiedDate release];
	[_imageID release];
	[_path release];
	[_cachedImage release];
	[super dealloc];
}

-(NSString *) description {
	return [NSString stringWithFormat: @"%@, %@", 
		[self path],
		[[self modifiedDate] descriptionWithCalendarFormat:@"%m/%d/%Y %I:%M:%S %p" timeZone:nil
		locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]] ];
}

- (id)initWithPath:(NSString *)path {
	NSDictionary *		exifData = nil;
	BOOL				bUseFileSystemDate = YES;
	
	if([super init]) {
		_imageID = [[NSString stringWithFormat:@"-%d", rand()] retain];
		_path = [path copy];
		
		bIsHidden = NO;
		pairExtension = nil;
		
#ifdef USEEXIF
		CGImageSourceRef cfImageSource = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path], NULL);
		
		if(cfImageSource) {
			exifData = (NSDictionary *)CGImageSourceCopyPropertiesAtIndex(cfImageSource, 0, NULL);
			
			if([exifData description])
				NSLog(@"%@",[exifData description]);
			
			CFRelease(cfImageSource);
		}
		
		// if the file has exif data, use that for the creation date
		// exif guidance here: http://www.mail-archive.com/cocoa-dev@lists.apple.com/msg30630.html
		// and here: http://caffeinatedcocoa.com/blog/?p=7
		if(exifData != nil) {
			NSString *exifDateString = [[exifData objectForKey:(NSString *)kCGImagePropertyExifDictionary] 
				objectForKey:(NSString*)kCGImagePropertyExifDateTimeOriginal];
			
			if(exifDateString != nil) {
				NSDateFormatter* exifFormat = [[NSDateFormatter alloc] init];
				[exifFormat setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
				modifiedDate = [[exifFormat dateFromString:exifDateString] copy];
				[exifFormat release];
				bUseFileSystemDate = NO;
			}
		}
		
		// if bUseFileSystemDate = YES, use the file system modified date
		if(bUseFileSystemDate) {
#endif
			NSError *err = 0; 
			NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&err]; 
			
			if(attrs)	
				modifiedDate = [[attrs fileModificationDate] copy]; 
#ifdef USEEXIF
		}
#endif
			
		return self;
	}
	
	return nil;
}

- (NSString *)path {
	return _path;
}

- (NSString *)pairExtension {
	return pairExtension;
}

- (void)setPairExtension:(NSString *)newExtension {
	if(pairExtension != nil)
		[pairExtension release];
	
	pairExtension = [[NSString alloc] initWithString:newExtension];
}

- (BOOL)isHidden {
	return bIsHidden;
}

- (void)setIsHidden:(BOOL)newStatus {
	bIsHidden = newStatus; 
}

- (NSDate *)modifiedDate {
	return modifiedDate;
}

- (NSString *)imageUID {
	return _imageID;
}

- (NSString *)imageRepresentationType {
	return IKImageBrowserNSImageRepresentationType;
}

- (id)imageRepresentation {
	if(!_cachedImage) {
		_cachedImage = [[NSImage imageWithPreviewOfFileAtPath:[self path] ofSize:iconSize asIcon:YES] retain];
	}
	return _cachedImage;
}

- (void)setModifiedDate:(NSDate *)date {
	[modifiedDate release];
	modifiedDate = [[NSDate alloc] initWithString:[date description]];
}

- (NSString *)imageTitle {
	
	if(![[_path pathExtension] length]) 
		return [NSString stringWithFormat:@"%@ (folder)",[[_path lastPathComponent] stringByDeletingPathExtension]];
	else if ([self pairExtension])
		return [NSString stringWithFormat:@"%@.%@/%@",
			[[_path lastPathComponent] stringByDeletingPathExtension],[[_path pathExtension] uppercaseString],[[self pairExtension] lowercaseString]];
	else
		return [NSString stringWithFormat:@"%@.%@",[[_path lastPathComponent] stringByDeletingPathExtension],[[_path pathExtension] uppercaseString]];
}

- (NSString *)imageSubtitle {
	return [NSString stringWithFormat:@"%@",
		[[self modifiedDate] descriptionWithCalendarFormat:@"%m/%d/%Y %I:%M:%S %p" timeZone:nil
		locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]]];
}

@end
