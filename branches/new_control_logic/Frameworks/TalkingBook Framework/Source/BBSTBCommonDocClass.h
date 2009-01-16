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
#import <QTKit/QTTime.h>

extern NSString * const TalkingBookAudioSegmentDidChangeNotification;

@interface BBSTBCommonDocClass : NSObject 
{
	// bindings ivars
	NSString				*bookTitle;
	NSString				*bookSubject;
	NSString				*sectionTitle;

	NSInteger				totalPages;
	NSInteger				currentPage;
	NSString				*pageString;
	NSString				*bookTotalTime;
	
	NSString				*levelString;
	NSInteger				currentLevel;
	
	float					playbackRate;
	float					playbackVolume;
	
	BOOL					hasNextChapter;
	BOOL					hasPreviousChapter;
	BOOL					hasLevelUp;
	BOOL					hasLevelDown;
	BOOL					hasNextSegment;
	BOOL					hasPreviousSegment;
	
	BOOL					isPlaying;
	
	TalkingBookType			bookType;
	TalkingBookMediaFormat	mediaFormat;
	
	QTTime					chapterSkipDuration;
}

// bindings ivars
@property (readwrite, copy)	NSString	*bookTitle;
@property (readwrite, copy) NSString	*bookSubject;
@property (readwrite, copy)	NSString	*sectionTitle;

@property (readwrite)		NSInteger	currentLevel;
@property (readwrite, copy)	NSString	*levelString;

@property (readwrite)		float		playbackRate;
@property (readwrite)		float		playbackVolume;

@property (readwrite)		NSInteger	currentPage;
@property (readwrite)		NSInteger	totalPages;
@property (readwrite,copy)	NSString	*pageString;

@property (readwrite,copy)	NSString	*bookTotalTime;

@property (readwrite) BOOL		hasNextChapter;
@property (readwrite) BOOL		hasPreviousChapter;
@property (readwrite) BOOL		hasLevelUp;
@property (readwrite) BOOL		hasLevelDown;
@property (readwrite) BOOL		hasNextSegment;
@property (readwrite) BOOL		hasPreviousSegment;

@property (readwrite) BOOL		isPlaying;

@property (readwrite) TalkingBookType bookType;
@property (readwrite) TalkingBookMediaFormat mediaFormat;

@property (readwrite) QTTime	chapterSkipDuration;

+ (BBSTBCommonDocClass *)sharedInstance;
- (void)resetForNewBook;
- (void)setMediaFormatFromString:(NSString *)mediaTypeString;

@end
