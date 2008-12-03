//
//  BBSTBControlDoc.h
//  BBSTalkingBook
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
#import "BBSTalkingBookTypes.h"

@interface BBSTBControlDoc : NSObject 
{
	NSXMLDocument		*xmlControlDoc;
	NSString			*parentFolderPath;
	
	NSXMLNode			*metadataNode;
	
	TalkingBookMediaFormat			bookMediaFormat;
	NSInteger			currentLevel;
	NSInteger			currentPageNumber;
	
	NSInteger			totalPages;			// dtb:maxPageNumber or dtb:maxPageNormal in pre 2005 spec
	NSInteger			totalTargetPages;	// dtb:totalPageCount
	NSString			*documentUID;		// dtb:uid
	NSString			*segmentTitle;
	NSString			*bookTitle;
	float				levelNavChapterIncrement;
	
	id					controlDocument;
	NSString			*currentAudioFilename;
	NSString			*currentPositionID;
	
	BOOL				navigateForChapters;
	BOOL				_hasTextContent;
	BOOL				_hasAudioContent;
	
}

- (BOOL)openWithContentsOfURL:(NSURL *)aURL;
- (BOOL)processMetadata;
- (NSXMLNode *)metadataNode;

- (void)moveToNextSegment;
- (void)moveToPreviousSegment;
- (void)goUpALevel;
- (void)goDownALevel;

- (BOOL)canGoNext;
- (BOOL)canGoPrev;
- (BOOL)canGoUpLevel;
- (BOOL)canGoDownLevel;
- (BOOL)nextSegmentIsAvailable;
- (BOOL)PreviousSegmentIsAvailable;

- (NSString *)stringForXquery:(NSString *)aQuery ofNode:(NSXMLNode *)theNode;

@property (readonly) TalkingBookMediaFormat bookMediaFormat;
@property (readonly) NSXMLNode *metadataNode;
@property (readonly, retain) NSString	*bookTitle;
@property (readonly) NSInteger currentLevel;
@property (readonly) NSInteger currentPageNumber;
@property (readonly) NSInteger totalPages;
@property (readonly) NSInteger totalTargetPages;
@property (readwrite) float levelNavChapterIncrement;
@property (readonly, retain) NSString *documentUID;
@property (readonly, retain) NSString *segmentTitle;
@property (readonly, retain) NSString *currentAudioFilename;
@property (readwrite,retain) NSString *currentPositionID;
@property (readwrite) BOOL navigateForChapters;

@end
