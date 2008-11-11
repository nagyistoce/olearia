//
//  BBSTBPackageDoc.h
//  BBSTalkingBook
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

@interface BBSTBPackageDoc : NSObject 
{

	NSString				*bookTitle;
	NSString				*bookSubject;
	NSString				*bookTotalTime;
	TalkingBookType			bookType;
	TalkingBookMediaFormat	bookMediaFormat;
	
	NSString				*ncxFilename;
	NSString				*xmlContentFilename;
	
	
}

- (BOOL)openPackageFileWithURL:(NSURL *)aURL;
- (NSString *)nextAudioSegmentFilename;
- (NSString *)prevAudioSegmentFilename;

@property (readonly, retain) NSString *bookTitle;
@property (readonly, retain) NSString *bookSubject;
@property (readonly, retain) NSString *bookTotalTime;
@property (readonly) TalkingBookType bookType;
@property (readonly) TalkingBookMediaFormat bookMediaFormat;

@property (readonly, retain) NSString *ncxFilename;
@property (readonly, retain) NSString *xmlContentFilename;

@end
