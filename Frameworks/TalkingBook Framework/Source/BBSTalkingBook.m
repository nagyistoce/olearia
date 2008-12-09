//
//  BBSTalkingBook.m
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

#import "BBSTalkingBook.h"
#import "BBSTBControlDoc.h"
#import "BBSTBPackageDoc.h"
#import "BBSTBOPFDocument.h"
#import "BBSTBNCXDocument.h"
#import "BBSTBNCCDocument.h"
#import "BBSTBSMILDocument.h"
#import "BBSTBInfoController.h"
#import "BBSTBCommonDocClass.h"

#import <QTKit/QTKit.h>

@interface BBSTalkingBook ()


- (void)errorDialogDidEnd;
- (void)resetBook;

//- (void)setupAudioNotifications;
//- (NSArray *)makeChaptersOfDuration:(QTTime)aDuration forMovie:(QTMovie *)aMovie;

- (TalkingBookControlDocType)typeOfControlDoc:(NSURL *)aURL;
//- (void)setPreferredAudioAttributes;
//- (BOOL)updateAudioFile:(NSString *)pathToFile;
//- (void)updateForPosInBook;
//- (void)updateChapterIndex;

- (BOOL)openControlDocument:(NSURL *)aDocUrl;

@property (readwrite, retain) NSSpeechSynthesizer *speechSynth;

@property (readwrite) NSInteger	maxLevels;

@property (readwrite) NSInteger _totalChapters;
@property (readwrite) NSInteger _currentChapterIndex;

@property (readwrite) TalkingBookType _controlMode;

@property (readwrite, retain) id		_controlDoc;
@property (readwrite, retain) id		_packageDoc;
@property (readwrite, retain) id		_textDoc;
@property (readwrite, retain) id		_smilDoc;

@property (readwrite, retain) NSURL *_baseBookURL;

// Bindings related
//@property (readwrite, retain) NSString	*bookTitle;
//@property (readwrite, retain) NSString	*currentSectionTitle;
//@property (readwrite, retain) NSString	*currentPageString;
//@property (readwrite, retain) NSString	*currentLevelString;
@property (readwrite) BOOL		canPlay;
@property (readwrite) BOOL		isPlaying;
//@property (readwrite) BOOL		hasNextChapter;
//@property (readwrite) BOOL		hasPreviousChapter;
//@property (readwrite) BOOL		hasLevelUp;
//@property (readwrite) BOOL		hasLevelDown;
//@property (readwrite) BOOL		hasNextSegment;
//@property (readwrite) BOOL		hasPreviousSegment;

@end

@implementation BBSTalkingBook

- (id) init
{
	if (!(self=[super init])) return nil;

	speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
	[speechSynth setDelegate:self];
	
	commonDoc = [BBSTBCommonDocClass sharedInstance];
		
	[self resetBook];
	
	bookIsAlreadyLoaded = NO;

	return self;
}

- (void) dealloc
{
	if([speechSynth isSpeaking])
		[speechSynth stopSpeaking];
	
	[speechSynth release];
	
	if(_infoController)
		[_infoController release];
	
	if(_controlDoc)
		[_controlDoc release];
	
	if(_packageDoc)
		[_packageDoc release];
	
	if(_smilDoc)
		[_smilDoc release];
	
	if(_textDoc)
		[_textDoc release];
	
	[self resetBook];
	
	[super dealloc];
}


- (BOOL)openWithFile:(NSURL *)aURL
{
	// reset everything ready for a new book to be loaded
	[self resetBook];
	
	BOOL fileOpenedOK = NO;
	
	// get the parent folder path as a string
	_baseBookURL = [[NSURL alloc] initFileURLWithPath:[[aURL path] stringByDeletingLastPathComponent] isDirectory:YES];
	
	// when we do zip files we will check internally for one of the package or control files
	// also direct loading of .iso files would be good too
	
	NSURL *fileURL; 
	// check the extension first
	NSString *filename = [[NSString alloc] initWithString:[aURL path]];
	
	// do a sanity check to see if the user chose a NCX file and there 
	// is actually an OPF file available
	
	// check for an ncx file first
	if([self typeOfControlDoc:aURL] == ncxControlDocType)
	{
		// we assume that the opf file has the same filename as the ncx file sans extension
		NSFileManager *fm = [NSFileManager defaultManager];
		// delete the extension from the NCX filename
		NSMutableString *opfFilePath = [[NSMutableString alloc] initWithString:[filename stringByDeletingPathExtension]];
		// add the OPF extension to the filename
		[opfFilePath appendString:@".opf"];
		// check if the filename exists
		if ([fm fileExistsAtPath:opfFilePath] )
		{	
			// it exists so make a url of it
			fileURL = [[NSURL alloc] initFileURLWithPath:opfFilePath];
			_packageDoc = [[BBSTBOPFDocument alloc] init];
			_hasPackageFile = [_packageDoc openWithContentsOfURL:fileURL];
			if(_hasPackageFile)
			{
				
				fileOpenedOK = _hasPackageFile;
				// successfully opened the opf document so get the ncx filename from it
				//NSString *ncxPathString = [[NSString alloc] initWithString:[[_baseBookURL stringByAppendingPathComponent:[_packageDoc ncxFilename]]];
					
				// make a URL of the full path
				NSURL *ncxURL = [[NSURL alloc] initWithString:[_packageDoc ncxFilename] relativeToURL:_baseBookURL];

				// open the control file
				_hasControlFile = [self openControlDocument:ncxURL];
			}
			else // package file failed opening so drop back to the NCX file 
			{	
				// open the control file
				_hasControlFile = [self openControlDocument:aURL];
				fileOpenedOK = _hasControlFile;
			}

		}
		else // no opf file found - so dropback to the ncx file.
		{	
			_hasControlFile = [self openControlDocument:aURL];
			fileOpenedOK = _hasControlFile;
		}
	}
	else
	{	
		// we have chosen an opf or ncc.html open and process it.
		// check if its an OPF package file
		if(YES == [[[filename pathExtension] lowercaseString] isEqualToString:@"opf"])
		{
			_packageDoc = [[BBSTBOPFDocument alloc] init];
			_hasPackageFile = [_packageDoc openWithContentsOfURL:aURL];
			if(_hasPackageFile)
			{				
				fileOpenedOK = _hasPackageFile;
				
				// get the book type so we know how to control acces to it
				_controlMode = [_packageDoc bookType];
				// successfully opened the opf document so get the ncx filename from it
				//NSString *ncxPathString = [[NSString alloc] initWithString:[_bookPath stringByAppendingPathComponent:[_packageDoc ncxFilename]]];
						
				// make a URL of the full path
				NSURL *ncxURL = [[NSURL alloc] initWithString:[_packageDoc ncxFilename] relativeToURL:_baseBookURL];
					
				_hasControlFile = [self openControlDocument:ncxURL];
				
			}
		}
		
		else //check for a control file of some form
		{
			_hasControlFile = [self openControlDocument:aURL];
			fileOpenedOK = _hasControlFile;
		}
	}
	
	
	if (fileOpenedOK)
	{
		
		self.canPlay = YES;
		bookIsAlreadyLoaded = YES;
		
		fullBookPath = [aURL path];
		
		if(_hasPackageFile)
		{
			//_mediaFormat = [_packageDoc bookMediaFormat];

			//commonDoc.bookTitle = [_packageDoc bookTitle];
			//commonDoc.currentLevel = [_controlDoc currentLevel];
							
		}
		else if(_hasControlFile)
		{
			_mediaFormat = [_controlDoc bookMediaFormat];
			
			
			if(0 == [_controlDoc totalPages])
			{
				//self.currentPageString = NSLocalizedString(@"No Page Numbers", @"no page numbers string");
			}
			else
			{
				
				//self.currentPageString = (0 != [_controlDoc totalPages]) ? [NSString stringWithFormat:@"%d",[_controlDoc totalPages]] : [NSString stringWithFormat:@"%d",[_controlDoc totalTargetPages]];
				//_hasPageNavigation = YES;
				//_maxLevelConMode = pageNavigationControlMode;
			}
			//self.bookTitle = (_hasPackageFile) ? [_packageDoc bookTitle] : [_controlDoc bookTitle];
			//self.currentLevelString = [NSString stringWithFormat:@"%d",[_controlDoc currentLevel]];
			
		}
		
		// setup for the media format of the book
		if(_mediaFormat <= AudioOnlyMediaFormat)
		{
			if([_controlDoc currentSmilFilename])
			{
				
			}
		}
		
		//update the interface with the initial values
		//[self updateForPosInBook];		
		
		//update the information controller if it has been previously loaded
		if(_infoController)
		{
			if(_hasPackageFile)
				[_infoController updateMetaInfoFromNode:[_packageDoc metadataNode]];
			else
				[_infoController updateMetaInfoFromNode:[_controlDoc metadataNode]];
		}
		
		
	}
	
	
	return fileOpenedOK;
	
}

- (BOOL)openControlDocument:(NSURL *)aDocUrl 
{
	BOOL loadedOK = NO;
	
	
	if(nil != aDocUrl)
	{
		TalkingBookControlDocType aType = [self typeOfControlDoc:aDocUrl];
		switch (aType)
		{
			case ncxControlDocType:
				_controlDoc = [[BBSTBNCXDocument alloc] init];
				break;
			case bookshareNcxControlDocType:
				break;
			case nccControlDocType:
				_controlDoc = [[BBSTBNCCDocument alloc] init];
			default:
				break;
		}
				
		// open the control file
		 loadedOK = (nil != _controlDoc) ? [_controlDoc openWithContentsOfURL:aDocUrl] : NO;
	}
	return loadedOK;
}

- (void)updateSkipDuration:(float)newDuration
{
	if(_smilDoc)
		[_smilDoc setChapterSkipDuration:QTMakeTimeWithTimeInterval((double)newDuration * (double)60)];
}

#pragma mark -
#pragma mark Play Methods

- (void)playAudio
{
	if(self.isPlaying == NO)
	{
		if(_smilDoc) // check if we have an audio file to play
		{
			[_smilDoc playAudio];
			self.isPlaying = YES;
		}
	}
	//else // isPlaying == YES
//	{
//		if(_smilDoc)
//		{
//			[_smilDoc pauseAudio];
//			self.isPlaying = NO;
//		}
//		
//	}
	
	//[self updateForPosInBook];
}

- (void)pauseAudio
{	
	if(_smilDoc)
	{
		[_smilDoc pauseAudio];
		self.isPlaying = NO;
	}
	
	
}

#pragma mark -
#pragma mark Navigation Methods

- (BOOL)nextSegment
{
	BOOL	fileDidUpdate = NO;
	if(YES == _hasControlFile)
	{	
		// get the filename of the next audio file to play from the ncx file
		[_controlDoc moveToNextSegment];

		if([_controlDoc currentSmilFilename])
		{	
			if(!_smilDoc)
				_smilDoc = [[BBSTBSMILDocument alloc] init];
			
			NSURL *smilUrl = [[NSURL alloc] initWithString:[_controlDoc currentSmilFilename] relativeToURL:_baseBookURL];
			fileDidUpdate = [_smilDoc openWithContentsOfURL:smilUrl];
		}
		
		//fileDidUpdate = [self updateAudioFile:[_controlDoc currentAudioFilename]];
	}
	
	return fileDidUpdate;
}

- (BOOL)nextSegmentOnLevel
{
	BOOL fileDidUpdate = NO;
	if(YES == _hasControlFile)
	{	
		// move to the next segment at the current level
		[_controlDoc setLoadFromCurrentLevel:YES];
		[_controlDoc moveToNextSegment];
		
		if([_controlDoc currentSmilFilename])
		{	
			NSURL *smilUrl = [[NSURL alloc] initWithString:[_controlDoc currentSmilFilename] relativeToURL:_baseBookURL];
			fileDidUpdate = [_smilDoc openWithContentsOfURL:smilUrl];
			
		}		
		// update the audio segment
		//fileDidUpdate = [self updateAudioFile:[_controlDoc currentAudioFilename]];
	}
			
	return fileDidUpdate;
}

- (BOOL)previousSegment 
{
	BOOL	fileDidUpdate = NO;
	if(YES == _hasControlFile)
	{	
		// move to the previous segment of the book
		[_controlDoc moveToPreviousSegment];

		if([_controlDoc currentSmilFilename])
		{	
			NSURL *smilUrl = [[NSURL alloc] initWithString:[_controlDoc currentSmilFilename] relativeToURL:_baseBookURL];
			fileDidUpdate = [_smilDoc openWithContentsOfURL:smilUrl];
			
		}
		// update the audio segment 
		//fileDidUpdate = [self updateAudioFile:[_controlDoc currentAudioFilename]];

	}
	
	return fileDidUpdate;
}

- (void)upOneLevel
{
	if(_hasControlFile)
	{
		[_controlDoc goUpALevel];
		
		//self.currentLevelString = [NSString stringWithFormat:@"%d",[_controlDoc currentLevel]];
	}
	
	//[self updateForPosInBook];
	
	if(speakUserLevelChange)
	{
		if(_smilDoc)
			[_smilDoc pauseAudio];
		[speechSynth startSpeakingString:[NSString stringWithFormat:NSLocalizedString(@"Level %d", @"VO level string"),[_controlDoc currentLevel]]];
	}
	else
	{
		// update the audio segment 
		//[self updateAudioFile:[_controlDoc currentAudioFilename]];
		//[_currentAudioFile play];
	}

}

- (void)downOneLevel
{
	// check that we have a control document to use
	if(_hasControlFile)
	{
		// check that we can go down a level
		if([_controlDoc canGoDownLevel])
		{	
			[_controlDoc goDownALevel];
			
			if([_controlDoc currentSmilFilename])
			{	
				NSURL *smilUrl = [[NSURL alloc] initWithString:[_controlDoc currentSmilFilename] relativeToURL:_baseBookURL];
				[_smilDoc openWithContentsOfURL:smilUrl];
			}
			
			//self.currentLevelString = [NSString stringWithFormat:@"%d",[_controlDoc currentLevel]];
			
		}

		//[self updateForPosInBook];
		
		if(speakUserLevelChange)
		{
			if(_smilDoc)
				[_smilDoc pauseAudio];
			[speechSynth startSpeakingString:[NSString stringWithFormat:NSLocalizedString(@"Level %d", @"VO level string"),[_controlDoc currentLevel]]];
		}
		else
		{
			// update the audio segment 
			//[self updateAudioFile:[_controlDoc currentAudioFilename]];
			if(_smilDoc)
				[_smilDoc playAudio];

		}
	}
	
}

- (void)nextChapter
{
	if(_smilDoc)
	{
		if([_smilDoc hasNextChapter])
			[_smilDoc nextChapter];

	}
	
//	BOOL segmentAvailable = NO;
//	QTTime timeOffset = QTZeroTime;
//	
//	
//	// check if we are moving to a chapter in the current audio file
//	if((_currentChapterIndex + 1) < _totalChapters)
//	{
//		_currentChapterIndex++;
//		[_currentAudioFile setCurrentTime:[_currentAudioFile startTimeOfChapter:_currentChapterIndex]];
//	}
//	else 
//	{
//		if(_hasControlFile)
//		segmentAvailable = [_controlDoc nextSegmentIsAvailable];
//		
//		if(segmentAvailable)
//		{
//			// the next chapter will be in the next audio file
//
//			// calculate the current time left in the currently playing file 
//			QTTime timeLeft = QTTimeDecrement([_currentAudioFile duration], [_currentAudioFile currentTime]);
//			
//			// decrement the skip duration by how much time is left
//			timeOffset = QTTimeDecrement(_skipDuration, timeLeft);
//
//			[self nextSegment];
//			// check if there is a segment available after the one we just moved to
//			segmentAvailable = [_controlDoc nextSegmentIsAvailable];
//	
//			//check if the segment loaded has a shorter duration than the offset
//			while((QTTimeCompare([_currentAudioFile duration], timeOffset) == NSOrderedAscending) && segmentAvailable)
//			{
//				if(segmentAvailable)
//				{
//					// the current duration is shorter so decrment the offset by the duration of the segment
//					timeOffset = QTTimeDecrement(timeOffset, [_currentAudioFile duration]);
//					
//					// now go to the next segment
//					[self nextSegment];
//					
//					// check if there is a segment available after the one we just moved to
//					segmentAvailable = [_controlDoc nextSegmentIsAvailable];					
//				}
//				else
//				{
//					timeOffset = QTZeroTime;
//				}
//			}
//			
//			// check that we dont have a zero time spec
//			if(QTTimeCompare(timeOffset, QTZeroTime) != NSOrderedSame)
//			{
//				[_currentAudioFile setCurrentTime:timeOffset];
//			}
//		}
//	}
//	
//	[_currentAudioFile play];
//	[self updateForPosInBook];
}

- (void)previousChapter
{
	if(_smilDoc)
	{
		if([_smilDoc hasPreviousChapter])
			[_smilDoc previousChapter];
	}
	
	
//	BOOL segmentAvailable = NO;
//	
//	if((_currentChapterIndex - 1) >= 0)
//	{
//		_currentChapterIndex--;
//		[_currentAudioFile setCurrentTime:[_currentAudioFile startTimeOfChapter:_currentChapterIndex]];
//	}
//	else
//	{
//		
//		if(_hasControlFile)
//			segmentAvailable = [_controlDoc PreviousSegmentIsAvailable] ;
//		
//		if(segmentAvailable)
//		{
//			// the previous chapter will be in the previous audio file
//
//			// calculate the offset from the currently playing file 
//			QTTime timeOffset = QTTimeDecrement(_skipDuration, [_currentAudioFile currentTime]);
//			
//			// set the flag for reverse chapter navigation
//			[_controlDoc setNavigateForChapters:YES]; 
//			
//			// go to the previous segment
//			[self previousSegment];
//			
//			// check if there is a segment available before one we just moved to
//			segmentAvailable = [_controlDoc PreviousSegmentIsAvailable];
//			
//			//check if the segment loaded has a shorter duration than the offset
//			while((QTTimeCompare([_currentAudioFile duration], timeOffset) == NSOrderedAscending) && segmentAvailable)
//			{
//				if(segmentAvailable)
//				{
//					// the current duration is shorter so decrment the offset by the duration of the segment
//					timeOffset = QTTimeDecrement(timeOffset, [_currentAudioFile duration]);
//					
//					// set the flag for reverse chapter navigation
//					[_controlDoc setNavigateForChapters:YES];
//					
//					// now go to the previous segment
//					[self previousSegment];
//					
//					segmentAvailable = [_controlDoc PreviousSegmentIsAvailable];
//				}
//				else
//				{
//					timeOffset = QTZeroTime;
//				}
//			}
//			
//			// check that we dont have a zero time spec
//			if(QTTimeCompare(timeOffset, QTZeroTime) != NSOrderedSame)
//			{
//				// check that the duration is greater than the offset
//				if(QTTimeCompare([_currentAudioFile duration], timeOffset) == NSOrderedDescending)
//				{
//					// calculate the offset into the new current file from the end of the audio
//					QTTime timeToSkipTo = QTTimeDecrement([_currentAudioFile duration], timeOffset);
//					
//					// set the now current segments time position
//					[_currentAudioFile setCurrentTime:timeToSkipTo];
//					
//				}
//			}
//		}
//	}
//	
//	[_currentAudioFile play];
//	[self updateForPosInBook];
	
}

- (void)gotoPage
{
	
}

#pragma mark -
#pragma mark Information Methods

- (void)showBookInfo
{
	// check if we should init the controller
	if(!_infoController)
	{
		if(_hasPackageFile)
			_infoController = [[BBSTBInfoController alloc] initWithMetadataNode:[_packageDoc metadataNode]];
		else if(_hasControlFile)
			_infoController = [[BBSTBInfoController alloc] initWithMetadataNode:[_controlDoc metadataNode]];
	}
	else
	{
		if(_hasPackageFile)
			[_infoController updateMetaInfoFromNode:[_packageDoc metadataNode]];
		else if(_hasControlFile)
			[_infoController updateMetaInfoFromNode:[_controlDoc metadataNode]];
	}
		
	if(_infoController)
		[_infoController displayInfoPanel];  	
		
}


- (NSDictionary *)getCurrentPageInfo
{
	return nil;
}

#pragma mark -
#pragma mark Overridden Attribute Methods

- (void)setPlaybackRate:(float)aRate
{
	if(_smilDoc)
		[_smilDoc setAudioPlayRate:aRate];
}

- (void)setPlaybackVolume:(float)aLevel
{
	if(_smilDoc)
		[_smilDoc setAudioVolume:aLevel];	
}

- (void)setPreferredVoice:(NSString *)aVoiceID;
{
	[speechSynth setVoice:aVoiceID];
	preferredVoice = aVoiceID;
}


- (void)setPlayPositionID:(NSString *)aPos
{
	if(_hasControlFile)
	{
		[_controlDoc setCurrentPositionID:aPos];
	}
}

- (NSString *)playPositionID
{
	if(_hasControlFile)
	{
		return [_controlDoc currentPositionID];
	}
	
	return nil;
}

- (NSString *)audioSegmentTimePosition
{
	NSString *nowTime = nil;
	if(_smilDoc)
		nowTime = [_smilDoc currentTimeString];
	
	return nowTime;
}

#pragma mark -
#pragma mark Private Methods


- (void)resetBook
{
	
	if(_hasControlFile) 
		[_controlDoc release];
	
	if(_hasPackageFile) 
		[_packageDoc release];
	
	if(_smilDoc) 
		[_smilDoc release];
	if(_textDoc) 
		[_textDoc release];
			
	bookIsAlreadyLoaded = NO;
	
	_hasPackageFile = NO;
	_hasControlFile = NO;

	bookIsAlreadyLoaded = NO;
	shouldJumpToTime = NO;

	_levelNavConMode = levelNavigationControlMode; // set the default level mode
	_maxLevelConMode = levelNavigationControlMode; // set the default max level mode. 
	_controlMode = UnknownBookType; // set the default control mode to unknown
	_mediaFormat = unknownMediaFormat; // set the default media format
	
	
	_hasPageNavigation = NO;
	_hasPhraseNavigation = NO;
	_hasSentenceNavigation = NO;
	_hasWordNavigation = NO;
	
	self.canPlay = NO;
	self.isPlaying = NO;
	
	[commonDoc resetForNewBook];

}


- (TalkingBookControlDocType)typeOfControlDoc:(NSURL *)aURL
{
	// set the default 
	TalkingBookControlDocType type = unknownControlDocType;
	
	NSString *filename = [aURL path];
	// check for an ncx extension
	if(YES == [[[filename pathExtension] lowercaseString] isEqualToString:@"ncx"])
	{
		type = ncxControlDocType;
	}
	// check for an ncc.html file
	else if(YES == [[[filename lastPathComponent] lowercaseString] isEqualToString:@"ncc.html"])
	{
		type = nccControlDocType;
	}
	
	return type;
}



- (void)errorDialogDidEnd
{
	[self resetBook];
}





/*
- (void)updateChapterIndex
{
	_currentChapterIndex = [_currentAudioFile chapterIndexForTime:[_currentAudioFile currentTime]];
	self.hasNextChapter = (_currentChapterIndex < (_totalChapters - 1)) ? YES : NO;
	self.hasPreviousChapter = (_currentChapterIndex > 0) ? YES : NO;
}
*/


/*
- (void)updateForPosInBook
{
	if(_hasControlFile)
	{	
		//self.currentSectionTitle = [_controlDoc segmentTitle];
		
		if(levelNavigationControlMode == _levelNavConMode)
			//self.currentLevelString = [NSString stringWithFormat:@"%d",[_controlDoc currentLevel]];
		self.hasLevelUp = (([_controlDoc canGoUpLevel]) || (_levelNavConMode > levelNavigationControlMode)) ? YES : NO;
		
		
		if ([_controlDoc canGoDownLevel]) // check regular level down first
			self.hasLevelDown = YES;
		else // We have reached the bottom of the current levels so check if we have other forms of nagigation below this
			self.hasLevelDown = (_levelNavConMode < _maxLevelConMode) ? YES : NO;
		
		self.hasNextSegment = [_controlDoc canGoNext];
		self.hasPreviousSegment = [_controlDoc canGoPrev];
		
		self.hasNextChapter = (_currentChapterIndex < _totalChapters) ? YES : ((_hasControlFile) ? [_controlDoc nextSegmentIsAvailable] : NO);
		self.hasPreviousChapter = (_currentChapterIndex > 0) ? YES : (_hasControlFile ? [_controlDoc PreviousSegmentIsAvailable] : NO);
		
		
		if(_hasPageNavigation)
		{
			//self. = [NSString stringWithFormat:NSLocalizedString(@"%d of %d", @"current page string"),[_controlDoc currentPageNumber],[_controlDoc totalPages]];
		}
	}
	
}
*/

#pragma mark -
#pragma mark Delegate Methods



- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success
{
	if(_mediaFormat <= AudioOnlyMediaFormat)
	{
		//[self updateAudioFile:[_controlDoc currentAudioFilename]];
		if(_smilDoc)
			[_smilDoc playAudio];
	}
	else
	{
		/// text only update calls here 
	}
	
}


@synthesize _controlDoc, _packageDoc, _textDoc, _smilDoc, commonDoc;
@synthesize speechSynth, preferredVoice;
@synthesize playbackRate, playbackVolume,  chapterSkipIncrement, maxLevels;
@synthesize _currentChapterIndex, _totalChapters;
@synthesize _controlMode;
@synthesize _baseBookURL, fullBookPath;
@synthesize bookIsAlreadyLoaded, speakUserLevelChange, overrideRecordedContent;
@synthesize playPositionID, audioSegmentTimePosition, shouldJumpToTime;

//bindings
@synthesize canPlay, isPlaying;

@end
