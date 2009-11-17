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

NSString * const TBAuxSpeechConDidFinishSpeaking = @"TBAuxSpeechConDidFinishSpeaking";

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
	_audioSegment = nil;
	
	_currentTag = [[NSString alloc] init];
	_currentAudioFilename = [[NSString alloc] init];
	_currentSmilFilename = [[NSString alloc] init];
	_currentTextFilename = [[NSString alloc] init];
	
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

	return self;

}

- (void) dealloc
{
	[bookData removeObserver:self forKeyPath:AudioPlaybackRate];
	[bookData removeObserver:self forKeyPath:AudioPlaybackVolume];
	[bookData removeObserver:self forKeyPath:PreferredSynthesizerVoice];
	
	[noteCentre removeObserver:self];

	[packageDocument release];
	[controlDocument release];
	[smilDocument release];
	
	[_currentTag release];
	[_contentToSpeak release];
	[_currentAudioFilename release];
	[_currentSmilFilename release];
	
	[_audioSegment release];
	
	
	[super dealloc];
}

@synthesize packageDocument, controlDocument, textDocument, smilDocument;
@synthesize bookMediaFormat;

@end

@implementation TBNavigationController (Playback)

- (void)startPlayback
{
	if((!bookData.isPlaying) && (!_audioSegment.isPlaying))
	{	
		[_audioSegment play];
		bookData.isPlaying = YES;
	}
}

- (void)stopPlayback
{
	if((bookData.isPlaying) && (_audioSegment.isPlaying))
	{	
		[_audioSegment stop];
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
		_currentTag = [controlDocument currentIdTag];
		
		NSString *filename = [controlDocument contentFilenameFromCurrentNode];
		if([[filename pathExtension] isEqualToString:@"smil"])
		{
			if(!smilDocument)
				smilDocument = [[TBSMILDocument alloc] init];
			
			// check if the smil file REALLY needs to be loaded
			// Failsafe for single smil books 
			if(![_currentSmilFilename isEqualToString:filename])
			{
				_currentSmilFilename = [filename copy];
				[smilDocument openWithContentsOfURL:[NSURL URLWithString:_currentSmilFilename relativeToURL:bookData.baseFolderPath]];
			}
			_currentAudioFilename = [smilDocument relativeAudioFilePath];
		}
		else
		{
			// no smil filename
			// take the audio filename directly from the control document
			
		}
		
		if(_currentAudioFilename) 
		{	
			[self updateAudioFile:_currentAudioFilename];
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
	if(_audioSegment)
	{	
		[_audioSegment stop];
	}
	
	isEndOfBook = NO;
	_currentAudioFilename = @"";
	_contentToSpeak = @"";
	_currentSmilFilename = @"";
	_currentTag = @"";
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
	if(_audioSegment)
		return QTStringFromTime([_audioSegment currentTime]);
	
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
		_currentTag = [controlDocument currentIdTag];
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
		_currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigationChange = YES;
	
	[self updateAfterNavigationChange];
}

- (void)previousElement
{
	if(controlDocument)
	{	
		[controlDocument moveToPreviousSegment];
		_currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigationChange = YES;
	
	[self updateAfterNavigationChange];
	
	
}

- (void)goUpLevel
{
	if(controlDocument)
	{	
		[controlDocument goUpALevel];
		_currentTag = [controlDocument currentIdTag];
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
		_currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigationChange = YES;
	if ((_audioSegment) && ([_audioSegment isPlaying]))
		[_audioSegment stop];

	[self updateAfterNavigationChange];
	[self speakLevelChange];
}

- (void)jumpAudioForwardInTime
{
	
}

- (void)jumpAudioBackInTime
{
	
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
		if(![_currentSmilFilename isEqualToString:filename])
		{
			if(!smilDocument)
				smilDocument = [[TBSMILDocument alloc] init];
			
			_currentSmilFilename = [filename copy];
			[smilDocument openWithContentsOfURL:[NSURL URLWithString:_currentSmilFilename relativeToURL:bookData.baseFolderPath]];
		}
		
		// user navigation uses the control Doc to change position
		if(_didUserNavigationChange) 
		{	
			if((bookMediaFormat != AudioOnlyMediaFormat) && (bookMediaFormat != AudioWithControlMediaFormat))
			{
				if(controlDocument)
					[smilDocument jumpToNodeWithIdTag:_currentTag];
			}
			//_didUserNavigationChange = NO;
		}
		
		_currentAudioFilename = smilDocument.relativeAudioFilePath;
		
		if(_currentAudioFilename)
			[self updateAudioFile:_currentAudioFilename];
		
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
		
		
		if (_audioSegment.isPlaying)
		{
			[_audioSegment stop];
		}
		[auxiliarySpeechSynth startSpeakingString:[NSString stringWithFormat:LocalizedStringInTBStdPluginBundle(@"Level %d",@"Level %d"),bookData.currentLevel]];
		
	}
	
	
}

- (void)setPreferredAudioAttributes
{
	[_audioSegment setVolume:bookData.audioPlaybackVolume];
	[_audioSegment setRate:bookData.audioPlaybackRate];
}

- (BOOL)updateAudioFile:(NSString *)relativePathToFile
{
	BOOL loadedOK = NO;
	NSError *theError = nil;
	
	// check that we have not passed in a nil string
	if(relativePathToFile != nil)
	{
		if([_audioSegment isPlaying])
			[_audioSegment stop];
		
		NSString *fullFilePath = [[NSString stringWithString:[[[bookData baseFolderPath] path] stringByAppendingPathComponent:relativePathToFile]] autorelease];
		if(_audioSegment)
			loadedOK = [_audioSegment openWithFile:fullFilePath];
		else
		{
			_audioSegment = [[BBSAudioSegment alloc] initWithFile:fullFilePath];
			if(_audioSegment)
			{
				[noteCentre addObserver:self 
							   selector:@selector(loadStateDidChange:) 
								   name:BBSAudioSegmentLoadStateDidChangeNotification 
								 object:_audioSegment];
				[noteCentre addObserver:self 
							   selector:@selector(audioFileDidEnd:) 
								   name:BBSAudioSegmentDidEndNotification 
								 object:_audioSegment];
				[noteCentre addObserver:self
							   selector:@selector(updateAfterChapterChange:) 
								   name:BBSAudioSegmentChapterDidChangeNotifiction
								 object:_audioSegment];
				loadedOK = YES;
			}
			
			
			
		}
	}
	
	
	if(loadedOK)
	{
		[_audioSegment setRate:bookData.audioPlaybackRate];
		[_audioSegment setVolume:bookData.audioPlaybackVolume];
	}
	else
	{	
		NSAlert *theAlert = [NSAlert alertWithError:theError];
		[theAlert setMessageText:LocalizedStringInTBStdPluginBundle(@"Error Opening Audio File", @"audio error alert short msg")];
		[theAlert setInformativeText:LocalizedStringInTBStdPluginBundle(@"There was a problem loading an audio file.\n Please check the book for problems.\nOlearia will now reset as we cannot continue", @"audio error alert short msg")];
		[theAlert setAlertStyle:NSWarningAlertStyle];
		[theAlert setIcon:[NSApp applicationIconImage]];		
		[theAlert beginSheetModalForWindow:[NSApp keyWindow] modalDelegate:self didEndSelector:@selector(errorDialogDidEnd) contextInfo:nil];
		
	}
	
	return loadedOK;
}

- (void)updateForAudioChapterPosition
{
	bookData.hasNextChapter = [_audioSegment hasNextChapter];
	bookData.hasPreviousChapter = [_audioSegment hasPreviousChapter];
	[controlDocument updateDataForCurrentPosition];
}


- (void)addChaptersToAudioSegment
{
	NSArray *chapters = nil;
	if((bookMediaFormat != AudioOnlyMediaFormat) && (bookMediaFormat != AudioWithControlMediaFormat))
	{
		chapters = [smilDocument audioChapterMarkersForFilename:smilDocument.relativeAudioFilePath WithTimescale:([_audioSegment duration].timeScale)];
		if([chapters count])
		{	
			[_audioSegment addChapters:chapters];
		}
		
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([keyPath isEqualToString:@"audioPlaybackVolume"])
		[_audioSegment setVolume:bookData.audioPlaybackVolume];
	else if([keyPath isEqualToString:@"audioPlaybackRate"])
	{
		
		if(!_audioSegment.isPlaying) 
			[_audioSegment setRate:bookData.audioPlaybackRate];
		else
			[_audioSegment setRate:bookData.audioPlaybackRate];
		
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

	if([notification object] == _audioSegment)
	{
	//	if (!_justAddedChapters)
//		{
			// update the smil doc to the current tags position
			[smilDocument jumpToNodeWithIdTag:_currentTag];
			// check for a new audio segment in the smil file
			if([smilDocument audioAfterCurrentPosition])
			{
				_currentAudioFilename = smilDocument.relativeAudioFilePath;
				_currentTag = [smilDocument currentIdTag];
				// sync the new position in the smil with the control document
				if(controlDocument)
					[controlDocument jumpToNodeWithIdTag:_currentTag];
				if(_currentAudioFilename)
					[self updateAudioFile:smilDocument.relativeAudioFilePath];
			}
			else
			{
				if(controlDocument)
				{
					// update the control documents current position 
					[controlDocument jumpToNodeWithIdTag:_currentTag];
					[controlDocument moveToNextSegment];
					// set the tag for the new position
					_currentTag = [controlDocument currentIdTag];
					[self updateAfterNavigationChange];
				}
			}
			
//		}
//		else 
//		{
//			_justAddedChapters = NO;
//		}

	}
}

- (void)loadStateDidChange:(NSNotification *)notification
{
	
	// add chapters if required
	[self addChaptersToAudioSegment];
	
	if(!_shouldJumpToTime)
		[_audioSegment setCurrentTime:[_audioSegment startTimeOfChapterWithTitle:_currentTag]];
	else
	{	
		[_audioSegment setCurrentTime:_timeToJumpTo];
		_shouldJumpToTime = NO;
	}
	
	[self setPreferredAudioAttributes];
	
	
	if(bookData.isPlaying)
		[_audioSegment play];
	
}


- (void)updateAfterChapterChange:(NSNotification *)notification
{
	_currentTag = [_audioSegment currentChapterName];
	[self updateForAudioChapterPosition];
}


@end


@implementation TBNavigationController (SpeechDelegate)

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success
{
	if(sender == auxiliarySpeechSynth)
	{	
		if (bookData.isPlaying && !_audioSegment.isPlaying)
		{
			[_audioSegment play];
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

