//
//  TBTalkingBook.h
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

#import <QTKit/QTTime.h>
#import "TBPluginInterface.h"
#import "TalkingBookTypes.h"

@class TBInfoController;
@class TBSharedBookData;

typedef enum 
{
	levelNavigationControlMode,
	pageNavigationControlMode,
	phraseNavigationControlMode,
	sentenceNavigationControlMode,
	wordNavigationControlMode
} levelControlMode;

@interface TBTalkingBook : NSObject 
{
	// book user settings
	NSString				*preferredVoice;
	BOOL					overrideRecordedContent;
	BOOL					speakUserLevelChange;
	BOOL					bookIsAlreadyLoaded;
	NSString				*audioSegmentTimePosition;
	
	NSMutableArray			*plugins;
	id<TBPluginInterface>	currentPlugin;
	
	NSSpeechSynthesizer		*speechSynth;
	
	TalkingBookType			_controlMode;
	levelControlMode		_levelNavConMode;
	levelControlMode		_maxLevelConMode;
	
	TBSharedBookData		*bookData;
	TBInfoController		*_infoController;
	

	NSString				*_currentSegmentFilename;
	
	BOOL					_hasPageNavigation;
	BOOL					_hasPhraseNavigation;
	BOOL					_hasSentenceNavigation;
	BOOL					_hasWordNavigation;

	// bindings
	BOOL					canPlay;

}


- (BOOL)openBookWithURL:(NSURL *)aURL;
- (void)play;
- (void)pause;

- (void)nextSegmentOnLevel;
- (void)nextSegment;
- (void)previousSegment;
- (void)upOneLevel;
- (void)downOneLevel;
- (void)nextChapter;
- (void)previousChapter;

- (void)jumpToPoint:(NSString *)aNodePath;
- (NSString *)currentPlayPositionID;

- (void)updateSkipDuration:(float)newDuration;

- (void)showHideBookInfo;
- (void)gotoPage;
- (NSDictionary *)getCurrentPageInfo;
- (void)setAudioPlayRate:(float)aRate;
- (void)setAudioVolume:(float)aVolumeLevel;

@property (readwrite, retain)	TBSharedBookData *bookData;

@property (readwrite, copy)		NSString	*preferredVoice;

@property (readwrite)			BOOL		bookIsAlreadyLoaded;
@property (readwrite)			BOOL		overrideRecordedContent;
@property (readwrite)			BOOL		speakUserLevelChange;
@property (readwrite, copy)		NSString	*audioSegmentTimePosition;

@property (readonly) BOOL		canPlay;

@property (readonly, copy)		id<TBPluginInterface>	currentPlugin;

@end
