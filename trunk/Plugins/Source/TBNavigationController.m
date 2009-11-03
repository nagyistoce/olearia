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
#import "TBAudioSegment.h"

@interface TBNavigationController () 

- (void)updateForAudioChapterPosition;
- (void)addChaptersToAudioSegment;
- (void)setPreferredAudioAttributes;
- (BOOL)updateAudioFile:(NSString *)pathToFile;


@end


@implementation TBNavigationController

- (id)init
{
	if (!(self=[super init])) return nil;
	
	packageDocument = nil;
	controlDocument = nil;
	smilDocument = nil;
	_audioFile = nil;
	
	currentTag = nil;
	
	bookData = [TBBookData sharedBookData];
	mainSpeechSynth = [[[NSSpeechSynthesizer alloc] initWithVoice:bookData.preferredVoiceIdentifier] retain];
	[mainSpeechSynth setDelegate:self];
	auxiliarySpeechSynth = [[[NSSpeechSynthesizer  alloc] initWithVoice:bookData.preferredVoiceIdentifier] retain];
	[auxiliarySpeechSynth setDelegate:self];
		
	
	noteCentre = [NSNotificationCenter defaultCenter];
	_shouldJumpToTime = NO;
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
	packageDocument = nil;
	controlDocument = nil;
	
	[currentTag release];
	[_contentToSpeak release];
	[_currentAudioFilename release];
	currentSmilFilename = nil;
	smilDocument = nil;
	_audioFile = nil;
	
	[bookData removeObserver:self forKeyPath:AudioPlaybackRate];
	[bookData removeObserver:self forKeyPath:AudioPlaybackVolume];
	[bookData removeObserver:self forKeyPath:PreferredSynthesizerVoice];
	
	[noteCentre removeObserver:self];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Public Methods

- (void)moveControlPoint:(NSString *)aNodePath withTime:(NSString *)aTime
{
	// the control document will always be our first choice for navigation
	if(controlDocument)
	{	
		[controlDocument jumpToNodeWithPath:aNodePath];
		currentTag = [controlDocument currentIdTag];
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

	m_didUserNavigationChange = YES;
	
	[self updateAfterNavigationChange];
	
}

- (NSString *)currentNodePath
{
	if(controlDocument)
		return [controlDocument currentPositionID];
	
	return nil;
}

- (NSString *)currentTime
{
	if(_audioFile)
		return QTStringFromTime([_audioFile currentTime]);
	
	return nil;
}

/*
	This Method is called when the book is first opened 
	it checks the type of control/navigation files available and the validates the
	media format of the book.
	it then sets up the dependencies for playback to start.
 
	this method will be over-ridden by subclasses that have specific format support issues
 */

- (void)prepareForPlayback
{
	[self resetController];
	
	if(controlDocument)
	{
		if(nil == controlDocument.currentNavPoint)
		{	
			[controlDocument jumpToNodeWithPath:nil];
			currentTag = [controlDocument currentIdTag];
		}
		
		NSString *filename = [controlDocument contentFilenameFromCurrentNode];
		if([[filename pathExtension] isEqualToString:@"smil"])
		{
			if(!smilDocument)
				smilDocument = [[TBSMILDocument alloc] init];
			
			// check if the smil file REALLY needs to be loaded
			// Failsafe for single smil books 
			if(![currentSmilFilename isEqualToString:filename])
			{
				currentSmilFilename = [filename copy];
				[smilDocument openWithContentsOfURL:[NSURL URLWithString:currentSmilFilename relativeToURL:bookData.baseFolderPath]];
			}
			_currentAudioFilename = smilDocument.relativeAudioFilePath;
		}
		else
		{
			// no smil filename
			
		}
		
		if(_currentAudioFilename) 
		{	
	
			

			
			if([self updateAudioFile:_currentAudioFilename])
			{
				currentTag = [controlDocument currentIdTag];			
			}
		}
			
	
	}
	else if(packageDocument)
	{
		// setup for package navigation
	}
	
	
}





#pragma mark -
#pragma mark Navigation

- (void)nextElement
{
	if(controlDocument)
	{	
		[controlDocument moveToNextSegmentAtSameLevel];
		currentTag = [controlDocument currentIdTag];
	}
	
	m_didUserNavigationChange = YES;
	
	[self updateAfterNavigationChange];
}

- (void)previousElement
{
	if(controlDocument)
	{	
		[controlDocument moveToPreviousSegment];
		currentTag = [controlDocument currentIdTag];
	}
	
	m_didUserNavigationChange = YES;
	
	[self updateAfterNavigationChange];
	
	
	
}

- (void)goUpLevel
{
	if(controlDocument)
	{	
		[controlDocument goUpALevel];
		currentTag = [controlDocument currentIdTag];
	}
	
	m_didUserNavigationChange = YES;
	
	[self updateAfterNavigationChange];
	[self speakLevelChange];
}

- (void)goDownLevel
{
	if(controlDocument)
	{	
		[controlDocument goDownALevel];
		currentTag = [controlDocument currentIdTag];
	}
	
	m_didUserNavigationChange = YES;
	
	[self updateAfterNavigationChange];
	[self speakLevelChange];
}

- (void)startPlayback
{
	if((!bookData.isPlaying) && (!_audioFile.isPlaying))
	{	
		[_audioFile play];
		bookData.isPlaying = YES;
	}
}

- (void)stopPlayback
{
	if((bookData.isPlaying) && (_audioFile.isPlaying))
	{	
		[_audioFile stop];
		bookData.isPlaying = NO;
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
		
		
		if (_audioFile.isPlaying)
		{
			[_audioFile stop];
		}
		[auxiliarySpeechSynth startSpeakingString:[NSString stringWithFormat:LocalizedStringInTBStdPluginBundle(@"Level %d",@"Level %d"),bookData.currentLevel]];
		
	}
	
	
}


#pragma mark -
#pragma mark Private Methods


- (void)setPreferredAudioAttributes
{
	[_audioFile setVolume:bookData.audioPlaybackVolume];
	[_audioFile setRate:bookData.audioPlaybackRate];
	[_audioFile setDelegate:self];
}

- (BOOL)updateAudioFile:(NSString *)relativePathToFile
{
	BOOL loadedOK = NO;
	NSError *theError = nil;
	
	
	
	// check that we have not passed in a nil string
	if(relativePathToFile != nil)
	{
		[noteCentre removeObserver:self name:QTMovieLoadStateDidChangeNotification object:_audioFile];
		[noteCentre removeObserver:self name:QTMovieDidEndNotification object:_audioFile];
		[noteCentre removeObserver:self name:QTMovieChapterDidChangeNotification object:_audioFile];
		
		if (_audioFile)
		{
			[_audioFile stop]; // pause the playback
			_audioFile = nil;
		}

		
		
		
		 
		NSString *fullFilePath = [[NSString stringWithString:[[[bookData baseFolderPath] path] stringByAppendingPathComponent:relativePathToFile]] autorelease];
		_audioFile = [[TBAudioSegment alloc] initWithFile:fullFilePath error:&theError];
		
		if(_audioFile != nil)
		{
			// watch for load state changes
			[noteCentre addObserver:self
						   selector:@selector(loadStateDidChange:)
							   name:QTMovieLoadStateDidChangeNotification
							 object:_audioFile];
			
			// watch for chapter change notifications 
			[noteCentre addObserver:self 
						   selector:@selector(updateForChapterChange:) 
							   name:QTMovieChapterDidChangeNotification 
							 object:_audioFile];
						
			// small audio files load so fast they do not post a notification for load completed
			if(([[_audioFile attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete))
			{	
				// post a notification to add chapters and set attributes
				[noteCentre postNotificationName:QTMovieLoadStateDidChangeNotification object:_audioFile];
			}
			loadedOK = YES;
		}
	}
	
	
	if((!_audioFile))
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
	bookData.hasNextChapter = [_audioFile nextChapterIsAvail];
	bookData.hasPreviousChapter = [_audioFile prevChapterIsAvail];
	[controlDocument updateDataForCurrentPosition];
}


- (void)addChaptersToAudioSegment
{
	NSArray *chapters = nil;
	if((bookMediaFormat != AudioOnlyMediaFormat) && (bookMediaFormat != AudioWithControlMediaFormat))
	{
		chapters = [smilDocument audioChapterMarkersForFilename:smilDocument.relativeAudioFilePath WithTimescale:([_audioFile duration].timeScale)];
		if([chapters count])
		{	
			NSError *theError = nil;
			// get the track the chapter will be associated with
			QTTrack *musicTrack = [[_audioFile tracksOfMediaType:QTMediaTypeSound] objectAtIndex:0];
			NSDictionary *trackDict = [NSDictionary dictionaryWithObjectsAndKeys:musicTrack, QTMovieChapterTargetTrackAttribute,nil];
			// add the chapters both to the Audio track
			_justAddedChapters = YES;
			[_audioFile addChapters:chapters withAttributes:trackDict error:&theError];
			
		}
		
	}
}

- (void)resetController
{
	if(_audioFile)
	{	
		[_audioFile stop];
		_audioFile = nil;
	}
	
	_currentAudioFilename = nil;
	_contentToSpeak = nil;
	currentSmilFilename = nil;
	currentTag = nil;
	m_didUserNavigationChange = NO;
	_justAddedChapters = NO;
	[mainSpeechSynth stopSpeaking];
	[auxiliarySpeechSynth stopSpeaking];
	
	[noteCentre removeObserver:self];
}

#pragma mark -
#pragma mark KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([keyPath isEqualToString:@"audioPlaybackVolume"])
		[_audioFile setVolume:bookData.audioPlaybackVolume];
	else if([keyPath isEqualToString:@"audioPlaybackRate"])
	{
		
		if(!_audioFile.isPlaying) 
			[_audioFile setAttribute:[NSNumber numberWithFloat:bookData.audioPlaybackRate] forKey:QTMoviePreferredRateAttribute];
		else
			[_audioFile setRate:bookData.audioPlaybackRate];
		
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


#pragma mark -
#pragma mark Notifications

- (void)audioFileDidEnd:(NSNotification *)notification
{

	if([notification object] == _audioFile)
	{
		if (!_justAddedChapters)
		{
			// update the smil doc to the current tags position
			[smilDocument jumpToNodeWithIdTag:currentTag];
			// check for a new audio segment in the smil file
			if([smilDocument audioAfterCurrentPosition])
			{
				_currentAudioFilename = smilDocument.relativeAudioFilePath;
				currentTag = [smilDocument currentIdTag];
				// sync the new position in the smil with the control document
				if(controlDocument)
					[controlDocument jumpToNodeWithIdTag:currentTag];
				if(_currentAudioFilename)
					[self updateAudioFile:smilDocument.relativeAudioFilePath];
			}
			else
			{
				if(controlDocument)
				{
					// update the control documents current position 
					[controlDocument jumpToNodeWithIdTag:currentTag];
					[controlDocument moveToNextSegment];
					// set the tag for the new position
					currentTag = [controlDocument currentIdTag];
					[self updateAfterNavigationChange];
				}
			}
			
		}
		else 
		{
			_justAddedChapters = NO;
		}

	}
}

- (void)loadStateDidChange:(NSNotification *)notification
{
	if([notification object] == _audioFile)
		if([[notification name] isEqualToString:QTMovieLoadStateDidChangeNotification])
			if([[_audioFile attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete)
			{	
				// add chapters if required
				[self addChaptersToAudioSegment];

				if(!_shouldJumpToTime)
					[_audioFile setCurrentTime:[_audioFile startTimeOfChapterWithTitle:currentTag]];
				else
				{	
					[_audioFile setCurrentTime:_timeToJumpTo];
					_shouldJumpToTime = NO;
				}
				
				[self setPreferredAudioAttributes];
				
				// watch for end of audio file notifications
				[noteCentre addObserver:self 
							   selector:@selector(audioFileDidEnd:) 
								   name:QTMovieDidEndNotification 
								 object:_audioFile];
				
				if(bookData.isPlaying)
					[_audioFile play];
			}
}


- (void)updateForChapterChange:(NSNotification *)notification
{
	if([notification object] == _audioFile)
	{
		if((!_justAddedChapters))
		{
			currentTag = [_audioFile currentChapterName];
			[self updateForAudioChapterPosition];
		}
		else
			_justAddedChapters = NO;

	}
}


- (void)jumpAudioForwardInTime
{
	
}

- (void)jumpAudioBackInTime
{
	
}




@synthesize packageDocument, controlDocument, textDocument, smilDocument;
@synthesize currentSmilFilename, currentTextFilename, currentTag;
@synthesize bookMediaFormat;


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
			
			currentSmilFilename = [filename copy];
			[smilDocument openWithContentsOfURL:[NSURL URLWithString:currentSmilFilename relativeToURL:bookData.baseFolderPath]];
		}
		
		// user navigation uses the control Doc to change position
		if(m_didUserNavigationChange) 
		{	
			if((bookMediaFormat != AudioOnlyMediaFormat) && (bookMediaFormat != AudioWithControlMediaFormat))
			{
				if(controlDocument)
					[smilDocument jumpToNodeWithIdTag:currentTag];
			}
			m_didUserNavigationChange = NO;
		}
		
		_currentAudioFilename = smilDocument.relativeAudioFilePath;
		
		if(_currentAudioFilename)
			[self updateAudioFile:_currentAudioFilename];
		
		[controlDocument updateDataForCurrentPosition];
	}
}


@end

@implementation TBNavigationController (SpeechDelegate)

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success
{
	if(sender == auxiliarySpeechSynth)
	{	
		if (bookData.isPlaying && !_audioFile.isPlaying)
		{
			[_audioFile play];
		}
//		if(_mainSynthIsSpeaking)
//			[mainSpeechSynth continueSpeaking];
		//				else
		//				{	
		//				if(!m_didUserNavigationChange)
		//					[[NSNotificationCenter defaultCenter] postNotificationName:TBAuxSpeechConDidFinishSpeaking object:self];
		//					else
		//					{	
		//						m_didUserNavigationChange = NO;
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

