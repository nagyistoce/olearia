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

- (void)checkMediaFormat;
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
	speechCon = [[TBSpeechController alloc] init];
	
	noteCentre = [NSNotificationCenter defaultCenter];
	_shouldJumpToTime = NO;
	_timeToJumpTo = QTZeroTime;
	
	
	// watch KVO notifications
	[bookData addObserver:self
			    forKeyPath:@"audioPlaybackRate" 
				   options:NSKeyValueObservingOptionNew
				   context:NULL]; 
	
	[bookData addObserver:self
			    forKeyPath:@"audioPlaybackVolume" 
				   options:NSKeyValueObservingOptionNew
				   context:NULL]; 
	
	return self;

}

- (void) dealloc
{
	packageDocument = nil;
	controlDocument = nil;
	
	currentTag = nil;
	_currentAudioFilename = nil;
	currentSmilFilename = nil;
	smilDocument = nil;
	_audioFile = nil;
	
	[bookData removeObserver:self forKeyPath:@"audioPlaybackRate"];
	[bookData removeObserver:self forKeyPath:@"audioPlaybackVolume"];
	
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

	_didUserNavigation = YES;
	
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
	
	[self checkMediaFormat];
	
	if(controlDocument)
	{
		
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
				[smilDocument openWithContentsOfURL:[NSURL URLWithString:currentSmilFilename relativeToURL:bookData.folderPath]];
			}
			_currentAudioFilename = smilDocument.relativeAudioFilePath;
		}
		else
		{
			// no smil filename
			
		}
		
		if(_currentAudioFilename) 
			if([self updateAudioFile:_currentAudioFilename])
			{
				currentTag = [controlDocument currentIdTag];			
				[noteCentre addObserver:self
							   selector:@selector(startPlayback)
								   name:TBAuxSpeechConDidFinishSpeaking
								 object:speechCon];
			}
	
	}
	else if(packageDocument)
	{
		// setup for package navigation
	}
}



- (void)checkMediaFormat
{
	if(UnknownMediaFormat == bookData.mediaFormat)
	{
		// create an alert for the user as we cant establish what the media the book contains
		NSAlert *mediaFormatAlert = [[[NSAlert alloc] init] autorelease];
		[mediaFormatAlert setAlertStyle:NSWarningAlertStyle];
		[mediaFormatAlert setIcon:[NSImage imageNamed:@"olearia.icns"]];
		[mediaFormatAlert setMessageText:NSLocalizedString(@"Unknown Media Format", @"Unknown Media Format alert title")];
		[mediaFormatAlert setInformativeText:NSLocalizedString(@"This Book did not specify what type of media it contains.\n  It will be assumed it contains audio only content.", @"Unknown Media Format alert msg text")];
		[mediaFormatAlert runModal];
		
		bookData.mediaFormat = AudioOnlyMediaFormat;
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
	
	_didUserNavigation = YES;
	
	[self updateAfterNavigationChange];
}

- (void)previousElement
{
	if(controlDocument)
	{	
		[controlDocument moveToPreviousSegment];
		currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigation = YES;
	
	[self updateAfterNavigationChange];
	
	
}

- (void)goUpLevel
{
	if(controlDocument)
	{	
		[controlDocument goUpALevel];
		currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigation = YES;
	
	[self updateAfterNavigationChange];
	[self stopPlayback];
	[speechCon speakLevelChange];
}

- (void)goDownLevel
{
	if(controlDocument)
	{	
		[controlDocument goDownALevel];
		currentTag = [controlDocument currentIdTag];
	}
	_didUserNavigation = YES;
	
	[self updateAfterNavigationChange];
	
	[self stopPlayback];
	[speechCon speakLevelChange];
}

- (void)startPlayback
{
	if(_audioFile)
	{	
		[_audioFile play];
		bookData.isPlaying = YES;
	}
}

- (void)stopPlayback
{
	if(_audioFile)
	{	
		[_audioFile stop];
		bookData.isPlaying = NO;
	}
	
}

#pragma mark -
#pragma mark Private Methods


- (void)setPreferredAudioAttributes
{
	[_audioFile setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieRateChangesPreservePitchAttribute];
	[_audioFile setAttribute:[NSNumber numberWithFloat:bookData.audioPlaybackVolume] forKey:QTMoviePreferredVolumeAttribute];
	[_audioFile setVolume:bookData.audioPlaybackVolume];
	
	[_audioFile setAttribute:[NSNumber numberWithFloat:bookData.audioPlaybackRate] forKey:QTMoviePreferredRateAttribute];
	if(!bookData.isPlaying)
	{	
		[_audioFile stop];
	}
	else
	{	
		[_audioFile setRate:bookData.audioPlaybackRate];
	}
	
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
		
		[_audioFile stop]; // pause the playback if there is any currently playing
		_audioFile = nil;
		_audioFile = [[TBAudioSegment alloc] initWithFile:[[[bookData folderPath] path] stringByAppendingPathComponent:relativePathToFile] error:&theError];
		
		if(_audioFile != nil)
		{
			
			// watch for load state changes
			[noteCentre addObserver:self
						   selector:@selector(loadStateDidChange:)
							   name:QTMovieLoadStateDidChangeNotification
							 object:_audioFile];
			
			// make the file editable and set the timescale for it 
			[_audioFile setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
			
			// small audio files load so fast they do not post a notification for load completed
			// so check the load state an if the file has any chapters
			if(([[_audioFile attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete))
			{	
				// no chapters and its loaded so post a notification to add chapters
				[noteCentre postNotificationName:QTMovieLoadStateDidChangeNotification object:_audioFile];
			}
			loadedOK = YES;
		}
	}
	
	
	if((!_audioFile))
	{	
		NSAlert *theAlert = [NSAlert alertWithError:theError];
		[theAlert setMessageText:NSLocalizedString(@"Error Opening Audio File", @"audio error alert short msg")];
		[theAlert setInformativeText:NSLocalizedString(@"There was a problem loading an audio file.\n Please check the book for problems.\nOlearia will now reset as we cannot continue", @"audio error alert short msg")];
		[theAlert setAlertStyle:NSWarningAlertStyle];
		[theAlert setIcon:[NSImage imageNamed:@"olearia.icns"]];		
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
	if((bookData.mediaFormat != AudioOnlyMediaFormat) && (bookData.mediaFormat != AudioNcxOrNccMediaFormat))
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
			if([_audioFile hasChapters])
				// watch for chapter change notifications 
				[noteCentre addObserver:self 
							   selector:@selector(updateForChapterChange:) 
								   name:QTMovieChapterDidChangeNotification 
								 object:_audioFile];
		}
		
	}
}

- (void)resetController
{
	if(_audioFile)
		[_audioFile release];
	_audioFile = nil;
	_currentAudioFilename = nil;
	currentSmilFilename = nil;
	currentTag = nil;
	_didUserNavigation = NO;
	_justAddedChapters = NO;
	
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
		[_audioFile setAttribute:[NSNumber numberWithFloat:bookData.audioPlaybackRate] forKey:QTMoviePreferredRateAttribute];
		if(!bookData.isPlaying) 
		{	
			// this is a workaround for the current issue where setting the 
			// playback speed using setRate: automatically starts playback
			[_audioFile stop];
		}
		else
			[_audioFile setRate:bookData.audioPlaybackRate];
		
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


@synthesize packageDocument, controlDocument, textDocument, smilDocument, speechCon;
@synthesize currentSmilFilename, currentTextFilename, currentTag;


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
			[smilDocument openWithContentsOfURL:[NSURL URLWithString:currentSmilFilename relativeToURL:bookData.folderPath]];
		}
		
		// user navigation uses the control Doc to change position
		if(_didUserNavigation) 
		{	
			if((bookData.mediaFormat != AudioOnlyMediaFormat) && (bookData.mediaFormat != AudioNcxOrNccMediaFormat))
			{
				if(controlDocument)
					[smilDocument jumpToNodeWithIdTag:currentTag];
			}
			_didUserNavigation = NO;
		}
		
		_currentAudioFilename = smilDocument.relativeAudioFilePath;
		
		if(_currentAudioFilename)
			[self updateAudioFile:_currentAudioFilename];
		[controlDocument updateDataForCurrentPosition];
	}
}


@end


