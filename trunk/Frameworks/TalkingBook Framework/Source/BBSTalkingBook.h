//
//  BBSTalkingBook.h
//  BBSTalkingBook
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

#import <Cocoa/Cocoa.h>
#import "BBSTalkingBookTypes.h"

@class BBSTBSMILDocument, BBSTBTextDocument;
@class BBSTBControlDoc, BBSTBPackageDoc;
@class QTMovie;



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
	NSString				*preferredVoice;
	NSSpeechSynthesizer		*speechSynth;
	
	
	TalkingBookType			controlMode;
	levelControlMode		levelNavConMode;
	levelControlMode		maxLevelConMode;
	NSInteger				maxLevels;
	NSInteger				totalChapters;
	NSInteger				currentLevelIndex;
	
	NSInteger				currentPageIndex;
	NSInteger				currentChapterIndex;
	NSInteger				bookFormatType;
	NSInteger				currentLevel;
	float					currentPlaybackRate;
	float					currentPlaybackVolume;
	

	id						controlDoc;
	id						packageDoc;
	

	BBSTBTextDocument		*textDoc;
	BBSTBSMILDocument		*smilDoc;
	
	
	NSString				*bookPath;
	NSString				*segmentFilename;
	
	
	NSNotificationCenter	*TalkingBookNotificationCenter;


	BOOL					didLoadOK;
	BOOL					hasPackageFile;
	BOOL					hasControlFile;
	BOOL					hasPageNavigation;
	BOOL					hasPhraseNavigation;
	BOOL					hasSentenceNavigation;
	BOOL					hasWordNavigation;
	
	
	// bindings ivars
	NSString				*bookTitle;
	NSString				*currentSectionTitle;
	NSString				*currentLevelString;
	NSString				*currentPageString;
	BOOL					isPlaying;
	BOOL					canPlay;
	BOOL					hasNextChapter;
	BOOL					hasPreviousChapter;
	BOOL					hasLevelUp;
	BOOL					hasLevelDown;
	BOOL					hasNextSegment;
	BOOL					hasPreviousSegment;
	

	QTMovie					*currentAudioFile;
}


- (BOOL)openWithFile:(NSURL *)aURL;
- (void)playAudio;
- (void)pauseAudio;

- (BOOL)nextSegmentOnLevel;
- (BOOL)nextSegment;
- (BOOL)previousSegment;

- (BOOL)hasChapters;

- (void)upOneLevel;
- (void)downOneLevel;



- (void)nextChapter;
- (void)previousChapter;

- (NSDictionary *)getBookInfo;
- (void)gotoPage;
- (NSDictionary *)getCurrentPageInfo;

- (void)setVolumeLevel:(float)aLevel;
- (void)setPlaybackRate:(float)aRate;
- (void)setPlaybackVoice:(NSString *)aVoiceID;

@property (readwrite, retain) BBSTBControlDoc *controlDoc;
@property (readwrite, retain) BBSTBPackageDoc *packageDoc;

@property (readwrite,retain) NSString	*preferredVoice;

@property (readonly)		NSInteger	maxLevels;

@property (readonly)		NSInteger	currentPageIndex;

@property (retain,readonly)		BBSTBTextDocument		*textDoc;

// bindings ivars
@property (readonly,retain)	NSString	*bookTitle;
@property (readonly,retain) NSString	*currentSectionTitle;
@property (readonly, retain) NSString	*currentLevelString;
@property (readonly,retain) NSString	*currentPageString;
@property (readonly) BOOL		canPlay;
@property (readonly) BOOL		isPlaying;
@property (readonly) BOOL		hasNextChapter;
@property (readonly) BOOL		hasPreviousChapter;
@property (readonly) BOOL		hasLevelUp;
@property (readonly) BOOL		hasLevelDown;
@property (readonly) BOOL		hasNextSegment;
@property (readonly) BOOL		hasPreviousSegment;


@end
