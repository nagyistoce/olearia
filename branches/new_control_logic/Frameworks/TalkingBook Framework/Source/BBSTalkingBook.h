//
//  BBSTalkingBook.h
//  TalkingBook Framework
//
//  Created by Kieren Eaton on 5/05/08.
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

#import "BBSTalkingBookTypes.h"
#import <QTKit/QTTime.h>

@class BBSTBInfoController;
@class BBSTBCommonDocClass;

typedef enum 
{
	levelNavigationControlMode,
	pageNavigationControlMode,
	phraseNavigationControlMode,
	sentenceNavigationControlMode,
	wordNavigationControlMode
} levelControlMode;

@interface BBSTalkingBook : NSObject 
{
	// book user settings
	NSString				*preferredVoice;
	float					playbackRate;
	float					playbackVolume;
//	float					chapterSkipIncrement;
	BOOL					overrideRecordedContent;
	BOOL					speakUserLevelChange;
	BOOL					bookIsAlreadyLoaded;
//	BOOL					shouldJumpToTime;
	NSString				*audioSegmentTimePosition;
	
	NSSpeechSynthesizer		*speechSynth;
	
	TalkingBookType			_controlMode;
	levelControlMode		_levelNavConMode;
	levelControlMode		_maxLevelConMode;
//	TalkingBookMediaFormat  _mediaFormat;
	
//	NSInteger				maxLevels;
//	NSInteger				_totalChapters;
//	NSInteger				_currentLevelIndex;
//	NSInteger				_currentChapterIndex;
//	NSInteger				bookFormatType;
	//NSInteger				currentLevel;
	
	id						_textDoc;
	id						_smilDoc;
	id						_controlDoc;
	id						_packageDoc;
	BBSTBCommonDocClass		*commonInstance;
	BBSTBInfoController		*_infoController;
	

	NSString				*_currentSegmentFilename;
	NSString				*playPositionID;
	NSURL					*_bookBaseURL;
	
	BOOL					_hasPackageFile;
	BOOL					_hasControlFile;

	BOOL					_hasPageNavigation;
	BOOL					_hasPhraseNavigation;
	BOOL					_hasSentenceNavigation;
	BOOL					_hasWordNavigation;

	// bindings
	BOOL					isPlaying;
	BOOL					canPlay;

}


- (BOOL)openWithFile:(NSURL *)aURL;
- (void)playAudio;
- (void)pauseAudio;

- (BOOL)nextSegmentOnLevel;
- (BOOL)nextSegment;
- (BOOL)previousSegment;
- (void)upOneLevel;
- (void)downOneLevel;
- (void)nextChapter;
- (void)previousChapter;

- (void)jumpToPosition:(NSString *)aPosition;
- (void)updateSkipDuration:(float)newDuration;

- (void)showBookInfo;
- (void)gotoPage;
- (NSDictionary *)getCurrentPageInfo;

@property (readwrite, retain)	BBSTBCommonDocClass *commonInstance;

@property (readwrite, copy)		NSString	*preferredVoice;
@property (readwrite)			float		playbackRate;
@property (readwrite)			float		playbackVolume;
@property (readwrite, copy)		NSString	*playPositionID;

@property (readwrite)			BOOL		bookIsAlreadyLoaded;
@property (readwrite)			BOOL		overrideRecordedContent;
@property (readwrite)			BOOL		speakUserLevelChange;
@property (readwrite, copy)		NSString	*audioSegmentTimePosition;

@property (readonly) BOOL		canPlay;
@property (readonly) BOOL		isPlaying;


@end