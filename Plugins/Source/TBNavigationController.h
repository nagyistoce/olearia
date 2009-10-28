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

extern NSString * const TBAuxSpeechConDidFinishSpeaking;

#import <Foundation/Foundation.h>
#import <QTKit/QTTime.h>
#import "TBTextContentDoc.h"
#import  "TBSpeechController.h"

@class TBPackageDoc, TBControlDoc, TBSMILDocument, TBAudioSegment;


@interface TBNavigationController : NSObject 
{
	TBBookData			*bookData;
	
	TBPackageDoc		*packageDocument;
	TBControlDoc		*controlDocument;
	TBTextContentDoc	*textDocument;
	TBSMILDocument		*smilDocument;
	NSSpeechSynthesizer	*mainSpeechSynth;
	NSSpeechSynthesizer *auxiliarySpeechSynth;
	
	NSString			*currentSmilFilename;
	NSString			*currentTextFilename;
	NSString			*currentTag;
	NSString			*_contentToSpeak;
	
	TBAudioSegment		*_audioFile;
	//BOOL				_audioIsLoaded;
	NSString			*_currentAudioFilename;
	BOOL				_justAddedChapters;
	BOOL				m_didUserNavigationChange;
	BOOL				_shouldJumpToTime;
	BOOL				_isPlaying;
	BOOL				_mainSynthIsSpeaking;
	QTTime				_timeToJumpTo;
	
	
	NSNotificationCenter *noteCentre;

	
	
}

// methods used for setting and getting the current position in the document
- (void)moveControlPoint:(NSString *)aNodePath withTime:(NSString *)aTime;
- (NSString *)currentNodePath;
- (NSString *)currentTime;

- (void)resetController;
- (void)prepareForPlayback;
- (void)startPlayback;
- (void)stopPlayback;
- (void)speakLevelChange;

- (void)resetController;
- (void)nextElement;
- (void)previousElement;
- (void)goUpLevel;
- (void)goDownLevel;
- (void)jumpAudioForwardInTime;
- (void)jumpAudioBackInTime;

@property (readwrite, retain)	TBPackageDoc		*packageDocument;
@property (readwrite, retain)	TBControlDoc		*controlDocument;
@property (readwrite, retain)	TBSMILDocument		*smilDocument;
@property (readwrite, retain)	TBTextContentDoc	*textDocument;
@property (readwrite, copy)		NSString			*currentTag;
@property (readwrite, copy)		NSString			*currentSmilFilename;
@property (readwrite, copy)		NSString			*currentTextFilename;


@end

@interface TBNavigationController (Synchronization)

- (void)updateAfterNavigationChange;

@end

@interface TBNavigationController (SpeechDelegate)

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success;
- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender willSpeakWord:(NSRange)wordToSpeak ofString:(NSString *)text;

@end



