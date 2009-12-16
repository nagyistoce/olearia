//
//  TBNavigationController.m
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

#import <Cocoa/Cocoa.h>
#import "TBNavigationController.h"
#import "TBOPFDocument.h"
#import "TBNCXDocument.h"
#import "TBSMILDocument.h"
#import "BBSAudioSegment.h"

@implementation TBNavigationController

- (id)init
{
	if (!(self=[super init])) return nil;
	
	packageDocument = nil;
	controlDocument = nil;
	smilDocument = nil;
	audioSegment = nil;
	
	currentTag = @""; //[[NSString alloc] init];
	currentAudioFilename = @""; //[[NSString alloc] init];
	currentSmilFilename = @""; //[[NSString alloc] init];
	currentTextFilename = @""; //[[NSString alloc] init];
	contentToSpeak = @""; //[[NSString alloc] init];
	
	bookData = [TBBookData sharedBookData];
	mainSpeechSynth = [[[NSSpeechSynthesizer alloc] initWithVoice:bookData.preferredVoiceIdentifier] retain];
	[mainSpeechSynth setDelegate:self];
	auxiliarySpeechSynth = [[[NSSpeechSynthesizer  alloc] initWithVoice:bookData.preferredVoiceIdentifier] retain];
	[auxiliarySpeechSynth setDelegate:self];
		
	
	noteCentre = [NSNotificationCenter defaultCenter];
	
	_shouldJumpToTime = NO;
	_didUserNavigationChange = NO;
	_timeToJumpTo = QTZeroTime;
	
		
	// watch KVO notifications
	[bookData addObserver:self
			    forKeyPath:AudioPlaybackRate 
				   options:NSKeyValueObservingOptionNew
				   context:NULL]; 
	
	[bookData addObserver:self
			    forKeyPath:AudioPlaybackVolume 
				   options:NSKeyValueObservingOptionNew
				   context:NULL]; 
	
	[bookData addObserver:self 
			   forKeyPath:PreferredSynthesizerVoice
				  options:NSKeyValueObservingOptionNew
				  context:NULL];

	[noteCentre addObserver:self
				   selector:@selector(didFinishSpeakingLevelChange:) 
					   name:TBSpeechConDidFinishSpeaking 
					 object:auxiliarySpeechSynth];
	
	return self;

}

- (void) dealloc
{
	[bookData removeObserver:self forKeyPath:AudioPlaybackVolume];
	[bookData removeObserver:self forKeyPath:AudioPlaybackRate];
	[bookData removeObserver:self forKeyPath:PreferredSynthesizerVoice];
	[noteCentre removeObserver:self];

	[packageDocument release];
	[controlDocument release];
	[smilDocument release];
	
	[currentTag release];
	[contentToSpeak release];
	[currentAudioFilename release];
	[currentSmilFilename release];
	[currentTextFilename release];
	
	[audioSegment release];
	
	
	[super dealloc];
}

@synthesize packageDocument, controlDocument, textDocument, smilDocument;
@synthesize bookMediaFormat;
@synthesize currentSmilFilename, currentAudioFilename, currentTextFilename;
@synthesize currentTag, contentToSpeak;

@end

@implementation TBNavigationController (Playback)

- (void)startPlayback
{
	if((!bookData.isPlaying) && (!audioSegment.isPlaying))
	{	
		[audioSegment play];
		bookData.isPlaying = YES;
	}
}

- (void)stopPlayback
{
	if((bookData.isPlaying) && (audioSegment.isPlaying))
	{	
		[audioSegment stop];
		bookData.isPlaying = NO;
	}
	
}

- (void)prepareForPlayback
{
	[self resetController];
	
	if(controlDocument)
	{
		if ([controlDocument isKindOfClass:[TBNCXDocument class]])
		{
			if(nil == controlDocument.currentNavPoint)
				[controlDocument jumpToNodeWithPath:nil];
		}
		self.currentTag = [controlDocument currentIdTag];
		
		NSString *filename = [controlDocument contentFilenameFromCurrentNode];
		if([[filename pathExtension] isEqualToString:@"smil"])
		{
			if(!smilDocument)
				smilDocument = [[TBSMILDocument alloc] init];
			
			// check if the smil file REALLY needs to be loaded
			// Failsafe for single smil books 
			if(![currentSmilFilename isEqualToString:filename])
			{
				self.currentSmilFilename = [filename copy];
				[smilDocument openWithContentsOfURL:[NSURL URLWithString:currentSmilFilename relativeToURL:bookData.baseFolderPath]];
			}
			self.currentAudioFilename = [smilDocument relativeAudioFilePath];
		}
		else
		{
			// no smil filename
			// take the audio filename directly from the control document
			
		}
		
		if(currentAudioFilename) 
		{	
			[self updateAudioFile:currentAudioFilename];
		}
		else // no audio filename found
		{
			[controlDocument moveToNextSegment];
			[self prepareForPlayback];
		}

			
	
	}
	else if(packageDocument)
	{
		// setup for package navigation
	}
	
	
}

- (void)resetController
{
	if(audioSegment)
	{	
		[audioSegment stop];
	}
	
	isEndOfBook = NO;
	self.currentAudioFilename = @"";
	self.contentToSpeak = @"";
	self.currentSmilFilename = @"";
	self.currentTag = @"";
	_isDoingTimeSkip = NO;
	_skipDirection = skipForward;
	_didUserNavigationChange = NO;
	[mainSpeechSynth stopSpeaking];
	[auxiliarySpeechSynth stopSpeaking];
	
}


@end


@implementation TBNavigationController (Query)


- (NSString *)currentNodePath
{
	if(controlDocument)
		return [controlDocument currentPositionID];
	
	return nil;
}

- (NSString *)currentPlaybackTime
{
	if(audioSegment)
		return QTStringFromTime([audioSegment currentTime]);
	
	return nil;
}



@end



@implementation TBNavigationController (Navigation)

- (void)moveControlPoint:(NSString *)aNodePath withTime:(NSString *)aTime
{
	// the control document will always be our first choice for navigation
	if(controlDocument)
	{	
		[controlDocument jumpToNodeWithPath:aNodePath];
		self.currentTag = [controlDocument currentIdTag];
	}
	else if(packageDocument)
	{
		// need to add navigation methods for package documents
	}

	if(aTime)
	{
		_shouldJumpToTime = YES;
		_timeToJumpTo = QTTimeFromString(aTime);
	}

	_didUserNavigationChange = YES;
	
	[self updateAfterNavigationChange];
	
}

- (void)nextElement
{
	if(controlDocument)
	{	
		[controlDocument moveToNextSegmentAtSameLevel];
		self.currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigationChange = YES;
	
	[self updateAfterNavigationChange];
}

- (void)previousElement
{
	if(controlDocument)
	{	
		[controlDocument moveToPreviousSegment];
		self.currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigationChange = YES;
	
	[self updateAfterNavigationChange];
	
	
}

- (void)goUpLevel
{
	if(controlDocument)
	{	
		[controlDocument goUpALevel];
		self.currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigationChange = YES;

	
	[self updateAfterNavigationChange];
	[self speakLevelChange];
}

- (void)goDownLevel
{
	if(controlDocument)
	{	
		[controlDocument goDownALevel];
		self.currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigationChange = YES;
	if ((audioSegment) && ([audioSegment isPlaying]))
		[audioSegment stop];

	[self updateAfterNavigationChange];
	[self speakLevelChange];
}

- (void)jumpAudioForwardInTime
{
	QTTime remainingTime = QTZeroTime;
	// make sure we are playing before trying to skip either direction
	if(bookData.isPlaying)
	{
		// get the time remaining in this segment
		remainingTime = QTTimeDecrement([audioSegment duration], [audioSegment currentTime]);		
		// not skipping beyond segment end (yet)
		if (!_isDoingTimeSkip)
		{
			// first time through we set the offset to the skip duration
			// so it can be reduced later if required 
			_timeOffset = bookData.audioSkipDuration;
			// check if the time remaining is longer than or equal to the skip duration
			if (QTTimeCompare(_timeOffset, remainingTime) <= BBSTimesAreEqual) 
			{
				_isDoingTimeSkip = NO;
				// advance the current time by the skip duration
				[audioSegment setCurrentTime:QTTimeIncrement([audioSegment currentTime], _timeOffset)];
			}
			else 
			{
				// the time to jump to is beyond the duration of this audio segment
				// decrement the skip duration by the remaining unplayed portion of the audio segment
				_timeOffset = QTTimeDecrement(_timeOffset, remainingTime);
				_isDoingTimeSkip = YES;
				_skipDirection = skipForward;
				[noteCentre postNotificationName:BBSAudioSegmentDidEndNotification object:audioSegment];
			}
		}
		else // we are now in a new audio segment  
		{
			// check if the time remaining is longer than or equal to the skip duration
			if (QTTimeCompare(_timeOffset, remainingTime) <= BBSTimesAreEqual) 
			{	
				_isDoingTimeSkip = NO;
				[audioSegment setCurrentTime:_timeOffset];
				// we post a load state did change notification to force an update of the present data position
				[noteCentre postNotificationName:BBSAudioSegmentLoadStateDidChangeNotification object:audioSegment];
			}
			else 
			{
				// the time to jump to is again beyond the duration of this audio segment
				// decrement the skip duration by the remaining unplayed portion of the audio segment
				_timeOffset = QTTimeDecrement(_timeOffset, remainingTime);
				// post an audio segment did end notification to force loading of the next segment without 
				// playing the current one to completion.
				[noteCentre postNotificationName:BBSAudioSegmentDidEndNotification object:audioSegment];
			}
		}
	}
}

- (void)jumpAudioBackInTime
{
	BOOL shouldLoadNewSegment = NO;	
	QTTime currentPlayhead = QTZeroTime;
	// make sure we are playing before trying to skip either direction
	if(bookData.isPlaying)
	{
		// get the current playhead time of this segment
		currentPlayhead = [audioSegment currentTime];		
		// not skipping before segment beginning (yet)
		if (!_isDoingTimeSkip)
		{
			// set the duration to skip back 
			// only if we havent set it previously
			if (QTTimeCompare(_timeOffset, QTZeroTime) == BBSTimesAreEqual)
				_timeOffset = bookData.audioSkipDuration;
			
			// check if the time this segment has been playing is longer than the skip duration
			if (QTTimeCompare(currentPlayhead, _timeOffset) >= BBSTimesAreEqual) 
			{
				_isDoingTimeSkip = NO;
				// decrement the current time by the skip duration
				[audioSegment setCurrentTime:QTTimeDecrement([audioSegment currentTime], _timeOffset)];
				_timeOffset = QTZeroTime;
			}
			else 
			{
				_isDoingTimeSkip = YES;
				_timeOffset = QTTimeDecrement(_timeOffset, currentPlayhead);
				shouldLoadNewSegment = YES;
				
			}
		}
		else // we have already started skipping 
		{	
			// check if the duration of this segment is longer than the remaining skip duration
			if (QTTimeCompare(_timeOffset, [audioSegment duration]) <= BBSTimesAreEqual) 
			{	
				_isDoingTimeSkip = NO;
				[audioSegment setCurrentTime:QTTimeDecrement([audioSegment duration], _timeOffset)];
				_timeOffset = QTZeroTime;
				[noteCentre postNotificationName:BBSAudioSegmentLoadStateDidChangeNotification object:audioSegment];
				
			}
			else 
			{
				
				_timeOffset = QTTimeDecrement(_timeOffset, [audioSegment duration]);
				shouldLoadNewSegment = YES;
			}
			
		}
		
		
		if (shouldLoadNewSegment)
		{
			if (smilDocument)
			{
				if ([smilDocument moveToAudioBeforeCurrentPosition])
				{
					// the time to jump to is before the start of this audio segment
					// decrement the skip duration by the played portion of the audio segment
					_timeOffset = QTTimeDecrement(_timeOffset, currentPlayhead);
					_isDoingTimeSkip = YES;
					_skipDirection = skipBackward;
					
					self.currentAudioFilename = smilDocument.relativeAudioFilePath;
					self.currentTag = [smilDocument currentIdTag];
					// sync the new position in the smil with the control document
					if(controlDocument)
						[controlDocument jumpToNodeWithIdTag:currentTag];
					if(currentAudioFilename)
						[self updateAudioFile:smilDocument.relativeAudioFilePath];
					
				}
				else 
				{
					_isDoingTimeSkip = YES;
					_skipDirection = skipBackward;
					[self previousElement];
					[noteCentre postNotificationName:BBSAudioSegmentLoadStateDidChangeNotification object:audioSegment];
				}
				
			}
		}
	}	
	
	
}


@end

@implementation TBNavigationController (Synchronization)

- (void)updateAfterNavigationChange
{
	NSString *filename = [controlDocument contentFilenameFromCurrentNode];
	if([[filename pathExtension] isEqualToString:@"smil"])
	{
		// check if the smil file REALLY needs to be loaded
		// Failsafe for single smil books 
		if(![currentSmilFilename isEqualToString:filename])
		{
			if(!smilDocument)
				smilDocument = [[TBSMILDocument alloc] init];
			
			self.currentSmilFilename = [filename copy];
			[smilDocument openWithContentsOfURL:[NSURL URLWithString:currentSmilFilename relativeToURL:bookData.baseFolderPath]];
		}
		
		// user navigation uses the control Doc to change position
		if(_didUserNavigationChange) 
		{	
			if((bookMediaFormat != AudioOnlyMediaFormat) && (bookMediaFormat != AudioWithControlMediaFormat))
			{
				if(controlDocument)
					[smilDocument jumpToNodeWithIdTag:currentTag];
			}
			
		}
		
		self.currentAudioFilename = smilDocument.relativeAudioFilePath;
		
		if(currentAudioFilename)
			[self updateAudioFile:currentAudioFilename];
		
		if (!_didUserNavigationChange)
			[controlDocument updateDataForCurrentPosition];
		else
			_didUserNavigationChange = NO;
	}
}

- (void)speakLevelChange
{
	if(bookData.speakUserLevelChange)
	{	
		if ([mainSpeechSynth isSpeaking])
		{
			[mainSpeechSynth stopSpeaking];
		}
		
		
		if (audioSegment.isPlaying)
		{
			[audioSegment stop];
		}
		[auxiliarySpeechSynth startSpeakingString:[NSString stringWithFormat:LocalizedStringInTBStdPluginBundle(@"Level %d",@"Level %d"),bookData.currentLevel]];
		
	}
	
	
}

- (void)setPreferredAudioAttributes
{
	[audioSegment setVolume:bookData.audioPlaybackVolume];
	[audioSegment setRate:bookData.audioPlaybackRate];
}

- (BOOL)updateAudioFile:(NSString *)relativePathToFile
{
	BOOL loadedOK = NO;
	NSError *theError = nil;
	
	// check that we have not passed in a nil string
	if(relativePathToFile != nil)
	{
		if([audioSegment isPlaying])
			[audioSegment stop];
		
		NSString *fullFilePath = [[NSString stringWithString:[[[bookData baseFolderPath] path] stringByAppendingPathComponent:relativePathToFile]] autorelease];
		if(audioSegment)
			loadedOK = [audioSegment openWithFile:fullFilePath];
		else
		{
			audioSegment = [[BBSAudioSegment alloc] initWithFile:fullFilePath];
			if(audioSegment)
			{
				[noteCentre addObserver:self 
							   selector:@selector(loadStateDidChange:) 
								   name:BBSAudioSegmentLoadStateDidChangeNotification 
								 object:audioSegment];
				
				// we dont need to watch for segment end or chanpter change notifications 
				// while fast forwarding through audio
				if (!_isDoingTimeSkip)
				{
					[noteCentre addObserver:self 
								   selector:@selector(audioFileDidEnd:) 
									   name:BBSAudioSegmentDidEndNotification 
									 object:audioSegment];
					[noteCentre addObserver:self
								   selector:@selector(updateAfterChapterChange:) 
									   name:BBSAudioSegmentChapterDidChangeNotifiction
									 object:audioSegment];
				}

				loadedOK = YES;
			}
			
			
			
		}
	}
	
	
	if(loadedOK)
	{
		[audioSegment setRate:bookData.audioPlaybackRate];
		[audioSegment setVolume:bookData.audioPlaybackVolume];
	}
	else
	{	
		NSAlert *theAlert = [NSAlert alertWithError:theError];
		[theAlert setMessageText:LocalizedStringInTBStdPluginBundle(@"Error Opening Audio File", @"audio error alert short msg")];
		[theAlert setInformativeText:LocalizedStringInTBStdPluginBundle(@"There was a problem loading an audio file.\n Please check the book for problems.\nOlearia will now reset as we cannot continue", @"audio error alert short msg")];
		[theAlert setAlertStyle:NSWarningAlertStyle];
		[theAlert setIcon:[NSApp applicationIconImage]];		
		[theAlert beginSheetModalForWindow:[NSApp keyWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
		
	}
	
	return loadedOK;
}

- (void)updateForAudioChapterPosition
{
	bookData.hasNextChapter = [audioSegment hasNextChapter];
	bookData.hasPreviousChapter = [audioSegment hasPreviousChapter];
	[controlDocument updateDataForCurrentPosition];
}


- (void)addChaptersToAudioSegment
{
	NSArray *chapters = nil;
	if((bookMediaFormat != AudioOnlyMediaFormat) && (bookMediaFormat != AudioWithControlMediaFormat))
	{
		chapters = [smilDocument audioChapterMarkersForFilename:smilDocument.relativeAudioFilePath WithTimescale:([audioSegment duration].timeScale)];
		if([chapters count])
		{	
			[audioSegment addChapters:chapters];
		}
		
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([keyPath isEqualToString:@"audioPlaybackVolume"])
		[audioSegment setVolume:bookData.audioPlaybackVolume];
	else if([keyPath isEqualToString:@"audioPlaybackRate"])
	{
		
		if(!audioSegment.isPlaying) 
			[audioSegment setRate:bookData.audioPlaybackRate];
		else
			[audioSegment setRate:bookData.audioPlaybackRate];
		
	}
	else if([keyPath isEqualToString:@"preferredVoiceIdentifier"])	
	{		
		[mainSpeechSynth setVoice:bookData.preferredVoiceIdentifier];
		[auxiliarySpeechSynth setVoice:bookData.preferredVoiceIdentifier];
	}
	else
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];

}



@end


@implementation TBNavigationController (Notifications)

- (void)audioFileDidEnd:(NSNotification *)notification
{

	if([notification object] == audioSegment)
	{

		// update the smil doc to the current tags position
		[smilDocument jumpToNodeWithIdTag:currentTag];
		// check for a new audio segment in the smil file
		if([smilDocument moveToAudioAfterCurrentPosition])
		{
			self.currentAudioFilename = smilDocument.relativeAudioFilePath;
			self.currentTag = [smilDocument currentIdTag];
			// sync the new position in the smil with the control document
			if(controlDocument)
				[controlDocument jumpToNodeWithIdTag:currentTag];
			if(currentAudioFilename)
				[self updateAudioFile:smilDocument.relativeAudioFilePath];
		}
		else
		{
			if(controlDocument)
			{
				// update the control documents current position in case it has changed
				[controlDocument jumpToNodeWithIdTag:currentTag];
				[controlDocument moveToNextSegment];
				// set the tag for the new position
				self.currentTag = [controlDocument currentIdTag];
				[self updateAfterNavigationChange];
			}
		}
	}
}

- (void)loadStateDidChange:(NSNotification *)notification
{
	if (!_isDoingTimeSkip) 
	{
		// add chapters if required
		[self addChaptersToAudioSegment];
		
		if(!_shouldJumpToTime)
			[audioSegment setCurrentTime:[audioSegment startTimeOfChapterWithTitle:currentTag]];
		else
		{	
			[audioSegment setCurrentTime:_timeToJumpTo];
			_shouldJumpToTime = NO;
		}
		
		[self setPreferredAudioAttributes];
		
		
		if(bookData.isPlaying)
			[audioSegment play];
	}
	else 
	{
		// skipping forward in time
		if (_skipDirection)
			[self jumpAudioForwardInTime]; 
		else // skipping back
			[self jumpAudioBackInTime];
	}


	
}


- (void)updateAfterChapterChange:(NSNotification *)notification
{
	self.currentTag = [audioSegment currentChapterName];
	[self updateForAudioChapterPosition];
}

- (void)didFinishSpeakingLevelChange:(NSNotification *)aNote
{
	
}

@end


@implementation TBNavigationController (SpeechDelegate)

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success
{
	if(sender == auxiliarySpeechSynth)
	{	
		if (bookData.isPlaying && !audioSegment.isPlaying)
		{
			[audioSegment play];
		}
//		if(_mainSynthIsSpeaking)
//			[mainSpeechSynth continueSpeaking];
		//				else
		//				{	
		//				if(!_didUserNavigationChange)
		//					[[NSNotificationCenter defaultCenter] postNotificationName:TBAuxSpeechConDidFinishSpeaking object:self];
		//					else
		//					{	
		//						_didUserNavigationChange = NO;
		//					[[NSNotificationCenter defaultCenter] postNotificationName:TBAuxSpeechConDidFinishSpeaking object:self];
		//				}
		
	
	
	}

	
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender willSpeakWord:(NSRange)wordToSpeak ofString:(NSString *)text
{
//	if(sender == mainSpeechSynth)
//	{
//		//NSLog(@"word num is %d",wordToSpeak.location);
//	}
	// send a notifcation or tell the web/text view to 
	//highlight the current word about to be spoken
	//NSString *wordIs = [text substringWithRange:wordToSpeak];
	//NSLog(@"speaking -> %@",wordIs);
}


@end

