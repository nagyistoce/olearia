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

typedef enum 
	{
		AudioFullTextMediaFormat,
		AudioPartialTextMediaFormat,
		AudioNcxOrNccMediaFormat,
		AudioOnlyMediaFormat,
		TextPartialAudioMediaFormat,
		TextOnlyNcxOrNccMediaFormat,
		UnknownMediaFormat
	} TalkingBookMediaFormat;

extern NSString * const TalkingBookAudioSegmentDidChangeNotification;

@interface TBBookData : NSObject 
{
	// bindings ivars
	NSString				*m_bookTitle;
	NSString				*m_bookSubject;
	NSString				*m_sectionTitle;

	NSInteger				m_totalPages;
	NSInteger				m_currentPageNumber;
	NSString				*m_currentPageString;
	NSString				*m_bookTotalTime;
	
	NSString				*m_currentLevelString;
	NSInteger				m_currentLevel;
	

	
	BOOL					m_hasNextChapter;
	BOOL					m_hasPreviousChapter;
	BOOL					m_hasLevelUp;
	BOOL					m_hasLevelDown;
	BOOL					m_hasNextSegment;
	BOOL					m_hasPreviousSegment;
	BOOL					m_isPlaying;
	
	QTTime					m_audioSkipDuration;
	
	BOOL					m_localBookSettingsHaveChanged;
	
	TalkingBookMediaFormat	m_mediaFormat;
	NSSpeechSynthesizer		*m_talkingBookSpeechSynth;

	
	NSURL					*m_baseFolderPath;
	
	// User settings
	NSString				*m_preferredVoiceIdentifier;
	BOOL					m_ignoreRecordedAudioContent;
	BOOL					m_speakUserLevelChange;
	BOOL					m_includeSkippableContent;
	float					m_audioPlaybackRate;
	float					m_audioPlaybackVolume;
	
	
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
@property (readwrite)		NSInteger	totalPages;

@property (readwrite, copy)	NSString	*bookTotalTime;

@property (readwrite) BOOL		hasNextChapter;
@property (readwrite) BOOL		hasPreviousChapter;
@property (readwrite) BOOL		hasLevelUp;
@property (readwrite) BOOL		hasLevelDown;
@property (readwrite) BOOL		hasNextSegment;
@property (readwrite) BOOL		hasPreviousSegment;
@property (readwrite) BOOL		isPlaying;

@property (readwrite)			TalkingBookMediaFormat mediaFormat;
@property (readwrite, retain)	NSSpeechSynthesizer *talkingBookSpeechSynth;

@property (readwrite,retain)	NSURL *baseFolderPath;

// user settings
@property (readwrite, copy)	NSString	*preferredVoiceIdentifier;
@property (readwrite)		BOOL		ignoreRecordedAudioContent;
@property (readwrite)		BOOL		speakUserLevelChange;
@property (readwrite)		BOOL		includeSkippableContent;
@property (readwrite)		QTTime		audioSkipDuration;
@property (readwrite)		float		audioPlaybackRate;
@property (readwrite)		float		audioPlaybackVolume;

+ (TBBookData *)sharedBookData;
- (void)resetForNewBook;
- (void)setMediaFormatFromString:(NSString *)mediaTypeString;

@end
