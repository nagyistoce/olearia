//
//  TBNavigationController.h
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 11/06/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TBPackageDoc, TBControlDoc, TBSMILDocument, TBAudioSegment, TBSharedBookData;


@interface TBNavigationController : NSObject 
{
	TBSharedBookData	*_bookData;
	
	TBPackageDoc		*packageDocument;
	TBControlDoc		*controlDocument;
	
	TBSMILDocument		*_smilDoc;
	TBAudioSegment		*_audioFile;
	NSString			*_currentSmilFilename;
	NSString			*_currentAudioFilename;
	NSString			*_currentTag;
	
}

// methods used for setting and getting the current position in the document
- (void)moveToNodeWihPath:(NSString *)aNodePath;
- (NSString *)currentNodePath;

- (void)prepareForPlayback;

@property (readwrite, retain)	TBPackageDoc		*packageDocument;
@property (readwrite, retain)	TBControlDoc		*controlDocument;


@end
