//
//  TBTextContentDoc.h
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 13/07/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
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

#import "TBBookData.h"


@interface TBTextContentDoc : NSObject 
{
	TBBookData		*bookData;
	NSXMLDocument	*_xmlTextDoc;
	NSXMLElement	*_xmlRoot;
	NSXMLNode		*_currentNode;
	
	
}


// setup
- (BOOL)openWithContentsOfURL:(NSURL *)aURL;
- (void)processData;


@end

@interface TBTextContentDoc (Synchronization)

- (void)jumpToNodeWithPath:(NSString *)fullPathToNode;
- (void)jumpToNodeWithIdTag:(NSString *)anIdTag;
- (void)updateDataForCurrentPosition;
- (NSString *)currentIdTag;


@end


@interface TBTextContentDoc (Information)

- (BOOL)canGoNext;
- (BOOL)canGoPrev;
- (BOOL)canGoUpLevel;
- (BOOL)canGoDownLevel;
- (NSString *)contentText;

@end

@interface TBTextContentDoc (Navigation)

- (void)moveToNextSegment;
- (void)moveToNextSegmentAtSameLevel;
- (void)moveToPreviousSegment;
- (void)goUpALevel;
- (void)goDownALevel;

@end

