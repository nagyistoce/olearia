//
//  BBSTalkingBook.m
//  BBSTalkingBook
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
#import "BBSTBSMILDocument.h"
#import <QTKit/QTKit.h>

//@class BBSTBTextDocument;



@interface BBSTalkingBook ()


- (void)audioFileDidEnd:(NSNotification *)aNote;
- (void)setDisplayDefaults;

- (void)setupAudioNotifications;

- (TalkingBookControlDocType)typeOfControlDoc:(NSURL *)aURL;
- (void)setPreferredAudioAttributes;
- (BOOL)updateAudioFile:(NSString *)pathToFile;
- (void)updateForPosInBook;
- (void)updateChapterIndex;

- (BOOL)openControlDocument:(NSURL *)aDocUrl;
- (BOOL)openPackageDocument:(NSURL *)aDocUrl asType:(TalkingBookType)aType;

@property (readwrite, retain) NSSpeechSynthesizer *speechSynth;

@property (readwrite) NSInteger	maxLevels;
@property (readwrite) NSInteger totalChapters;

@property (readwrite) NSInteger currentChapterIndex;
@property (readwrite) TalkingBookType controlMode;
@property (readwrite) float		currentPlaybackRate;
@property (readwrite) float		currentPlaybackVolume;

@property (readwrite, retain) NSString *currentLevelString;

@property (readwrite, retain) QTMovie *currentAudioFile;

@property (readwrite, retain) BBSTBTextDocument	*textDoc;
@property (readwrite, retain) BBSTBSMILDocument *smilDoc;
@property (readwrite, retain) NSString *bookPath;
@property (readwrite, retain) NSString *segmentFilename;

@property (readwrite, retain) NSString	*bookTitle;
@property (readwrite, retain) NSString	*currentSectionTitle;
@property (readwrite, retain) NSString	*currentPageString;
@property (readwrite) BOOL		canPlay;
@property (readwrite) BOOL		isPlaying;
@property (readwrite) BOOL		hasNextChapter;
@property (readwrite) BOOL		hasPreviousChapter;
@property (readwrite) BOOL		hasLevelUp;
@property (readwrite) BOOL		hasLevelDown;
@property (readwrite) BOOL		hasNextSegment;
@property (readwrite) BOOL		hasPreviousSegment;

@end

@implementation BBSTalkingBook



- (id) init
{

	if (!(self=[super init])) return nil;
	
	hasPackageFile = NO;
	packageDoc = nil;
	hasControlFile = NO;
	controlDoc = nil;
	smilDoc = nil;
	textDoc = nil;
	levelNavConMode = levelNavigationControlMode; // set the default level mode
	maxLevelConMode = levelNavigationControlMode; // set the default max level mode. 
	controlMode = UnknownBookType; // set the default book type
	
	self.textDoc = nil;
	
	currentAudioFile = nil;
	
	totalChapters = 0;
	
	speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
		
	self.bookPath = [[NSString alloc] init];

	[self setDisplayDefaults];
	
	return self;
}


- (BOOL)openWithFile:(NSURL *)aURL
{
	TalkingBookNotificationCenter = [NSNotificationCenter defaultCenter];
	
	// set up the defaults for the bindings when opening the book
	[self setDisplayDefaults];
	
	hasPageNavigation = NO;
	hasPhraseNavigation = NO;
	hasSentenceNavigation = NO;
	hasWordNavigation = NO;
	
	if(hasControlFile) 
	{
		controlDoc = nil;
		hasControlFile = NO;
	}
	
	if(hasPackageFile) 
	{
		packageDoc = nil;
		hasPackageFile = NO;
	}
	
	if(smilDoc) smilDoc = nil;
	if(textDoc) textDoc = nil;
	
	BOOL fileOpenedOK = NO;
	
	// check for a OPF, NCX or NCC.html file first
	// get the parent folder path as a string
	
	self.bookPath = [[aURL path] stringByDeletingLastPathComponent];
	
	// when we do zip files we will check internally for one of the package or control files
	// also direct loading of .iso files would be good too
	
	NSURL *fileURL; 
	// check the extension first
	NSString *filename = [[NSString alloc] initWithString:[aURL path]];
	
	// do a sanity check to see if the user chose a NCX file and there 
	// is actually an OPF file available
	
	// currently this method assumes that the opf file has the same filename as the ncx file sans extension
	if([self typeOfControlDoc:aURL] == ncxControlDocType)
	{
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
			hasPackageFile = [self openPackageDocument:fileURL asType:DTB2005Type];
			if(hasPackageFile)
			{
				
				fileOpenedOK = hasPackageFile;
				// successfully opened the opf document so get the ncx filename from it
				NSString *ncxPathString = [[NSString alloc] initWithString:[bookPath stringByAppendingPathComponent:[packageDoc ncxFilename]]];
					
				// make a URL of the full path
				NSURL *ncxURL = [[NSURL alloc] initFileURLWithPath:ncxPathString];

				// open the control file
				hasControlFile = [self openControlDocument:ncxURL];
			}
			else // package file failed opening so drop back to the NCX file 
			{	
				// open the control file
				hasControlFile = [self openControlDocument:aURL];
				fileOpenedOK = hasControlFile;
			}

		}
		else // no opf file found -- this should never happen
			// dropback to the ncx file.
		{	
			hasControlFile = [self openControlDocument:aURL];
			fileOpenedOK = hasControlFile;
			
		}
	}
	else
	{	
		// we have chosen some other sort of file so open and process it.
		// check if its an OPF package file
		if([[filename pathExtension] compare:@"opf" options:NSCaseInsensitiveSearch] == NSOrderedSame)
		{
			hasPackageFile = [self openPackageDocument:aURL asType:DTB2005Type];
			if(hasPackageFile)
			{				
				fileOpenedOK = hasPackageFile;
				
				// get the book type so we know how to control acces to it
				self.controlMode = [packageDoc bookType];
				// successfully opened the opf document so get the ncx filename from it
				NSString *ncxPathString = [[NSString alloc] initWithString:[bookPath stringByAppendingPathComponent:[packageDoc ncxFilename]]];
						
				// make a URL of the full path
				NSURL *ncxURL = [[NSURL alloc] initFileURLWithPath:ncxPathString];
					
				hasControlFile = [self openControlDocument:ncxURL];
				
			}
			else
			{	// we failed to open the opf file 
				//fileOpenedOK = NO;
				// send an error to the user that the file couldnt be opened
			}
		}
		
		else //check for a control file
		{
			hasControlFile = [self openControlDocument:aURL];
			fileOpenedOK = hasControlFile;
		}
	}
	
	
	if (fileOpenedOK)
	{
		self.canPlay = YES;
		
		if(hasPackageFile)
		{
			// check that we have some sort of audio media in the file
			if((TextNCXMediaFormat != [packageDoc bookMediaFormat]))
				[self setupAudioNotifications];

			self.bookTitle = [packageDoc bookTitle];
			self.currentLevelString = [NSString stringWithFormat:@"%d",[controlDoc currentLevel]];
						
		}
		if(hasControlFile)
		{
			if((0 == [controlDoc totalPages]) && (0 == [controlDoc totalTargetPages]))
			{
				self.currentPageString = @"No Page Numbers";
			}
			else
			{
				self.currentPageString = @"To Be Set...";
				hasPageNavigation = YES;
				maxLevelConMode = pageNavigationControlMode;
			}

		}
		
		//setup the notifications for the changing values on the documents
		[self updateForPosInBook];		
		
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
				controlDoc = [[BBSTBNCXDocument alloc] init];
				break;
			case bookshareNcxControlDocType:
			case nccControlDocType:
			default:
				break;
		}
				
		// open the control file
		 loadedOK = (nil != controlDoc) ? [controlDoc openFileWithURL:aDocUrl] : NO;
	}
	return loadedOK;
}

- (BOOL)openPackageDocument:(NSURL *)aDocUrl asType:(TalkingBookType)aType
{
	BOOL loadedOK = NO;
	if(nil != aDocUrl)
	{
		switch (aType) 
		{
			case DTB2005Type:
			case DTB2002Type:
				packageDoc = [[BBSTBOPFDocument alloc] init];
				break;
			case BookshareType:
				
				break;
			default:
				break;
		}

		loadedOK = (nil != packageDoc) ? [packageDoc openFileWithURL:aDocUrl] : NO;
	}		
	
	return loadedOK;
}

#pragma mark -
#pragma mark Play Methods

- (void)playAudio
{
	if(isPlaying == NO)
	{
		if(currentAudioFile) // check if we have an audio file to play
		{
			//[self sendNotificationsForPosInBook];
			
			[currentAudioFile play];
			self.isPlaying = YES;
		}
	}
	else // isPlaying == YES
	{
		//[self sendNotificationsForPosInBook];
		[currentAudioFile play];
		self.isPlaying = YES;
	}
	
	[self updateForPosInBook];
}

- (void)pauseAudio
{	
	[currentAudioFile stop];
	self.isPlaying = NO;
	
}

#pragma mark -
#pragma mark Navigation Methods

/*
- (BOOL)hasNextFile
{
	BOOL isAFileAfterThis = NO;
	
	if(hasControlFile)
		isAFileAfterThis = [controlDoc canGoNext]; 
	
	return isAFileAfterThis;
}

- (BOOL)hasPrevFile
{
	BOOL isAFileBeforeThis = NO;

	if(hasControlFile)
		isAFileBeforeThis = [controlDoc canGoPrev];
	
	return isAFileBeforeThis;
}
*/

- (BOOL)nextSegment
{
	NSString *audioSegmentFilename;
	BOOL	fileDidUpdate = NO;
	if(YES == hasControlFile)
	{	
		// get the filename of the next audio file to play from the ncx file
		audioSegmentFilename = [controlDoc nextSegmentAudioFilePath];
		self.currentSectionTitle = [controlDoc segmentTitle];
		self.currentLevelString = [NSString stringWithFormat:@"%d",[controlDoc currentLevel]];
		
	}
	
	fileDidUpdate = [self updateAudioFile:audioSegmentFilename];
	
	return fileDidUpdate;
}

- (BOOL)nextSegmentOnLevel
{
	NSString *audioSegmentFilename = nil;
	BOOL fileDidUpdate = NO;
	if(YES == hasControlFile)
	{	
		// get the filename of the next file to play from the ncx file
		[controlDoc setLoadFromCurrentLevel:YES];
		audioSegmentFilename = [controlDoc nextSegmentAudioFilePath];
	}
	
	fileDidUpdate = [self updateAudioFile:audioSegmentFilename];
	
	return fileDidUpdate;
}

- (BOOL)previousSegment 
{
	NSString *audioSegmentFilename = nil;
	BOOL	fileDidUpdate = NO;
	if(YES == hasControlFile)
	{	
		// get the filename of the next audio file to play from the ncx file
		audioSegmentFilename = [controlDoc previousSegmentAudioFilePath];
	}
	
	fileDidUpdate = [self updateAudioFile:audioSegmentFilename];
	
	return fileDidUpdate;
}

- (void)upOneLevel
{
	if(hasControlFile)
	{
		NSString *audioFilePath = [controlDoc goUpALevel];
		[self updateAudioFile:audioFilePath];
		
		
		self.currentLevelString = [NSString stringWithFormat:@"%d",[controlDoc currentLevel]];
		
	}
		
}

- (void)downOneLevel
{
	if(hasControlFile)
	{
		if([controlDoc canGoDownLevel])
		{	NSString *audioFilePath = [controlDoc goDownALevel];
			[self updateAudioFile:audioFilePath];
			self.currentLevelString = [NSString stringWithFormat:@"%d",[controlDoc currentLevel]];
		}
		else if(hasPageNavigation)
		{
			
		}

	
		
	}
	
}

- (BOOL)hasChapters
{
	return [currentAudioFile hasChapters];
}

- (void)nextChapter
{
	if((currentChapterIndex + 1) < totalChapters)
	{
		self.currentChapterIndex++;
		[currentAudioFile setCurrentTime:[currentAudioFile startTimeOfChapter:currentChapterIndex]];
		self.hasNextChapter = (currentChapterIndex < (totalChapters - 1)) ? YES : NO;
		self.hasPreviousChapter = (currentChapterIndex > 0) ? YES : NO;

	}
}

- (void)previousChapter
{
	if((currentChapterIndex - 1) >= 0)
	{
		self.currentChapterIndex--;
		[currentAudioFile setCurrentTime:[currentAudioFile startTimeOfChapter:currentChapterIndex]];
		self.hasNextChapter = (currentChapterIndex < (totalChapters - 1)) ? YES : NO;
		self.hasPreviousChapter = (currentChapterIndex > 0) ? YES : NO;

	}
}

- (void)gotoPage
{
	
}

#pragma mark -
#pragma mark Information Methods

- (NSDictionary *)getBookInfo
{

	return nil;
}


- (NSDictionary *)getCurrentPageInfo
{
	return nil;
}

#pragma mark -
#pragma mark Attribute Methods

- (void)setPlaybackRate:(float)aRate
{
	if(aRate != self.currentPlaybackRate)
	{
		self.currentPlaybackRate = aRate;
		[currentAudioFile setRate:currentPlaybackRate];
	}
}

- (void)setVolumeLevel:(float)aLevel
{
	if(aLevel != self.currentPlaybackVolume)
	{
		self.currentPlaybackVolume = aLevel;
		[currentAudioFile setVolume:currentPlaybackVolume];
	}
}

- (void)setPlaybackVoice:(NSString *)aVoiceID;
{
	[speechSynth setVoice:aVoiceID];

}


#pragma mark -
#pragma mark Private Methods

- (void)setDisplayDefaults
{
	self.bookTitle = @"Olearia";
	self.currentLevelString = @"";
	self.currentPageString = @"";
	self.canPlay = NO;
	self.isPlaying = NO;
	self.hasNextChapter = NO;
	self.hasPreviousChapter = NO;
	self.hasLevelUp = NO;
	self.hasLevelDown = NO;
	self.hasNextSegment = NO;
	self.hasPreviousSegment = NO;
	
}

/*
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	
	if(hasPackageFile || hasControlFile)
	{
		if([keyPath isEqualToString:@"currentLevel"])
		{	
			self.hasLevelUp = (([controlDoc canGoUpLevel]) || (levelNavConMode > levelNavigationControlMode)) ? YES : NO;
			self.hasLevelDown = (([controlDoc canGoDownLevel]) || (levelNavConMode < wordNavigationControlMode)) ? YES : NO;
		}
		//if([keyPath isEqualToString:@"sect
	}
		   
}
*/
 
- (TalkingBookControlDocType)typeOfControlDoc:(NSURL *)aURL
{
	// set the default 
	TalkingBookControlDocType type = unknownControlDocType;
	
	NSString *filename = [aURL path];
	// check for an ncx extension
	if([[filename pathExtension] compare:@"ncx" options:NSCaseInsensitiveSearch] == NSOrderedSame)
	{
		type = ncxControlDocType;
	}
	// check for an ncc.html file
	else if([[filename lastPathComponent] compare:@"ncc.html" options:NSCaseInsensitiveSearch] == NSOrderedSame)
	{
		type = nccControlDocType;
	}
	
	return type;
}


- (BOOL)updateAudioFile:(NSString *)pathToFile
{
	NSError *theError = nil;
	BOOL loadedOK = YES;
	
	[currentAudioFile stop]; // pause the playback if there is any currently playing

	// open a temporary movie style file so we can extract the audio track from it
	QTMovie *audioOnlyMovie = [[QTMovie alloc] initWithFile:pathToFile error:&theError];
	
	if(audioOnlyMovie != nil)
	{
		// init the writable movie file 
		currentAudioFile = [[QTMovie alloc] initWithQuickTimeMovie:[audioOnlyMovie quickTimeMovie] disposeWhenDone:YES error:&theError];
		if(currentAudioFile != nil)
		{
			// make the file editable and set the timescale for it to that of the audio track
			[currentAudioFile setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
			[currentAudioFile setAttribute:[NSNumber numberWithLong:1000] forKey:QTMovieTimeScaleAttribute];
			[self setPreferredAudioAttributes];
			if(hasControlFile)
			{
				// populate the chapters array with a default timescale of 1ms
				NSArray *chaptersArray = [NSArray arrayWithArray:[controlDoc chaptersForSegmentWithTimescale:(long)1000]];
				if([chaptersArray count] > 0) // check we have some chapters to add
				{
					// get the track the chapter will be associated with
					QTTrack *musicTrack = [[currentAudioFile tracksOfMediaType:QTMediaTypeSound] objectAtIndex:0];
					currentChapterIndex = -1;
					NSDictionary *trackDict = [NSDictionary dictionaryWithObjectsAndKeys:musicTrack, QTMovieChapterTargetTrackAttribute,nil];
					// add the chapters track to the movie data
					// dont check for errors because it doesnt really matter if we cant get chapter markers
					NSError *chaptersError = nil;
					[currentAudioFile addChapters:chaptersArray withAttributes:trackDict error:&chaptersError];
					if(chaptersError == nil) // we successfully added the chapters to the file
					{
						totalChapters = [currentAudioFile chapterCount];
						currentChapterIndex = 0;
					}
				}
				[self updateForPosInBook];
			}
		}
		else
		{
			goto BAIL;
		}		
	}
	else
	{
		goto BAIL;
	}
	
	if((currentAudioFile == nil) || (loadedOK == NO))
		return NO;
	
	
	
	
	return YES;
BAIL:
{
	NSAlert *theAlert = [NSAlert alertWithError:theError];
	[theAlert setAlertStyle:NSWarningAlertStyle];
	[theAlert runModal];
	loadedOK = NO;
	return NO;
}

}

- (void)setPreferredAudioAttributes
{
	[currentAudioFile setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieRateChangesPreservePitchAttribute];
	[currentAudioFile setAttribute:[NSNumber numberWithFloat:self.currentPlaybackVolume] forKey:QTMoviePreferredVolumeAttribute];
	[currentAudioFile setVolume:currentPlaybackVolume];
	[currentAudioFile setAttribute:[NSNumber numberWithFloat:self.currentPlaybackRate] forKey:QTMoviePreferredRateAttribute];
	[currentAudioFile setDelegate:self];
	
}


- (void)setupAudioNotifications
{
	// start watching for notifications for reaching the end of the audio file
	[TalkingBookNotificationCenter addObserver:self 
									  selector:@selector(audioFileDidEnd:) 
										  name:QTMovieDidEndNotification 
										object:self.currentAudioFile];

	// watch for chapter change notifications
	[TalkingBookNotificationCenter addObserver:self 
									  selector:@selector(updateChapterIndex) 
										  name:QTMovieChapterDidChangeNotification 
										object:self.currentAudioFile];
}

- (void)updateChapterIndex
{
	currentChapterIndex = [currentAudioFile chapterIndexForTime:[currentAudioFile currentTime]];
}


- (void)updateForPosInBook
{
	if(hasControlFile)
	{	
		self.currentSectionTitle = [controlDoc segmentTitle];
		self.hasLevelUp = (([controlDoc canGoUpLevel]) || (levelNavConMode > levelNavigationControlMode)) ? YES : NO;
		if ([controlDoc canGoDownLevel]) // check regular level down first
			self.hasLevelDown = YES;
		else // We have reached the bottom of the current levels so check if we have other forms of nagigation below this
			self.hasLevelDown = (levelNavConMode < maxLevelConMode) ? YES : NO;
		self.hasNextSegment = [controlDoc canGoNext];
		self.hasPreviousSegment = [controlDoc canGoPrev];
		self.hasNextChapter = (currentChapterIndex < (totalChapters - 1)) ? YES : NO;
		self.hasPreviousChapter = (currentChapterIndex > 0) ? YES : NO;
		
	}
	
}

#pragma mark -
#pragma mark Notifications

- (void)audioFileDidEnd:(NSNotification *)aNote
{
	
	NSLog(@"file did end notification %@",aNote);
	
	if(YES == [self nextSegment])
		[self playAudio];
	
			 
}

#pragma mark -
#pragma mark Synthesized iVars

@synthesize controlDoc,packageDoc;

@synthesize speechSynth, preferredVoice;

@synthesize currentPlaybackRate, currentPlaybackVolume;
@synthesize maxLevels, currentPageIndex, currentChapterIndex, totalChapters;
@synthesize controlMode;
@synthesize textDoc, smilDoc;
@synthesize bookPath, segmentFilename;

@synthesize currentAudioFile;

// bindings related
@synthesize bookTitle, currentSectionTitle;
@synthesize currentLevelString, currentPageString;
@synthesize canPlay, isPlaying;
@synthesize hasNextChapter, hasPreviousChapter;
@synthesize hasLevelUp, hasLevelDown;
@synthesize hasNextSegment, hasPreviousSegment;

@end
