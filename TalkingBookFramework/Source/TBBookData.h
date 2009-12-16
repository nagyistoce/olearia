//
//  TBBookData.h
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
#import <QTKit/QTTime.h>

extern NSString * const PreferredSynthesizerVoice;
extern NSString * const AudioPlaybackRate;
extern NSString * const AudioPlaybackVolume;


@interface TBBookData : NSObject 
{
	
	NSString				*bookTitle;
	NSString				*bookSubject;
	NSString				*sectionTitle;

	NSInteger				totalPages;
	NSInteger				currentPageNumber;
	NSString				*currentPageString;
	QTTime					totalPlaybackTime;
	QTTime					currentPlaybackTime;
	NSString				*totalPlaybackTimeString;
	NSString				*currentPlaybackTimeString;
	NSString				*currentLevelString;
	NSInteger				currentLevel;
	
	BOOL					hasNextChapter;
	BOOL					hasPreviousChapter;
	BOOL					hasLevelUp;
	BOOL					hasLevelDown;
	BOOL					hasNextSegment;
	BOOL					hasPreviousSegment;
	BOOL					isPlaying;
	
	QTTime					audioSkipDuration;
	
	BOOL					localBookSettingsHaveChanged;
	
	NSURL					*baseFolderPath;
	
	// User settings
	NSString				*preferredVoiceIdentifier;
	BOOL					ignoreRecordedAudioContent;
	BOOL					speakUserLevelChange;
	BOOL					speakPageNumbers;
	BOOL					includeSkippableContent;
	float					audioPlaybackRate;
	float					audioPlaybackVolume;
	float					voicePlaybackVolume;
	
	
}

// UI Feedback 
@property (readwrite, copy)	NSString	*bookTitle;
@property (readwrite, copy)	NSString	*bookSubject;
@property (readwrite, copy)	NSString	*sectionTitle;

@property (readwrite)		NSInteger	currentLevel;
@property (readwrite, copy)	NSString	*currentLevelString;

@property (readwrite)		BOOL		localBookSettingsHaveChanged;

@property (readwrite)		NSInteger	currentPageNumber;
@property (readwrite, copy)	NSString	*currentPageString;

@property (readwrite) QTTime					totalPlaybackTime;
@property (readwrite) QTTime					currentPlaybackTime;
@property (readwrite, copy) NSString			*totalPlaybackTimeString;
@property (readwrite, copy) NSString			*currentPlaybackTimeString;


@property (readwrite)		NSInteger	totalPages;

@property (readwrite) BOOL		hasNextChapter;
@property (readwrite) BOOL		hasPreviousChapter;
@property (readwrite) BOOL		hasLevelUp;
@property (readwrite) BOOL		hasLevelDown;
@property (readwrite) BOOL		hasNextSegment;
@property (readwrite) BOOL		hasPreviousSegment;
@property (readwrite) BOOL		isPlaying;

@property (readwrite,retain)	NSURL *baseFolderPath;

// user settings
@property (readwrite, copy)	NSString	*preferredVoiceIdentifier;
@property (readwrite)		BOOL		ignoreRecordedAudioContent;
@property (readwrite)		BOOL		speakUserLevelChange;
@property (readwrite)		BOOL		speakPageNumbers;
@property (readwrite)		BOOL		includeSkippableContent;
@property (readwrite)		QTTime		audioSkipDuration;
@property (readwrite)		float		audioPlaybackRate;
@property (readwrite)		float		audioPlaybackVolume;
@property (readwrite)		float		voicePlaybackVolume;

+ (TBBookData *)sharedBookData;
- (void)resetData;

@end
