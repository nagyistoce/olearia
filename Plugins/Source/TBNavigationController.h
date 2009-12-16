//
//  TBNavigationController.h
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 11/06/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
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
#import "TBTextContentDoc.h"
#import "TBSpeechController.h"

@class TBPackageDoc, TBControlDoc, TBSMILDocument, BBSAudioSegment;

typedef enum
{
	skipBackward = 0,
	skipForward = 1
} audioSkipDirection;

@interface TBNavigationController : NSObject 
{
	TBBookData			*bookData;
	
	BOOL				isEndOfBook;
	
	TalkingBookMediaFormat bookMediaFormat;
	
	TBPackageDoc		*packageDocument;
	TBControlDoc		*controlDocument;
	TBTextContentDoc	*textDocument;
	TBSMILDocument		*smilDocument;
	NSSpeechSynthesizer	*mainSpeechSynth;
	NSSpeechSynthesizer *auxiliarySpeechSynth;
	
	NSString			*currentSmilFilename;
	NSString			*currentTextFilename;
	NSString			*currentTag;
	NSString			*contentToSpeak;
	
	BBSAudioSegment		*audioSegment;
	NSString			*currentAudioFilename;
	BOOL				_didUserNavigationChange;
	BOOL				_shouldJumpToTime;
	BOOL				_mainSynthIsSpeaking;
	BOOL				_isDoingTimeSkip;
	audioSkipDirection	_skipDirection;
	QTTime				_timeOffset;
	QTTime				_timeToJumpTo;
	
	
	NSNotificationCenter *noteCentre;
	
}

@property (readwrite)			TalkingBookMediaFormat	bookMediaFormat;
@property (readwrite, retain)	TBPackageDoc			*packageDocument;
@property (readwrite, retain)	TBControlDoc			*controlDocument;
@property (readwrite, retain)	TBSMILDocument			*smilDocument;
@property (readwrite, retain)	TBTextContentDoc		*textDocument;

@property (readwrite,copy)		NSString			*currentSmilFilename;
@property (readwrite,copy)		NSString			*currentTextFilename;
@property (readwrite,copy)		NSString			*currentTag;
@property (readwrite,copy)		NSString			*contentToSpeak;	
@property (readwrite,copy)		NSString			*currentAudioFilename;

@end

@interface TBNavigationController (Playback)

- (void)prepareForPlayback;
- (void)resetController;
- (void)startPlayback;
- (void)stopPlayback;

@end


@interface TBNavigationController (Query)

- (NSString *)currentNodePath;
- (NSString *)currentPlaybackTime;

@end


@interface TBNavigationController (Navigation) 

- (void)nextElement;
- (void)previousElement;
- (void)goUpLevel;
- (void)goDownLevel;
- (void)jumpAudioForwardInTime;
- (void)jumpAudioBackInTime;
- (void)moveControlPoint:(NSString *)aNodePath withTime:(NSString *)aTime;

@end

@interface TBNavigationController (Synchronization)

- (void)updateAfterNavigationChange;
- (void)updateForAudioChapterPosition;
- (void)addChaptersToAudioSegment;
- (void)setPreferredAudioAttributes;
- (BOOL)updateAudioFile:(NSString *)pathToFile;
- (void)speakLevelChange;

@end






