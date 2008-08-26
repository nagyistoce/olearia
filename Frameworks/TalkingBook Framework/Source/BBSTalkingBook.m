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

NSString * const BBSTBPlaybackVolume = @"TBPlaybackVolume";
NSString * const BBSTBPlaybackRate = @"TBPlaybackRate";
NSString * const BBSTBPlaybackVoice = @"TBPlaybackVoice"; 
NSString * const BBSTBUseVoiceForPlayback = @"TBUseVoiceForPlayback";

@interface BBSTalkingBook ()

@property (readwrite, retain) NSSpeechSynthesizer *speechSynth;

@property (readwrite,retain)	NSString	*bookTitle;
@property (readwrite,retain) NSString	*sectionTitle;

@property (readwrite) NSInteger	maxLevels;
@property (readwrite) NSInteger totalChapters;

@property (readwrite) NSInteger currentChapterIndex;
@property (readwrite) TalkingBookType controlMode;
@property (readwrite) float		currentPlaybackRate;
@property (readwrite) float		currentPlaybackVolume;

@property (readwrite)		NSInteger	currentLevelIndex;
@property (readwrite, retain) NSString *currentLevelString;

@property (readwrite, retain) QTMovie *currentAudioFile;

@property (readwrite, retain) BBSTBTextDocument	*textDoc;
@property (readwrite, retain) BBSTBSMILDocument *smilDoc;
@property (readwrite, retain) NSString *bookPath;
@property (readwrite, retain) NSString *segmentFilename;

@property (readwrite) BOOL		canPlay;
@property (readwrite) BOOL		isPlaying;
@property (readwrite) BOOL		hasNextChapter;
@property (readwrite) BOOL		hasPreviousChapter;
@property (readwrite) BOOL		hasLevelUp;
@property (readwrite) BOOL		hasLevelDown;
@property (readwrite) BOOL		hasNextSegment;
@property (readwrite) BOOL		hasPreviousSegment;

- (void)sendChapterNotifications;

- (void)audioFileDidEnd:(NSNotification *)aNote;

- (void)setupAudioNotifications;
- (BOOL)hasSubLevel;
- (BOOL)hasParentLevel;

- (TalkingBookControlDocType)typeOfControlDoc:(NSURL *)aURL;
- (void)setPreferredAudioAttributes;
- (BOOL)updateAudioFile:(NSString *)pathToFile;


@end

@implementation BBSTalkingBook

@synthesize controlDoc,packageDoc;

@synthesize speechSynth, preferredVoice;

@synthesize bookTitle, sectionTitle; 
@synthesize currentPlaybackRate, currentPlaybackVolume;
@synthesize maxLevels, currentPageIndex, currentChapterIndex, totalChapters;
@synthesize controlMode;
@synthesize textDoc, smilDoc;
@synthesize bookPath, segmentFilename;
@synthesize currentLevelString;

@synthesize currentAudioFile;
@synthesize currentLevelIndex;

@synthesize canPlay, isPlaying;
@synthesize hasNextChapter, hasPreviousChapter;
@synthesize hasLevelUp, hasLevelDown;
@synthesize hasNextSegment, hasPreviousSegment;

+ (void)initialize
{
	// Create a dictionary
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
    // Put defaults in the dictionary
	[defaultValues setValue:[NSNumber numberWithFloat:1.0] forKey:BBSTBPlaybackVolume];
	[defaultValues setValue:[NSNumber numberWithFloat:1.0] forKey:BBSTBPlaybackRate];
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:BBSTBUseVoiceForPlayback];
	[defaultValues setObject:[NSSpeechSynthesizer defaultVoice] forKey:BBSTBPlaybackVoice];
    
	// Register the dictionary of defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
}


- (id) init
{

	if (!(self=[super init])) return nil;
	
	
	
	hasPackageFile = NO;
	hasControlFile = NO;
	navigationMode = levelNavigationMode;
	controlMode = UnknownBookType;
	
	self.textDoc = nil;
	
	currentAudioFile = nil;
	
	totalChapters = 0;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	self.currentPlaybackVolume = [defaults floatForKey:BBSTBPlaybackVolume]; 
	self.currentPlaybackRate = [defaults floatForKey:BBSTBPlaybackRate];
	speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:[defaults valueForKey:BBSTBPlaybackVoice]];
	
	
	self.bookPath = [[NSString alloc] init];
	
	return self;
}


- (BOOL)openWithFile:(NSURL *)aURL
{
	TalkingBookNotificationCenter = [NSNotificationCenter defaultCenter];

	// set up the defaults for the book
	self.canPlay = NO;
	self.isPlaying = NO;
	self.hasNextChapter = NO;
	self.hasPreviousChapter = NO;
	self.hasLevelUp = NO;
	self.hasLevelDown = NO;
	self.hasNextSegment = NO;
	self.hasPreviousSegment = NO;
	
	self.bookTitle = [[NSString alloc] initWithString:@"Olearia"];
	self.currentLevelString = @"";
	
	if(controlDoc) controlDoc = nil;
	if(packageDoc) packageDoc = nil;
		
		// set the check flags
	hasPackageFile = NO;
	hasControlFile = NO;
		BOOL fileOpenedOK = NO;
	
		// check for a OPF, NCX or NCC.html file first
		// get the parent folder path as a string
	
		self.bookPath = [[aURL path] stringByDeletingLastPathComponent];
	
		// when we do zip files we will check internally for one of the package or control files
	
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
				packageDoc = [[BBSTBOPFDocument alloc] init];
				if(nil != packageDoc)
				{
					hasPackageFile = [packageDoc openFileWithURL:fileURL];
					fileOpenedOK = hasPackageFile;
					if(hasPackageFile)
					{	
						controlDoc = [[BBSTBNCXDocument alloc] init];
						if(nil != controlDoc)
						{
							// successfully opened the opf document so get the ncx filename from it
							NSString *ncxPathString = [[NSString alloc] initWithString:[bookPath stringByAppendingPathComponent:[packageDoc ncxFilename]]];
							
							// make a URL of the full path
							NSURL *ncxURL = [[NSURL alloc] initFileURLWithPath:ncxPathString];
							
							// open the ncx control file
							hasControlFile = [controlDoc openFileWithURL:ncxURL];
						}
					}
					else // package file failed opening so drop back to the NCX file 
					{	
						controlDoc = [[BBSTBNCXDocument alloc] init];
						if(nil != controlDoc)
						{
							// open the ncx control file
							hasControlFile = [controlDoc openFileWithURL:aURL];
							fileOpenedOK = hasControlFile;
						}
					}
				}
			}
			else // no opf file found -- this should never happen
			{	
				controlDoc = [[BBSTBNCXDocument alloc] init];
				if(nil != controlDoc)
				{
					// open the ncx control file
					hasControlFile = [controlDoc openFileWithURL:aURL];
					fileOpenedOK = hasControlFile;
				}
			}
		}
		else
		{	
			// we have chosen some other sort of file so open and process it.
			// check if its an OPF package file
			if([[filename pathExtension] compare:@"opf" options:NSCaseInsensitiveSearch] == NSOrderedSame)
			{
				self.packageDoc = [[BBSTBOPFDocument alloc] init];
				if(nil != packageDoc)
				{
					hasPackageFile = [packageDoc openFileWithURL:aURL];
					fileOpenedOK = hasPackageFile;
					
					if(YES == hasPackageFile)
					{	
						// get the book type so we know how to control acces to it
						self.controlMode = [packageDoc bookType];
						
						controlDoc = [[BBSTBNCXDocument alloc] init];
						if(nil != controlDoc)
						{
							// successfully opened the opf document so get the ncx filename from it
							NSString *ncxPathString = [[NSString alloc] initWithString:[bookPath stringByAppendingPathComponent:[packageDoc ncxFilename]]];
							
							// make a URL of the full path
							NSURL *ncxURL = [[NSURL alloc] initFileURLWithPath:ncxPathString];
							// open the ncx file
							hasControlFile = [controlDoc openFileWithURL:ncxURL];
						}
					}
				}
				else
				{	// we failed to open the opf file 
					//fileOpenedOK = NO;
					// send an error to the user that the file couldnt be opened
				}
			}
			
			else //check for NCX control file
			{
				if([self typeOfControlDoc:aURL] == ncxControlDocType)
				{
					controlDoc = [[BBSTBNCXDocument alloc] init];
					if(nil != controlDoc)
					{	
						hasControlFile = [controlDoc openFileWithURL:aURL];
						fileOpenedOK = hasControlFile;
					}
					else
					{	
						// send a message to the user that the file did not load correctly
					}
				}
				else // check for an ncc.html file
					if([self typeOfControlDoc:aURL] == nccControlDocType)
					{
						// open the ncc.html control file
					}
			}
		}
		
		
		if (fileOpenedOK)
		{
			self.canPlay = YES;
			//setup the notifications for the changing values on the documents
			if(hasPackageFile)
			{
				// check that we have some sort of audio media in the file
				if((TextNCXMediaFormat != [packageDoc bookMediaFormat]))
					[self setupAudioNotifications];
				[packageDoc addObserver:self forKeyPath:@"bookTitle" options:NSKeyValueObservingOptionNew context:nil];
				self.bookTitle = [packageDoc bookTitle];
			}
			if(hasControlFile)
			{
				if(!hasPackageFile)
				{
					// use the control document for title etc. 
				}
				[controlDoc addObserver:self forKeyPath:@"segmentTitle" options:NSKeyValueObservingOptionNew context:nil];
				self.sectionTitle = [controlDoc segmentTitle];
				[controlDoc addObserver:self forKeyPath:@"currentLevel" options:NSKeyValueObservingOptionNew context:nil];
				self.currentLevelString = [NSString stringWithFormat:@"%d",[controlDoc currentLevel]];
				
				// setup audionotifications as per the media format of the ncx file.
			}
			
			
		}
		

	return fileOpenedOK;

}



#pragma mark -
#pragma mark Play Methods

- (void)playAudio
{
	if(isPlaying == NO)
	{
		if(currentAudioFile) // check if we have an audio file to play
		{
			[self sendNotificationsForPosInBook];
			[currentAudioFile play];
			self.isPlaying = YES;
		}
	}
	else // isPlaying == YES
	{
		[self sendNotificationsForPosInBook];
		[currentAudioFile play];
		self.isPlaying = YES;
	}
}

- (void)pauseAudio
{	
	[currentAudioFile stop];
	self.isPlaying = NO;
	
}

#pragma mark -
#pragma mark Navigation Methods

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


- (BOOL)nextSegment
{
	NSString *audioSegmentFilename;
	BOOL	fileDidUpdate = NO;
	if(YES == hasControlFile)
	{	
		// get the filename of the next audio file to play from the ncx file
		audioSegmentFilename = [controlDoc nextSegmentAudioFilePath];
		self.sectionTitle = [controlDoc segmentTitle];
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
		
		//self.currentLevelIndex = [controlDoc currentLevel];
		self.currentLevelString = [NSString stringWithFormat:@"%d",[controlDoc currentLevel]];
		
	}
		
}

- (void)downOneLevel
{
	if(hasControlFile)
	{
		NSString *audioFilePath = [controlDoc goDownALevel];
		[self updateAudioFile:audioFilePath];
		//[self willChangeValueForKey:@"currentLevelIndex"];
		self.currentLevelIndex = [controlDoc currentLevel];
		self.currentLevelString = [NSString stringWithFormat:@"%d",currentLevelIndex];

		NSLog(@"current level is %d",currentLevelIndex);
		
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
		currentChapterIndex++;
		[currentAudioFile setCurrentTime:[currentAudioFile startTimeOfChapter:currentChapterIndex]];

	}
}

- (void)previousChapter
{
	if((currentChapterIndex - 1) >= 0)
	{
		currentChapterIndex--;
		[currentAudioFile setCurrentTime:[currentAudioFile startTimeOfChapter:currentChapterIndex]];

	}
}

- (void)gotoPage
{
	
}

#pragma mark -
#pragma mark Information Methods
/*
- (NSInteger)currentLevelIndex
{
	NSInteger level;
	if(hasControlFile)
	{	
		 
		level = [ncxDoc currentLevel];
		[self willChangeValueForKey:@"currentLevelIndex"];
		self.currentLevelIndex = level;
		[self didChangeValueForKey:@"currentLevelIndex"];
	}
	
	return level;
}

*/
- (NSDictionary *)getBookInfo
{
	
}


- (NSDictionary *)getCurrentPageInfo
{
	
}
#pragma mark -
#pragma mark Attribute Methods

- (void)setNewPlaybackRate:(float)aRate
{
	if(aRate != self.currentPlaybackRate)
	{
		self.currentPlaybackRate = aRate;
		[currentAudioFile setRate:currentPlaybackRate];
	}
}

- (void)setNewVolumeLevel:(float)aLevel
{
	if(aLevel != self.currentPlaybackVolume)
	{
		self.currentPlaybackVolume = aLevel;
		[currentAudioFile setVolume:currentPlaybackVolume];
	}
}
/*
- (void)setCurrentLevelIndex:(NSInteger)anIndex
{
	currentLevelIndex = anIndex;
	self.currentLevelString = [NSString stringWithFormat:@"%d",anIndex]; 
}
*/

#pragma mark -
#pragma mark Private Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(hasPackageFile || hasControlFile)
	{
		if([keyPath isEqualToString:@"bookTitle"])
			self.bookTitle = ((hasPackageFile) ? [packageDoc bookTitle] : [controlDoc bookTitle]);
		if([keyPath isEqualToString:@"currentLevel"])
			self.currentLevelString = [NSString stringWithFormat:@"%d",[controlDoc currentLevel]];
		//if([keyPath isEqualToString:@"sect
	}
		   
}

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
						[self sendChapterNotifications];
					}
				}
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

- (BOOL)hasSubLevel
{
	// check the type of control file  
	//if(controlMode < DTBPre2002Type)
	return (hasControlFile) ? [controlDoc canGoDownLevel] : NO;
}

- (BOOL)hasParentLevel
{
	return (hasControlFile) ? [controlDoc canGoUpLevel] : NO; // add opf check maybe?
}
	

- (void)setPreferredAudioAttributes
{
	//NSLog(@" current Vol : %f    Current Rate : %f",currentPlaybackVolume,currentPlaybackRate);
	
	//[currentAudioFile setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieRateChangesPreservePitchAttribute];
	
	[currentAudioFile setAttribute:[NSNumber numberWithFloat:self.currentPlaybackVolume] forKey:QTMoviePreferredVolumeAttribute];
	[currentAudioFile setVolume:currentPlaybackVolume];
	[currentAudioFile setAttribute:[NSNumber numberWithFloat:self.currentPlaybackRate] forKey:QTMoviePreferredRateAttribute];
	[currentAudioFile setDelegate:self];
	
}


/*
- (BOOL)openOpfDocument:(NSURL *)fileURL
{
	BOOL fileOK = NO;
	
	opfDoc = [[BBSTBOPFDocument alloc] initWithURL:fileURL];
	if(opfDoc != nil)
		fileOK = YES;
	
	return fileOK;

}
*/
/*
- (BOOL)openNcxDocument:(NSURL *)fileURL
{
	BOOL fileOK = NO;
	
	ncxDoc = [[BBSTBNCXDocument alloc] initWithURL:fileURL];
	if(opfDoc != nil)
		fileOK = YES;
	
	return fileOK;
}
*/
- (void)setupAudioNotifications
{
	[TalkingBookNotificationCenter addObserver:self 
									  selector:@selector(audioFileDidEnd:) 
										  name:QTMovieDidEndNotification 
										object:self.currentAudioFile];

	[TalkingBookNotificationCenter addObserver:self 
									  selector:@selector(sendChapterNotifications) 
										  name:QTMovieChapterDidChangeNotification 
										object:self.currentAudioFile];
}

- (void)sendChapterNotifications
{
	//BOOL aState;
	//NSMutableDictionary *stateDict = [[NSMutableDictionary alloc] init];
	
	currentChapterIndex = [currentAudioFile chapterIndexForTime:[currentAudioFile currentTime]];
	/*	
	aState = (currentChapterIndex < (totalChapters - 1)) ? YES : NO;
	[stateDict setObject:[NSNumber numberWithBool:aState] forKey:@"state"];
	[TalkingBookNotificationCenter postNotificationName:BBSTBhasNextChapterNotification object:self userInfo:stateDict];
		
	aState = (currentChapterIndex > 0) ? YES : NO;
	[stateDict setObject:[NSNumber numberWithBool:aState] forKey:@"state"];
	[TalkingBookNotificationCenter postNotificationName:BBSTBhasPrevChapterNotification object:self userInfo:stateDict];

	 */
	 
}


- (void)sendNotificationsForPosInBook
{
	/*
	BOOL aState;
	NSMutableDictionary *stateDict = [[NSMutableDictionary alloc] init];
	
	aState = [self hasNextFile];
	[stateDict setObject:[NSNumber numberWithBool:aState] forKey:@"state"];
	[TalkingBookNotificationCenter postNotificationName:BBSTBCanGoNextFileNotification object:self  userInfo:stateDict];
	
	aState = [self hasPrevFile];
	[stateDict setObject:[NSNumber numberWithBool:aState] forKey:@"state"];
	[TalkingBookNotificationCenter postNotificationName:BBSTBCanGoPrevFileNotification object:self userInfo:stateDict];
	
	aState = [self hasParentLevel];
	[stateDict setObject:[NSNumber numberWithBool:aState] forKey:@"state"];
	[TalkingBookNotificationCenter postNotificationName:BBSTBCanGoUpLevelNotification object:self userInfo:stateDict];
	
	aState = [self hasSubLevel];
	[stateDict setObject:[NSNumber numberWithBool:aState] forKey:@"state"];
	[TalkingBookNotificationCenter postNotificationName:BBSTBCanGoDownLevelNotification object:self userInfo:stateDict];
	*/
	
	
	if([currentAudioFile hasChapters])
	{
		[self sendChapterNotifications];
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

 @end
