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
#import "TBAudioSegment.h"
#import "TBTextContentDoc.h"

@interface TBNavigationController () 

@property (readwrite, retain)	TBSMILDocument		*_smilDoc;
@property (readwrite, retain)	TBAudioSegment		*_audioFile;
@property (readwrite)			BOOL				_didUserNavigation;
@property (readwrite)			BOOL				_justAddedChapters;
@property (readwrite)			BOOL				_shouldJumpToTime;
@property (readwrite)			QTTime				_timeToJumpTo;
@property (readwrite, copy)		NSString			*_currentTag;
@property (readwrite, copy)		NSString			*_currentSmilFilename;
@property (readwrite, copy)		NSString			*_currentAudioFilename;
@property (readwrite, retain)	NSNotificationCenter *_notCenter;


- (void)checkMediaFormat;
- (void)startPlayback;
- (void)stopPlayback;

- (void)updateForAudioChapterPosition;
- (void)addChaptersToAudioSegment;
- (void)setPreferredAudioAttributes;
- (BOOL)updateAudioFile:(NSString *)pathToFile;
- (void)updateAfterNavigationChange;
- (void)resetController;

@end

@implementation TBNavigationController

- (id)initWithSharedData:(id)sharedDataClass
{
	if (!(self=[super init])) return nil;
	
	packageDocument = nil;
	controlDocument = nil;
	_smilDoc = nil;
	_audioFile = nil;
	_currentTag = nil;
	if([[sharedDataClass class] respondsToSelector:@selector(sharedBookData)])
		bookData = [[sharedDataClass class] sharedBookData];
	_notCenter = [NSNotificationCenter defaultCenter];
	_shouldJumpToTime = NO;
	_timeToJumpTo = QTZeroTime;
	
	// watch KVO notifications
	[bookData addObserver:self
			    forKeyPath:@"playbackRate" 
				   options:NSKeyValueObservingOptionNew
				   context:NULL]; 
	
	[bookData addObserver:self
			    forKeyPath:@"playbackVolume" 
				   options:NSKeyValueObservingOptionNew
				   context:NULL]; 
	
	[bookData addObserver:self
			    forKeyPath:@"isPlaying"
				   options:NSKeyValueObservingOptionNew
				   context:NULL];
	
	return self;

}

- (void) dealloc
{
	self.packageDocument = nil;
	self.controlDocument = nil;
	
	_currentTag = nil;
	_currentAudioFilename = nil;
	_currentSmilFilename = nil;
	_smilDoc = nil;
	_audioFile = nil;
	
	[bookData removeObserver:self forKeyPath:@"isPlaying"];
	[bookData removeObserver:self forKeyPath:@"playbackRate"];
	[bookData removeObserver:self forKeyPath:@"playbackVolume"];
	
	[_notCenter removeObserver:self];
	
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
			if(!_smilDoc)
				_smilDoc = [[TBSMILDocument alloc] init];
			
			// check if the smil file REALLY needs to be loaded
			// Failsafe for single smil books 
			if(![_currentSmilFilename isEqualToString:filename])
			{
				_currentSmilFilename = [filename copy];
				[_smilDoc openWithContentsOfURL:[NSURL URLWithString:_currentSmilFilename relativeToURL:bookData.folderPath]];
			}
			_currentAudioFilename = _smilDoc.relativeAudioFilePath;
		}
		else
		{
			// no smil filename
			
		}
		
		if(_currentAudioFilename) 
			if([self updateAudioFile:_currentAudioFilename])
				_currentTag = [controlDocument currentIdTag];			
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
		NSAlert *mediaFormatAlert = [[NSAlert alloc] init];
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
		_currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigation = YES;
	
	[self updateAfterNavigationChange];
}

- (void)previousElement
{
	if(controlDocument)
	{	
		[controlDocument moveToPreviousSegment];
		_currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigation = YES;
	
	[self updateAfterNavigationChange];
}

- (void)goUpLevel
{
	if(controlDocument)
	{	
		[controlDocument goUpALevel];
		_currentTag = [controlDocument currentIdTag];
	}
				
	_didUserNavigation = YES;
	
	[self updateAfterNavigationChange];
		
}

- (void)goDownLevel
{
	if(controlDocument)
	{	
		[controlDocument goDownALevel];
		_currentTag = [controlDocument currentIdTag];
	}
		
	_didUserNavigation = YES;
	
	[self updateAfterNavigationChange];
	
}

#pragma mark -
#pragma mark Private Methods

- (void)startPlayback
{
	if(_audioFile)
		[_audioFile play];
}

- (void)stopPlayback
{
	if(_audioFile)
		[_audioFile stop];
}

- (void)setPreferredAudioAttributes
{
	[_audioFile setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieRateChangesPreservePitchAttribute];
	[_audioFile setAttribute:[NSNumber numberWithFloat:bookData.playbackVolume] forKey:QTMoviePreferredVolumeAttribute];
	[_audioFile setVolume:bookData.playbackVolume];
	if(!bookData.isPlaying)
	{	
		[_audioFile setAttribute:[NSNumber numberWithFloat:bookData.playbackRate] forKey:QTMoviePreferredRateAttribute];
		[_audioFile stop];
	}
	else
	{	
		[_audioFile setAttribute:[NSNumber numberWithFloat:bookData.playbackRate] forKey:QTMoviePreferredRateAttribute];
		[_audioFile setRate:bookData.playbackRate];
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
		[_notCenter removeObserver:self];
		
		[_audioFile stop]; // pause the playback if there is any currently playing
		_audioFile = nil;
		_audioFile = [[TBAudioSegment alloc] initWithFile:[[[bookData folderPath] path] stringByAppendingPathComponent:relativePathToFile] error:&theError];
		
		if(_audioFile != nil)
		{
			
			// watch for load state changes
			[_notCenter addObserver:self
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
				[[NSNotificationCenter defaultCenter] postNotificationName:QTMovieLoadStateDidChangeNotification object:_audioFile];
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
	self.bookData.hasNextChapter = [_audioFile nextChapterIsAvail];
	self.bookData.hasPreviousChapter = [_audioFile prevChapterIsAvail];
	[controlDocument updateDataForCurrentPosition];
}

- (void)updateAfterNavigationChange
{
	NSString *filename = [controlDocument contentFilenameFromCurrentNode];
	if([[filename pathExtension] isEqualToString:@"smil"])
	{
		// check if the smil file REALLY needs to be loaded
		// Failsafe for single smil books 
		if(![_currentSmilFilename isEqualToString:filename])
		{
			if(!_smilDoc)
				_smilDoc = [[TBSMILDocument alloc] init];
			
			_currentSmilFilename = [filename copy];
			[_smilDoc openWithContentsOfURL:[NSURL URLWithString:_currentSmilFilename relativeToURL:bookData.folderPath]];
		}
		
		// user navigation uses the control Doc to change position
		if(_didUserNavigation) 
		{	
			if((bookData.mediaFormat != AudioOnlyMediaFormat) && (bookData.mediaFormat != AudioNcxOrNccMediaFormat))
			{
				if(controlDocument)
					[_smilDoc jumpToNodeWithIdTag:_currentTag];
			}
			_didUserNavigation = NO;
		}
		
		_currentAudioFilename = _smilDoc.relativeAudioFilePath;
		
		if(_currentAudioFilename)
			[self updateAudioFile:_currentAudioFilename];
		[controlDocument updateDataForCurrentPosition];
	}
}

- (void)addChaptersToAudioSegment
{
	NSArray *chapters = nil;
	if((bookData.mediaFormat != AudioOnlyMediaFormat) && (bookData.mediaFormat != AudioNcxOrNccMediaFormat))
	{
		chapters = [_smilDoc audioChapterMarkersForFilename:_smilDoc.relativeAudioFilePath WithTimescale:([_audioFile duration].timeScale)];
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
				[_notCenter addObserver:self 
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
	_currentSmilFilename = nil;
	_currentTag = nil;
	_didUserNavigation = NO;
	_justAddedChapters = NO;
	
	[_notCenter removeObserver:self];
}

#pragma mark -
#pragma mark KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([keyPath isEqualToString:@"isPlaying"])
		(bookData.isPlaying) ? [self startPlayback] : [self stopPlayback];
	else if([keyPath isEqualToString:@"playbackVolume"])
		[_audioFile setVolume:bookData.playbackVolume];
	else if([keyPath isEqualToString:@"playbackRate"])
	{
		if(!bookData.isPlaying) 
		{	
			// this is a workaround for the current issue where setting the 
			// playback speed using setRate: automatically starts playback
			[_audioFile setAttribute:[NSNumber numberWithFloat:bookData.playbackRate] forKey:QTMoviePreferredRateAttribute];
			[_audioFile stop];
		}
		else
		{	
			[_audioFile setAttribute:[NSNumber numberWithFloat:bookData.playbackRate] forKey:QTMoviePreferredRateAttribute];
			[_audioFile setRate:bookData.playbackRate];
		}
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

	if([notification object] == self._audioFile)
	{
		// update the smil doc to the current tags position
		[_smilDoc jumpToNodeWithIdTag:_currentTag];
		// check for a new audio segment in the smil file
		if([_smilDoc audioAfterCurrentPosition])
		{
			_currentAudioFilename = _smilDoc.relativeAudioFilePath;
			_currentTag = [_smilDoc currentIdTag];
			// sync the new position in the smil with the control document
			if(controlDocument)
				[controlDocument jumpToNodeWithIdTag:_currentTag];
			if(_currentAudioFilename)
				[self updateAudioFile:_smilDoc.relativeAudioFilePath];
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
	}
}

- (void)loadStateDidChange:(NSNotification *)notification
{
	if([notification object] == self._audioFile)
		if([[notification name] isEqualToString:QTMovieLoadStateDidChangeNotification])
			if([[_audioFile attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete)
			{	
				// add chapters if required
				[self addChaptersToAudioSegment];

				if(!_shouldJumpToTime)
					[_audioFile setCurrentTime:[_audioFile startTimeOfChapterWithTitle:_currentTag]];
				else
				{	
					[_audioFile setCurrentTime:_timeToJumpTo];
					_shouldJumpToTime = NO;
				}
				
				[self setPreferredAudioAttributes];
				
				// watch for end of audio file notifications
				[_notCenter addObserver:self 
							   selector:@selector(audioFileDidEnd:) 
								   name:QTMovieDidEndNotification 
								 object:_audioFile];
								
				if(bookData.isPlaying)
					[_audioFile play];
			}
}


- (void)updateForChapterChange:(NSNotification *)notification
{
	if([notification object] == self._audioFile)
	{
		if((!_justAddedChapters))
		{
			_currentTag = [_audioFile currentChapterName];
			[self updateForAudioChapterPosition];
		}
		else
			_justAddedChapters = NO;

	}
}


@synthesize packageDocument, controlDocument, textDocument;
@synthesize _audioFile, _smilDoc, bookData, _notCenter;
@synthesize _currentSmilFilename, _currentAudioFilename, _currentTag;
@synthesize _didUserNavigation, _justAddedChapters, _shouldJumpToTime;
@synthesize _timeToJumpTo;

@end

