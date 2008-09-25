//
//  BBSTBNCCDocument.h
//  Olearia
//
//  Created by Kieren Eaton on 11/09/08.
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
#import "BBSTBControlDoc.h"

@class BBSTBSMILDocument;

@interface BBSTBNCCDocument : BBSTBControlDoc
{

	NSDictionary		*metaData;
	NSDictionary		*segmentAttributes;
	
	
	NSInteger			currentNodeIndex;
	NSInteger			totalBodyNodes;
	
	NSXMLElement		*nccRootElement;
	NSXMLNode			*currentNavPoint;
	
	BBSTBSMILDocument   *smilDoc;
	NSArray				*bodyNodes;
	
	NSString *parentFolderPath;
	NSString *currentFilename;
	
	BOOL loadFromCurrentLevel;
	BOOL isFirstRun;
	
}
- (BOOL)openControlFileWithURL:(NSURL *)aURL;

- (NSString *)nextSegmentAudioFilePath;
- (NSString *)previousSegmentAudioFilePath;

- (BOOL)canGoNext;
- (BOOL)canGoPrev;
- (BOOL)canGoUpLevel;
- (BOOL)canGoDownLevel;

- (NSString *)goUpALevel;
- (NSString *)goDownALevel;

- (NSArray *)chaptersForSegment;
- (NSArray *)chaptersForSegmentWithTimescale:(long)aTimeScale;


@property (readwrite) BOOL loadFromCurrentLevel;
//@property (readonly, retain) NSDictionary *metaData;
//@property (readonly, retain) NSDictionary *documentTitleDict;

//@property (readonly, retain) NSDictionary *documentAuthorDict;

//@property (readonly, retain) NSDictionary *smilCustomTest;
@property (readonly, retain) NSDictionary *segmentAttributes;

@end
