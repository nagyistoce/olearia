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

@interface TBControlDoc : NSObject
{
	NSXMLDocument		*xmlControlDoc;
	NSURL				*fileURL;
	
	TBBookData			*bookData;
	
	NSXMLNode			*currentNavPoint;
	
	NSString			*currentPositionID;
	
	BOOL				navigateForChapters;
	BOOL				_hasTextContent;
	BOOL				_hasAudioContent;
	
}

// setup
- (BOOL)openWithContentsOfURL:(NSURL *)aURL;
- (void)processData;
- (NSString *)mediaFormatString;

// syncronization
- (void)jumpToNodeWithPath:(NSString *)fullPathToNode;
- (void)jumpToNodeWithIdTag:(NSString *)anIdTag;
- (void)updateDataForCurrentPosition;
- (NSString *)currentIdTag;
- (NSString *)contentFilenameFromCurrentNode;
- (NSString *)filenameFromID:(NSString *)anIdString;

// navigation
- (BOOL)moveToNextSegment;
- (void)moveToNextSegmentAtSameLevel;
- (void)moveToPreviousSegment;
- (void)goUpALevel;
- (void)goDownALevel;

// information
- (NSXMLNode *)metadataNode;
- (BOOL)canGoNext;
- (BOOL)canGoPrev;
- (BOOL)canGoUpLevel;
- (BOOL)canGoDownLevel;
- (BOOL)nextSegmentIsAvailable;
- (BOOL)PreviousSegmentIsAvailable;

- (NSString *)stringForXquery:(NSString *)aQuery ofNode:(NSXMLNode *)theNode;

@property (readwrite, assign)	NSXMLNode		*currentNavPoint;
@property (readonly, copy)		NSURL			*fileURL;
@property (readwrite, copy)		NSString		*currentPositionID;
@property (readwrite)			BOOL			navigateForChapters;


@end
