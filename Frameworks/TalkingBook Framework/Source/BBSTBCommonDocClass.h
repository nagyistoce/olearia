//
//  BBSTBCommonDocClass.h
//  TalkingBook Framework
//
//  Created by Kieren Eaton on 9/12/08.
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

@interface BBSTBCommonDocClass : NSObject 
{
	// bindings ivars
	NSString				*bookTitle;
	NSString				*bookSubject;
	NSString				*currentSectionTitle;

	NSInteger				totalPages;
	NSInteger				currentPage;
	NSString				*currentPageString;
	NSString				*bookTotalTime;
	
	NSString				*currentLevelString;
	NSInteger				currentLevel;
	
	BOOL					hasNextChapter;
	BOOL					hasPreviousChapter;
	BOOL					hasLevelUp;
	BOOL					hasLevelDown;
	BOOL					hasNextSegment;
	BOOL					hasPreviousSegment;
	
	TalkingBookType			bookType;
	TalkingBookMediaFormat	mediaFormat;
	
}

// bindings ivars
@property (readwrite, copy)	NSString	*bookTitle;
@property (readwrite, copy) NSString	*bookSubject;
@property (readwrite, copy)	NSString	*currentSectionTitle;

@property (readwrite)		NSInteger	currentLevel;
@property (readonly, copy)	NSString	*currentLevelString;

@property (readwrite)		NSInteger	currentPage;
@property (readwrite)		NSInteger	totalPages;
@property (readonly,copy)	NSString	*currentPageString;

@property (readwrite,copy)	NSString	*bookTotalTime;

@property (readwrite) BOOL		hasNextChapter;
@property (readwrite) BOOL		hasPreviousChapter;
@property (readwrite) BOOL		hasLevelUp;
@property (readwrite) BOOL		hasLevelDown;
@property (readwrite) BOOL		hasNextSegment;
@property (readwrite) BOOL		hasPreviousSegment;

@property (readwrite) TalkingBookType bookType;
@property (readwrite) TalkingBookMediaFormat mediaFormat;

+ (BBSTBCommonDocClass *)sharedInstance;
- (void)resetForNewBook;
- (void)setMediaFormatFromString:(NSString *)mediaTypeString;

@end
