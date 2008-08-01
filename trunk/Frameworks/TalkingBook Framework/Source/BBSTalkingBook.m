//
//  BBSTalkingBook.m
//  BBSTalkingBook
//
//  Created by Kieren Eaton on 5/05/08.
//  BrainBender Software. 
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
#import "BBSTBOPFDocument.h"
#import "BBSTBNCXDocument.h"
#import "BBSTBSMILDocument.h"
#import <QTKit/QTKit.h>

//@class BBSTBTextDocument;

NSString * const BBSTBCanGoNextFileNotification = @"BBSTBCanGoNextFile";
NSString * const BBSTBCanGoPrevFileNotification = @"BBSTBCanGoPrevFile";
NSString * const BBSTBCanGoUpLevelNotification = @"BBSTBCanGoUpLevel";
NSString * const BBSTBCanGoDownLevelNotification = @"BBSTBCanGoDownLevel";
NSString * const BBSTBhasNextChapterNotification = @"BBSTBhasNextChapter";
NSString * const BBSTBhasPrevChapterNotification = @"BBSTBhasPrevChapter";

@interface BBSTalkingBook ()

@property (readwrite) NSInteger	maxLevels;
@property (readwrite) NSInteger totalChapters;
@property (readwrite) NSInteger	currentLevelIndex;
@property (readwrite) NSInteger	currentPageIndex;
@property (readwrite) NSInteger currentChapterIndex;
@property (readwrite) float		currentPlaybackRate;
@property (readwrite) float		currentPlaybackVolume;

@property (readwrite, retain) QTMovie *currentAudioFile;

@property (readwrite, retain) BBSTBTextDocument	*textDoc;
@property (readwrite, retain) BBSTBSMILDocument *smilDoc;
@property (readwrite, retain) NSString *bookPath;
@property (readwrite, retain) NSString *segmentFilename;

- (void)sendChapterNotifications;
- (BOOL)openOpfDocument:(NSURL *)fileURL;
- (BOOL)openNcxDocument:(NSURL *)fileURL;

- (void)audioFileDidEnd:(NSNotification *)aNote;

- (void)setupAudioNotifications;
- (BOOL)hasSubLevel;
- (BOOL)hasParentLevel;

- (void)setPreferredAudioAttributes;
- (BOOL)updateAudioFile:(NSString *)pathToFile;


@end

@implementation BBSTalkingBook

@dynamic bookTitle, sectionTitle; 
@synthesize currentPlaybackRate, currentPlaybackVolume;
@synthesize maxLevels, currentPageIndex, currentLevelIndex, currentChapterIndex, totalChapters;
@synthesize opfDoc, ncxDoc, textDoc, smilDoc;
@synthesize bookPath, segmentFilename;

@synthesize currentAudioFile;

- (id)initWithFile:(NSURL *)aURL
{
	self = [super init];
	if (self != nil) 
	{
		isPlaying = NO;
		hasOPFFile = NO;
		hasNCXFile = NO;
		self.opfDoc = nil;
		self.ncxDoc = nil;
		self.textDoc = nil;
		currentAudioFile = nil;
		currentPlaybackVolume = 1.0; 
		currentPlaybackRate = 1.0;
		totalChapters = 0;
		
		TalkingBookNotificationCenter = [NSNotificationCenter defaultCenter];
		
		// check for a OPF, NCX or NCC.html file first
		BOOL fileOpenedOK = NO;	
		
		// get the parent folder path as a string
		self.bookPath = [[aURL path] stringByDeletingLastPathComponent];
		
		NSURL *fileURL; 
		
		// do a sanity check to see if the user chose a NCX file and there 
		// is actually an OPF file available
		// check the extension first
		NSString *filename = [[NSString alloc] initWithString:[aURL path]];
		if([[filename pathExtension] compare:@"ncx" options:NSCaseInsensitiveSearch] == NSOrderedSame)
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
				
				if([self openOpfDocument:fileURL])
				{	
					hasOPFFile = YES;
					fileOpenedOK = YES;
					// now open the ncx file
					
				}
				else
				{	
					
					// open the ncxfile here
				}
				
			}
			else
			{	
				// open the NCX File here
				
			}
		}
		else
		{	
			// we have chosen some other sort of file so open and process it.
			if([[filename pathExtension] compare:@"opf" options:NSCaseInsensitiveSearch] == NSOrderedSame)
			{
				hasOPFFile = [self openOpfDocument:aURL];
				if(hasOPFFile == YES)
				{	
					fileOpenedOK = YES;
					// successfully opened the opf document so get the ncx filename from it
					NSString *ncxPathString = [NSString stringWithString:[bookPath stringByAppendingPathComponent:[opfDoc ncxFilename]]];
					
					NSURL *ncxURL = [[NSURL alloc] initFileURLWithPath:ncxPathString];
					// open the ncx file
					if([self openNcxDocument:ncxURL])
					{	
						hasNCXFile = YES;
						
					}
					
				}
				else
				{	// we failed to open the opf file 
					//fileOpenedOK = NO;
					// send an error to the user that the file couldnt be opened
				}
					
			}
			//check for other other types of control files like NCX, NCC.html etc  
			else if([[filename pathExtension] compare:@"ncx" options:NSCaseInsensitiveSearch] == NSOrderedSame)
			{
				if([self openNcxDocument:aURL])
				{	
					hasNCXFile = YES;
					fileOpenedOK = YES;
				}
				else
				{	
					// send a message to the user that the file did not load correctly
				}
			}
			
		}
		
		
		if (fileOpenedOK)
		{
			//setup the notification type if we need to
			if(hasOPFFile)
			{
				// check that we have some sort of audio media in the file
				if(([opfDoc bookMediaFormat] != TextNCXMediaFormat))
					[self setupAudioNotifications];
			}
			else if(hasNCXFile)
			{
				// setup audionotifications as per the media format of the ncx file.
			}
			
			
		}
		
		if(fileOpenedOK == NO)
			return nil;
	}
		
	
	
	return self;
}

/*
- (void) dealloc
{
	[opfDoc release];
	[ncxDoc release];
	
	[TalkingBookNotificationCenter removeObserver:self];
	
	[super dealloc];
}
*/

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
			isPlaying = YES;
		}
	}
	else // isPlaying == YES
	{
		[self sendNotificationsForPosInBook];
		[currentAudioFile play];
		isPlaying = YES;
	}
}

- (void)pauseAudio
{	
	[currentAudioFile stop];
	isPlaying = NO;
	
}

#pragma mark -
#pragma mark Navigation Methods

- (BOOL)hasNextFile
{
	BOOL isAFileAfterThis = NO;
	
	if(hasNCXFile)
		isAFileAfterThis = [ncxDoc canGoNext]; 
	
	return isAFileAfterThis;
}

- (BOOL)hasPrevFile
{
	BOOL isAFileBeforeThis = NO;

	if(hasNCXFile)
		isAFileBeforeThis = [ncxDoc canGoPrev];
	
	return isAFileBeforeThis;
}


- (BOOL)nextSegment
{
	NSString *audioSegmentFilename;
	BOOL	fileDidUpdate = NO;
	if(YES == hasNCXFile)
	{	
		// get the filename of the next audio file to play from the ncx file
		audioSegmentFilename = [ncxDoc nextSegmentAudioFilePath];
	}
	
	fileDidUpdate = [self updateAudioFile:audioSegmentFilename];
	
	return fileDidUpdate;
}

- (BOOL)nextSegmentOnLevel
{
	NSString *audioSegmentFilename = nil;
	BOOL fileDidUpdate = NO;
	if(YES == hasNCXFile)
	{	
		// get the filename of the next file to play from the ncx file
		[ncxDoc setLoadFromCurrentLevel:YES];
		audioSegmentFilename = [ncxDoc nextSegmentAudioFilePath];
	}
	
	fileDidUpdate = [self updateAudioFile:audioSegmentFilename];
	
	return fileDidUpdate;
}

- (BOOL)previousSegment 
{
	NSString *audioSegmentFilename = nil;
	BOOL	fileDidUpdate = NO;
	if(YES == hasNCXFile)
	{	
		// get the filename of the next audio file to play from the ncx file
		audioSegmentFilename = [ncxDoc previousSegmentAudioFilePath];
	}
	
	fileDidUpdate = [self updateAudioFile:audioSegmentFilename];
	
	return fileDidUpdate;
}

- (void)upOneLevel
{
	if(self.ncxDoc)
	{
		NSString *audioFilePath = [ncxDoc goUpALevel];
		[self updateAudioFile:audioFilePath];
	}
		
}

- (void)downOneLevel
{
	if(self.ncxDoc)
	{
		NSString *audioFilePath = [ncxDoc goDownALevel];
		[self updateAudioFile:audioFilePath];
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
		//[self sendNotificationsForPosInBook];
	}
}

- (void)previousChapter
{
	if((currentChapterIndex - 1) >= 0)
	{
		currentChapterIndex--;
		[currentAudioFile setCurrentTime:[currentAudioFile startTimeOfChapter:currentChapterIndex]];
		//[self sendNotificationsForPosInBook];
	}
}

- (void)gotoPage
{
	
}

#pragma mark -
#pragma mark Information Methods

- (NSInteger)currentLevelIndex
{
	NSInteger level;
	if(hasNCXFile)
		 level = [ncxDoc currentLevel];
	
	return level;
}


- (NSDictionary *)getBookInfo
{
	
}


- (NSDictionary *)getCurrentPageInfo
{
	
}

- (NSString *)bookTitle
{
	NSString *titleString;
	if(hasOPFFile == YES)
		titleString = [NSString stringWithString:[opfDoc bookTitle]];
	else 
		titleString = [NSString stringWithString:@"No Title"];
	
	return titleString; 
}

- (NSString *)sectionTitle
{
	NSString *titleString;
	if(hasNCXFile)
	{
		titleString = [ncxDoc segmentTitle];
	}
	
	return (titleString != nil) ? titleString : @"";
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
	
#pragma mark -
#pragma mark Private Methods

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
			// make the file editable
			[currentAudioFile setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
						
			if(hasNCXFile)
			{
				// populate the chapters array with a default timescale of 1ms
				NSArray *chaptersArray = [NSArray arrayWithArray:[ncxDoc chaptersForSegmentWithTimescale:(long)1000]];
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
	
	
	[self setPreferredAudioAttributes];
	
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
	return (hasNCXFile) ? [ncxDoc canGoDownLevel] : NO;
}

- (BOOL)hasParentLevel
{
	return (hasNCXFile) ? [ncxDoc canGoUpLevel] : NO; // add opf check maybe?
}
	

- (void)setPreferredAudioAttributes
{
	//NSLog(@" current Vol : %f    Current Rate : %f",currentPlaybackVolume,currentPlaybackRate);
	
	[currentAudioFile setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieRateChangesPreservePitchAttribute];
	
	[currentAudioFile setAttribute:[NSNumber numberWithFloat:self.currentPlaybackVolume] forKey:QTMoviePreferredVolumeAttribute];
	[currentAudioFile setVolume:currentPlaybackVolume];
	[currentAudioFile setAttribute:[NSNumber numberWithFloat:self.currentPlaybackRate] forKey:QTMoviePreferredRateAttribute];
	[currentAudioFile setDelegate:self];
	//[currentAudioFile setRate:self.currentPlaybackRate];
	//NSLog(@"BBSTB PREFAUDIOATTS currentaudiofile atts: \n%@",[currentAudioFile movieAttributes]);
	
}



- (BOOL)openOpfDocument:(NSURL *)fileURL
{
	BOOL fileOK = NO;
	
	opfDoc = [[BBSTBOPFDocument alloc] initWithURL:fileURL];
	if(opfDoc != nil)
		fileOK = YES;
	
	return fileOK;

}


- (BOOL)openNcxDocument:(NSURL *)fileURL
{
	BOOL fileOK = NO;
	
	ncxDoc = [[BBSTBNCXDocument alloc] initWithURL:fileURL];
	if(opfDoc != nil)
		fileOK = YES;
	
	return fileOK;
}

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
	BOOL aState;
	NSMutableDictionary *stateDict = [[NSMutableDictionary alloc] init];
	
	currentChapterIndex = [currentAudioFile chapterIndexForTime:[currentAudioFile currentTime]];
		
	aState = (currentChapterIndex < (totalChapters - 1)) ? YES : NO;
	[stateDict setObject:[NSNumber numberWithBool:aState] forKey:@"state"];
	[TalkingBookNotificationCenter postNotificationName:BBSTBhasNextChapterNotification object:self userInfo:stateDict];
		
	aState = (currentChapterIndex > 0) ? YES : NO;
	[stateDict setObject:[NSNumber numberWithBool:aState] forKey:@"state"];
	[TalkingBookNotificationCenter postNotificationName:BBSTBhasPrevChapterNotification object:self userInfo:stateDict];
}


- (void)sendNotificationsForPosInBook
{
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
