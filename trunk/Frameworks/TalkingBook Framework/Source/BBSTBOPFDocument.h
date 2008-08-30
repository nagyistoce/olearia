//
//  BBSTBOPFDocument.h
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

#import <Cocoa/Cocoa.h>
#import "BBSTalkingBookTypes.h"
#import "BBSTBPackageDoc.h"

@interface BBSTBOPFDocument : BBSTBPackageDoc 
{
	NSDictionary	*manifest;
	NSDictionary	*guide;	
	NSArray			*spine;
	NSArray			*tour;
	NSXMLNode		*metaDataNode;
	
	NSInteger		currentPosInSpine;
	
}

- (BOOL)openFileWithURL:(NSURL *)aURL;

- (NSString *)nextAudioSegmentFilename;
- (NSString *)prevAudioSegmentFilename;

@property (readonly, retain) NSDictionary *manifest; 	
@property (readonly, retain) NSDictionary *guide;
@property (readonly, retain) NSArray *spine;
@property (readonly, retain) NSArray *tour;

@property (readonly, retain) NSString *ncxFilename;
@property (readonly, retain) NSString *xmlContentFilename;

@property (readonly, retain) NSString *bookTitle;
@property (readonly, retain) NSString *bookSubject;
@property (readonly, retain) NSString *bookTotalTime;
@property (readonly) TalkingBookType bookType;
@property (readonly) TalkingBookMediaFormat bookMediaFormat;

@property (readonly) NSInteger	currentPosInSpine;

@end


