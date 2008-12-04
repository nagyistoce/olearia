//
//  BBSTBSMILDocument.h
//  TalkingBook Framework
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

@interface BBSTBSMILDocument : NSObject 
{
	
	//NSDictionary	*smilContent;
	//NSArray			*smilContent;
	NSString		*xmlContentFilename;
	NSDictionary	*smilChapterData;
	//NSString		*filename;
	NSArray			*parNodes;
	NSDictionary	*parNodeIndexes;
}

- (BOOL)openWithContentsOfURL:(NSURL *)aURL;
//- (NSArray *)chapterMarkers;
- (NSArray *)chapterMarkersFromId:(NSString *)startId toId:(NSString *)endId;
- (NSString *)audioFilenameForId:(NSString *)anId;


//@property (readonly, retain) NSDictionary *chapters;
@property (readonly, retain) NSString *xmlContentFilename;
//@property (readonly, retain) NSString *filename;

@end
