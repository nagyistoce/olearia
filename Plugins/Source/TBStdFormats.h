//
//  TBStdFormats.h
//  stdDaisyFormats
//
//  Created by Kieren Eaton on 13/04/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TBPluginInterface.h"
#import "TBSharedBookData.h"
@class TBFileUtils, TBPackageDoc, TBControlDoc;

@interface TBStdFormats : NSObject<TBPluginInterface> 
{
	TBSharedBookData	*bookData;
	TBFileUtils			*fileUtils;
	NSArray				*validFileExtensions;

	
	TBPackageDoc		*packageDocument;
	TBControlDoc		*controlDocument;
}

- (void)setupPluginSpecifics;
+ (id)bookType;

@property (readonly, copy)		NSArray* validFileExtensions;

@property (readwrite,retain)	TBSharedBookData	*bookData;
@property (readwrite, retain)	TBPackageDoc		*packageDocument;
@property (readwrite, retain)	TBControlDoc		*controlDocument;

@end
