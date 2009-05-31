//
//  TBControlDoc.h
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 14/08/08.
//  Copyright 2008 BrainBender Software. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


#import <Foundation/Foundation.h>
#import "TalkingBookTypes.h"
#import "TBSharedBookData.h"

@interface TBControlDoc : NSObject
{
	NSXMLDocument		*xmlControlDoc;
	NSString			*parentFolderPath;
	NSURL				*fileURL;
	
	TBSharedBookData	*bookData;
	
	NSXMLNode			*metadataNode;
	NSXMLNode			*currentNavPoint;
	
	NSString			*currentPositionID;
	
	BOOL				navigateForChapters;
	BOOL				_hasTextContent;
	BOOL				_hasAudioContent;
	BOOL				stayOnCurrentLevel;
	
		
}

- (BOOL)openWithContentsOfURL:(NSURL *)aURL;
- (void)processData;
- (NSXMLNode *)metadataNode;
- (void)jumpToNodeWithId:(NSString *)fullPathToNode;
- (void)updateDataForCurrentPosition;

- (void)moveToNextSegment;
- (void)moveToPreviousSegment;
- (NSString *)audioFilenameFromCurrentNode;
- (NSString *)filenameFromID:(NSString *)anIdString;

- (void)goUpALevel;
- (void)goDownALevel;

- (BOOL)canGoNext;
- (BOOL)canGoPrev;
- (BOOL)canGoUpLevel;
- (BOOL)canGoDownLevel;
- (BOOL)nextSegmentIsAvailable;
- (BOOL)PreviousSegmentIsAvailable;

- (NSString *)stringForXquery:(NSString *)aQuery ofNode:(NSXMLNode *)theNode;



@property (readwrite, retain) TBSharedBookData *bookData;

@property (readonly)		NSXMLNode			*metadataNode;
@property (readwrite, copy)	NSXMLNode			*currentNavPoint;
@property (readonly, copy)	NSURL				*fileURL;

@property (readwrite, copy) NSString *currentPositionID;

@property (readwrite) BOOL navigateForChapters;
@property (readwrite) BOOL stayOnCurrentLevel;

@end
