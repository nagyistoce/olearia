//
//  TBNavigationController.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 11/06/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TBNavigationController.h"
#import "TBOPFDocument.h"
#import "TBNCXDocument.h"
#import "TBSMILDocument.h"
#import "TBAudioSegment.h"

@interface TBNavigationController () 

@property (readwrite, retain)	TBSMILDocument		*_smilDoc;
@property (readwrite, retain)	TBAudioSegment		*_audioFile;
@property (readwrite, retain)	TBSharedBookData	*_bookData;
@property (readwrite, copy)		NSString			*_currentTag;
@property (readwrite, copy)		NSString			*_currentSmilFilename;
@property (readwrite, copy)		NSString			*_currentAudioFilename;


- (void)checkMediaFormat;
- (void)startPlayback;
- (void)stopPlayback;

- (void)updateForAudioChapterPosition;
- (void)addChaptersToAudioSegment;
- (void)setPreferredAudioAttributes;
- (BOOL)updateAudioFile:(NSString *)pathToFile;
- (void)updateAfterUserNavigation;
- (void)resetController;

@end

@implementation TBNavigationController

- (id) init
{
	if (!(self=[super init])) return nil;
	
	packageDocument = nil;
	controlDocument = nil;
	_smilDoc = nil;
	_audioFile = nil;
	_currentTag = nil;
	_bookData = [TBSharedBookData sharedInstance];
	
	// watch KVO notifications
	[_bookData addObserver:self
			    forKeyPath:@"playbackRate" 
				   options:NSKeyValueObservingOptionNew
				   context:NULL]; 
	
	[_bookData addObserver:self
			    forKeyPath:@"playbackVolume" 
				   options:NSKeyValueObservingOptionNew
				   context:NULL]; 
	
	[_bookData addObserver:self
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
	
	[_bookData removeObserver:self forKeyPath:@"isPlaying"];
	[_bookData removeObserver:self forKeyPath:@"playbackRate"];
	[_bookData removeObserver:self forKeyPath:@"playbackVolume"];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Public Methods

- (void)moveToNodeWihPath:(NSString *)aNodePath
{
	// the control document will always be our first choice for navigation
	if(controlDocument)
		[controlDocument jumpToNodeWithId:aNodePath];
	else if(packageDocument)
	{
		// need to add navigation methods for package documents
	}

}

- (NSString *)currentNodePath
{
	if(controlDocument)
		return [controlDocument currentPositionID];
	
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
		// check that its not a text only book
		if(TextNcxOrNccMediaFormat > _bookData.mediaFormat)
		{
			
			NSString *filename = [controlDocument filenameFromCurrentNode];
			if([[filename pathExtension] isEqualToString:@"smil"])
			{
				_currentSmilFilename = [filename copy];
					
				// load the smil doc
				if(!_smilDoc)
					_smilDoc = [[TBSMILDocument alloc] init];
				[_smilDoc openWithContentsOfURL:[NSURL URLWithString:_currentSmilFilename relativeToURL:_bookData.folderPath]];
				_currentAudioFilename = _smilDoc.relativeAudioFilePath;
			}
			
			if(_currentAudioFilename) 
			{		// watch for load state changes
				[[NSNotificationCenter defaultCenter] addObserver:self
														 selector:@selector(loadStateDidChange:)
															 name:QTMovieLoadStateDidChangeNotification
														   object:_audioFile];

				
				if([self updateAudioFile:_currentAudioFilename])
					_currentTag = [[controlDocument currentReferenceTag] copy];	
				
			}

		}
		
		
	}
	else if(packageDocument)
	{
		// setup for package navigation
	}
}



- (void)checkMediaFormat
{
	if(UnknownMediaFormat == _bookData.mediaFormat)
	{
		// create an alert for the user as we cant establish what the media the book contains
		NSAlert *mediaFormatAlert = [[NSAlert alloc] init];
		[mediaFormatAlert setAlertStyle:NSWarningAlertStyle];
		[mediaFormatAlert setIcon:[NSImage imageNamed:@"olearia.icns"]];
		[mediaFormatAlert setMessageText:NSLocalizedString(@"Unknown Media Format", @"Unknown Media Format alert title")];
		[mediaFormatAlert setInformativeText:NSLocalizedString(@"This Book did not specify what type of media it contains.\n  It will be assumed it contains audio only content.", @"Unknown Media Format alert msg text")];
		[mediaFormatAlert runModal];
		_bookData.mediaFormat = AudioOnlyMediaFormat;
	}
}

#pragma mark -
#pragma mark Navigation

- (void)nextElement
{
	if(controlDocument)
		[controlDocument moveToNextSegmentAtSameLevel];
	[self updateAfterUserNavigation];
}

- (void)previousElement
{
	if(controlDocument)
		[controlDocument moveToPreviousSegment];
	[self updateAfterUserNavigation];
}

- (void)goUpLevel
{
	if(controlDocument)
	{	
		[controlDocument goUpALevel];
		[self updateAfterUserNavigation];		
	}
	
		
}

- (void)goDownLevel
{
	if(controlDocument)
	{	
		[controlDocument goDownALevel];
		[self updateAfterUserNavigation];
	}
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
	[_audioFile setAttribute:[NSNumber numberWithFloat:_bookData.playbackVolume] forKey:QTMoviePreferredVolumeAttribute];
	[_audioFile setVolume:_bookData.playbackVolume];
	if(!_bookData.isPlaying)
	{	
		[_audioFile setAttribute:[NSNumber numberWithFloat:_bookData.playbackRate] forKey:QTMoviePreferredRateAttribute];
		[_audioFile stop];
	}
	else
	{	
		[_audioFile setAttribute:[NSNumber numberWithFloat:_bookData.playbackRate] forKey:QTMoviePreferredRateAttribute];
		[_audioFile setRate:_bookData.playbackRate];
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
		
		[_audioFile stop]; // pause the playback if there is any currently playing
		_audioFile = nil;
		_audioFile = [[TBAudioSegment alloc] initWithFile:[[[_bookData folderPath] path] stringByAppendingPathComponent:relativePathToFile] error:&theError];
		
		if(_audioFile != nil)
		{
			// make the file editable and set the timescale for it 
			[_audioFile setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
			[self setPreferredAudioAttributes];
			// small audio files load so fast they do not post a notification for load completed
			// so check the load state an if the file has any chapters
			if(([[_audioFile attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete) && (NO == [_audioFile hasChapters]))
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
	self._bookData.hasNextChapter = [_audioFile nextChapterIsAvail];
	self._bookData.hasPreviousChapter = [_audioFile prevChapterIsAvail];
}

- (void)updateAfterUserNavigation
{
	NSString *filename = [controlDocument filenameFromCurrentNode];
	if([[filename pathExtension] isEqualToString:@"smil"])
	{
		_currentSmilFilename = [filename copy];
		
		// load the smil doc
		if(!_smilDoc)
			_smilDoc = [[TBSMILDocument alloc] init];
		
		[_smilDoc openWithContentsOfURL:[NSURL URLWithString:_currentSmilFilename relativeToURL:_bookData.folderPath]];
		_currentAudioFilename = _smilDoc.relativeAudioFilePath;
		
		if(_currentAudioFilename)
			[self updateAudioFile:_currentAudioFilename];
	}
}

- (void)addChaptersToAudioSegment
{
	NSArray *chapters = nil;
	
	// work out how to add the chapters
	if((AudioOnlyMediaFormat != _bookData.mediaFormat) && (AudioNcxOrNccMediaFormat != _bookData.mediaFormat))
	{
		
		// for books with text content we have to add chapters which mark where the text content changes
		chapters = [_smilDoc audioChapterMarkersForFilename:_smilDoc.relativeAudioFilePath WithTimescale:([_audioFile duration].timeScale)];
		NSError *theError = nil;
		// get the track the chapter will be associated with
		QTTrack *musicTrack = [[_audioFile tracksOfMediaType:QTMediaTypeSound] objectAtIndex:0];
		NSDictionary *trackDict = [NSDictionary dictionaryWithObjectsAndKeys:musicTrack, QTMovieChapterTargetTrackAttribute,nil];
		// add the chapters both to the track and also as extended info for later use
		// this is a workaround for the problem that the addchapters strips all but the recognised keys from the chapter
		[_audioFile addChapters:chapters withAttributes:trackDict error:&theError];

	}
	else
	{
		// for audio only books we can just add chapters of the user set duration.
		// add chapters to the current audio file
		[_audioFile addChaptersOfDuration:_bookData.chapterSkipDuration];
		
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
}

#pragma mark -
#pragma mark KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([keyPath isEqualToString:@"isPlaying"])
		(_bookData.isPlaying) ? [self startPlayback] : [self stopPlayback];
	else if([keyPath isEqualToString:@"playbackVolume"])
		[_audioFile setVolume:_bookData.playbackVolume];
	else if([keyPath isEqualToString:@"playbackRate"])
	{
		if(!_bookData.isPlaying) 
		{	
			// this is a workaround for the current issue where setting the 
			// playback speed using setRate: automatically starts playback
			[_audioFile setAttribute:[NSNumber numberWithFloat:_bookData.playbackRate] forKey:QTMoviePreferredRateAttribute];
			[_audioFile stop];
		}
		else
		{	
			[_audioFile setAttribute:[NSNumber numberWithFloat:_bookData.playbackRate] forKey:QTMoviePreferredRateAttribute];
			[_audioFile setRate:_bookData.playbackRate];
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
#ifdef DEBUG	
	NSLog(@"audio file did end");
	NSLog(@"current Time is %@",QTStringFromTime([_audioFile currentTime]));
#endif	
		if([_smilDoc audioAfterCurrentPosition])
		{
			_currentAudioFilename = _smilDoc.relativeAudioFilePath;
			if(_currentAudioFilename)
				[self updateAudioFile:_smilDoc.relativeAudioFilePath];
		}
		else
		{
			if(controlDocument)
			{
				_currentAudioFilename = nil;
				[controlDocument moveToNextSegment];
				NSString *filename = [controlDocument filenameFromCurrentNode];
				if([[filename pathExtension] isEqualToString:@"smil"])
				{
					_currentSmilFilename = [filename copy];
					
					// load the smil doc
					if(!_smilDoc)
						_smilDoc = [[TBSMILDocument alloc] init];
					if([_smilDoc openWithContentsOfURL:[NSURL URLWithString:_currentSmilFilename relativeToURL:_bookData.folderPath]])
						_currentAudioFilename = [[_smilDoc relativeAudioFilePath] copy];
				}
				
				if(_currentAudioFilename) 
					if([self updateAudioFile:_currentAudioFilename])
						_currentTag = [[controlDocument currentReferenceTag] copy];	
				
			}
		}
	}
}

- (void)loadStateDidChange:(NSNotification *)notification
{
	if([[notification name] isEqualToString:QTMovieLoadStateDidChangeNotification])
		if([notification object] == self._audioFile)
			if([[_audioFile attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete)
			{	
				
				//[[NSNotificationCenter defaultCenter] removeObserver:self name:QTMovieDidEndNotification object:_audioFile];
				//[[NSNotificationCenter defaultCenter] removeObserver:self name:QTMovieChapterDidChangeNotification object:_audioFile];
				[self addChaptersToAudioSegment];
				
				// watch for end of audio file notifications
				[[NSNotificationCenter defaultCenter] addObserver:self 
														 selector:@selector(audioFileDidEnd:) 
															 name:QTMovieDidEndNotification 
														   object:_audioFile];
				// watch for chapter change notifications 
				[[NSNotificationCenter defaultCenter] addObserver:self 
														 selector:@selector(updateForChapterChange:) 
															 name:QTMovieChapterDidChangeNotification 
														   object:_audioFile];
				
				
				if(_bookData.isPlaying)
					[_audioFile play];
			}
}


- (void)updateForChapterChange:(NSNotification *)notification
{
	if([notification object] == self._audioFile)
	{
		//NSString *idTag =  [_audioFile currentChapterName];
		self._smilDoc.currentNodePath = [[_audioFile currentChapterInfo] valueForKey:@"XPath"];
	
		[self updateForAudioChapterPosition];
	}
}


@synthesize packageDocument, controlDocument;
@synthesize _audioFile, _smilDoc, _bookData;
@synthesize _currentSmilFilename, _currentAudioFilename, _currentTag;
			   

@end

