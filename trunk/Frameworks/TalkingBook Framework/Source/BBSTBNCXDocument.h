//
//  BBSTBNCXDocument.h
//  BBSTalkingBook
//
//  Created by Kieren Eaton on 15/04/08.
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

@interface BBSTBNCXDocument : BBSTBControlDoc 
{

	BBSTBSMILDocument	*smilDoc;
	
	NSDictionary		*metaData;
	NSDictionary		*smilCustomTest;
	NSDictionary		*documentTitleDict;
	NSDictionary		*documentAuthorDict;
	NSDictionary		*segmentAttributes;
	
	BOOL				shouldUseNavmap;
	BOOL				isFirstRun;
	BOOL				loadFromCurrentLevel;
	
	//BOOL				isAtPhraseLevel;
	
	NSXMLDocument		*ncxDoc;
	
	NSXMLElement		*ncxRootElement;
	NSXMLNode			*currentNavPoint;
	NSXMLNode			*navListNode;
	NSArray				*navTargets;
	
	NSInteger			maxNavPointsAtThisLevel;

	NSString			*versionString;
	NSString			*parentFolderPath;
	
}

- (BOOL)openControlFileWithURL:(NSURL *)aURL;

- (NSArray *)chaptersForSegment;
- (NSArray *)chaptersForSegmentWithTimescale:(long)aTimeScale;

@property (readwrite, assign) BOOL loadFromCurrentLevel;
@property (readonly, retain) NSDictionary *metaData;
@property (readonly, retain) NSDictionary *documentTitleDict;

@property (readonly, retain) NSDictionary *documentAuthorDict;

@property (readonly, retain) NSDictionary *smilCustomTest;
@property (readonly, retain) NSDictionary *segmentAttributes;

@end
