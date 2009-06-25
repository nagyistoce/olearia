//
//  TBSMILDocument.h
//  StdDaisyFormats
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

#import <Cocoa/Cocoa.h>
#import <QTKit/QTTime.h>

@class TBAudioSegment, TBSharedBookData;

@interface TBSMILDocument : NSObject 
{
	
	NSXMLNode		*_currentNode;
	NSString		*currentNodePath;
	//NSMutableArray  *_idChapterMarkers;
	//NSMutableArray  *_skipableIdList;
	//NSString		*idToStartFrom;
	//NSString		*idToFinishWith;
	
	NSURL			*_currentFileURL;
	NSString		*relativeAudioFilePath;

	//NSDictionary	*smilChapterData;
	//NSArray			*_parNodes;
	//NSDictionary	*_parNodeIndexes;
	
	NSXMLDocument		*_xmlSmilDoc;
	//TBAudioSegment		*_currentAudioFile;
	//TBSharedBookData	*bookData;
	
	//BOOL			useSmilChapters;

}

- (BOOL)openWithContentsOfURL:(NSURL *)aURL;
- (NSArray *)audioChapterMarkersForFilename:(NSString *)aFile WithTimescale:(long)aScale;
- (void)setCurrentNodeWithPath:(NSString *)aNodePath;
- (BOOL)audioAfterCurrentPosition;

//- (NSString *)idFollowingId:(NSString *)anId;

//- (NSArray *)chapterMarkersFromId:(NSString *)startId toId:(NSString *)endId;
//- (NSString *)audioFilenameForId:(NSString *)anId;

//@property (readwrite, retain)	TBSharedBookData *bookData;
@property (readonly, copy)		NSString	*relativeAudioFilePath;
@property (readwrite,copy)		NSString	*currentNodePath;

@end
