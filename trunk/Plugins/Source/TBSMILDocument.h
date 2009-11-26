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

#import <QTKit/QTTime.h>

@class TBAudioSegment, TBBookData;

@interface TBSMILDocument : NSObject 
{
	
	NSString		*currentNodePath;

	NSXMLNode		*currentNode;
	NSURL			*currentFileURL;
	NSXMLDocument		*xmlSmilDoc;

}

- (BOOL)openWithContentsOfURL:(NSURL *)aURL;
- (NSArray *)audioChapterMarkersForFilename:(NSString *)aFile WithTimescale:(long)aScale;
- (void)setCurrentNodeWithPath:(NSString *)aNodePath;
- (void)jumpToNodeWithIdTag:(NSString *)aTag;
- (NSString *)currentIdTag;
- (BOOL)audioAfterCurrentPosition;
- (NSString *)relativeAudioFilePath;
- (NSString *)relativeTextFilePath;
- (void)nextTextPlaybackPoint;
- (void)previousTextPlaybackPoint;
- (void)updateAfterPositionChange;

@property (readwrite,copy)		NSString	*currentNodePath;
@property (readwrite, assign)	NSXMLNode	*currentNode;

@end
