//
//  BBSTBPackageDoc.h
//  TalkingBook Framework
//
//  Created by Kieren Eaton on 25/08/08.
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
#import "BBSTBSharedBookData.h"

@interface BBSTBPackageDoc : NSObject 
{

	NSXMLDocument			*xmlPackageDoc;
	
	BBSTBSharedBookData		*bookData;
	
	NSString				*ncxFilename;
	NSString				*xmlContentFilename;
	
	
}

- (NSString *)stringForXquery:(NSString *)aQuery ofNode:(NSXMLNode *)theNode;

- (BOOL)openWithContentsOfURL:(NSURL *)aURL;
- (BOOL)processMetadata;
- (NSXMLNode *)metadataNode;

- (NSString *)nextAudioSegmentFilename;
- (NSString *)prevAudioSegmentFilename;

@property (readwrite, retain) BBSTBSharedBookData *bookData;

@property (readonly, copy) NSString *ncxFilename;
@property (readonly, copy) NSString *xmlContentFilename;

@end
