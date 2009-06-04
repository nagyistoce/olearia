//
//  TBTalkingBook.m
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

#import "TBTalkingBook.h"
#import "TBTalkingBookTypes.h"
#import "TBInfoController.h"
#import "TBSharedBookData.h"
#import "TBPluginInterface.h"

#import <QTKit/QTKit.h>

@interface TBTalkingBook ()

- (void)errorDialogDidEnd;
- (void)resetBook;

- (TalkingBookControlDocType)typeOfControlDoc:(NSURL *)aURL;

- (BOOL)isSmilFilename:(NSString *)aFilename;

// Pkugin Loading and Validation
- (BOOL)plugInClassIsValid:(Class)plugInClass;
- (void)loadPlugins;

@property (readwrite, retain)	NSMutableArray	*plugins;
@property (readwrite, copy)		id<TBPluginInterface>	currentPlugin;
@property (readwrite, retain)	NSSpeechSynthesizer *speechSynth;
@property (readwrite)			TalkingBookType _controlMode;

// Bindings related
@property (readwrite) BOOL		canPlay;


@end

@implementation TBTalkingBook

- (id) init
{
	if (!(self=[super init])) return nil;

	speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
	[speechSynth setDelegate:self];
	
	self.bookData = [TBSharedBookData sharedInstance];
	
	//appSupportSubpath = [NSString stringWithFormat:@"Application Support/%@/PlugIns",[[NSBundle mainBundle] app;
	
	plugins = [[NSMutableArray alloc] init];
	[self loadPlugins];
		
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

	
	
	[super dealloc];
}


- (BOOL)openBookWithURL:(NSURL *)aURL
{
	// reset everything ready for a new book to be loaded
	[self resetBook];
	
	BOOL bookDidOpen = NO;
	
	// iterate throught the plugins to see if one will open the URL correctly 
	for(id thePlugin in plugins)
	{
#ifdef DEBUG
		NSLog(@"Checking Plugin : %@",[thePlugin description]);
#endif

		if([thePlugin openBook:aURL])
		{	
			// set the currentplugin to the plugin that did open the book
			currentPlugin = thePlugin;
			bookDidOpen = YES;
			self.canPlay = YES;
			break;
		}
	}
	
	//update the information controller if it has been previously loaded
	if(_infoController)
		[_infoController updateMetaInfoFromNode:[currentPlugin infoMetadataNode]];
	
	return bookDidOpen;
	
}


- (void)jumpToPosition:(NSString *)aPosition
{
//	if(![aPosition isEqualToString:@""])
//		if(_hasControlFile)
//			[_controlDoc jumpToNodeWithId:aPosition];
//		
}

- (void)updateSkipDuration:(float)newDuration
{
	self.bookData.chapterSkipDuration = QTMakeTimeWithTimeInterval((double)newDuration * (double)60);
}

#pragma mark -
#pragma mark Play Methods

- (void)playAudio
{
	self.bookData.isPlaying = YES;
}

- (void)pauseAudio
{	
	self.bookData.isPlaying = NO;
}


#pragma mark -
#pragma mark Navigation Methods

- (void)nextSegment
{
//	BOOL	fileDidUpdate = NO;
//	if(YES == _hasControlFile)
//	{	
//		// check that there is another segment available
//		if(bookData.hasNextSegment)
//		{
//			//[_controlDoc moveToNextSegment];
//			// get the filename of the next audio file to play from the ncx file
//			if([_controlDoc audioFilenameFromCurrentNode])
//			{	
//				if(!_smilDoc)
//				{	//_smilDoc = [[TBSMILDocument alloc] init];
//					//NSURL *smilUrl = [[NSURL alloc] initWithString:[_controlDoc audioFilenameFromCurrentNode] relativeToURL:_bookBaseURL];
//				//fileDidUpdate = [_smilDoc openWithContentsOfURL:smilUrl];
//
//				}
//				
//			}
//		}
//		else
//		{
//			// we have reached the end of the book so tell the user and reset the book to the beginning
//		}
//		
//		//fileDidUpdate = [self updateAudioFile:[_controlDoc currentAudioFilename]];
//	}
//	
//	if (!fileDidUpdate)
//	{
//		// call the method for posting a msg that there was a problem loading the file
//	}
}

- (void)nextSegmentOnLevel
{
//	BOOL fileDidUpdate = NO;
//	if(YES == _hasControlFile)
//	{	
		// move to the next segment at the current level
//		[_controlDoc setLoadFromCurrentLevel:YES];
//		[_controlDoc moveToNextSegment];
//		
//		if([_controlDoc audioFilenameFromCurrentNode])
//		{	
//			NSURL *smilUrl = [[NSURL alloc] initWithString:[_controlDoc audioFilenameFromCurrentNode] 
//											 relativeToURL:_bookBaseURL];
//			fileDidUpdate = [_smilDoc openWithContentsOfURL:smilUrl];
//			
//		}		
		// update the audio segment
		//fileDidUpdate = [self updateAudioFile:[_controlDoc currentAudioFilename]];
//	}
			
	
}

- (void)previousSegment 
{
//	BOOL	fileDidUpdate = NO;
//	if(YES == _hasControlFile)
//	{	
		// move to the previous segment of the book
//		[_controlDoc moveToPreviousSegment];
//
//		if([_controlDoc audioFilenameFromCurrentNode])
//		{	
//			NSURL *smilUrl = [[NSURL alloc] initWithString:[_controlDoc audioFilenameFromCurrentNode] 
//											 relativeToURL:_bookBaseURL];
//			fileDidUpdate = [_smilDoc openWithContentsOfURL:smilUrl];
//			
//		}
		// update the audio segment 
		//fileDidUpdate = [self updateAudioFile:[_controlDoc currentAudioFilename]];

//	}
	
	//return fileDidUpdate;
}

- (void)upOneLevel
{
//	if(_hasControlFile)
//	{
//		//[_controlDoc goUpALevel];
//		
//		//self.currentLevelString = [NSString stringWithFormat:@"%d",[_controlDoc currentLevel]];
//	}
	
	//[self updateForPosInBook];
	
	if(speakUserLevelChange)
	{
		self.bookData.isPlaying = NO;
		[speechSynth startSpeakingString:[NSString stringWithFormat:NSLocalizedString(@"Level %d", @"VO level string"),bookData.currentLevel]];
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
//	if(_hasControlFile)
//	{
		// check that we can go down a level
	//	if([_controlDoc canGoDownLevel])
//		{	
//			[_controlDoc goDownALevel];
//			
//			if([_controlDoc audioFilenameFromCurrentNode])
//			{	
//				NSURL *smilUrl = [[NSURL alloc] initWithString:[_controlDoc audioFilenameFromCurrentNode] 
//												 relativeToURL:_bookBaseURL];
//				[_smilDoc openWithContentsOfURL:smilUrl];
//			}
//			
			//self.currentLevelString = [NSString stringWithFormat:@"%d",[_controlDoc currentLevel]];
			
//		}

		//[self updateForPosInBook];
		
		if(speakUserLevelChange)
		{
			self.bookData.isPlaying = NO;
			[speechSynth startSpeakingString:[NSString stringWithFormat:NSLocalizedString(@"Level %d", @"VO level string"),bookData.currentLevel]];
		}
		else
		{
			// update the audio segment 
			//[self updateAudioFile:[_controlDoc currentAudioFilename]];
			self.bookData.isPlaying = YES;

		}
//	}
	
}

- (void)nextChapter
{
//	if(_smilDoc)
//	{
//		if(bookData.hasNextChapter)
//			[_smilDoc nextChapter];
//
//	}
	
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
//	if(_smilDoc)
//	{
//		if(bookData.hasPreviousChapter)
//			[_smilDoc previousChapter];
//	}
	
	
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

- (void)showHideBookInfo
{
	// check if we should init the controller
	if(_infoController)
		[_infoController updateMetaInfoFromNode:[currentPlugin infoMetadataNode]];
	else
		_infoController = [[TBInfoController alloc] initWithMetadataNode:[currentPlugin infoMetadataNode]];

	if(_infoController)
		[_infoController toggleInfoPanel];  	
		
}


- (NSDictionary *)getCurrentPageInfo
{
	return nil;
}

#pragma mark -
#pragma mark Overridden Attribute Methods

- (void)setPreferredVoice:(NSString *)aVoiceID;
{
	[speechSynth setVoice:aVoiceID];
	preferredVoice = aVoiceID;
}


/*
- (void)setPlayPositionID:(NSString *)aPos
{
	if(_hasControlFile)
	{
		[_controlDoc setCurrentPositionID:aPos];
	}
}
*/
 
- (NSString *)playPositionID
{
//	if(_hasControlFile)
//	{
//		return [_controlDoc currentPositionID];
//	}
	
	return nil;
}

- (NSString *)audioSegmentTimePosition
{
	NSString *nowTime = nil;
//	if(_smilDoc)
//		nowTime = [_smilDoc currentTimeString];
	
	return nowTime;
}

- (void)setAudioPlayRate:(float)aRate
{
	self.bookData.playbackRate = aRate;
}

- (void)setAudioVolume:(float)aVolumeLevel
{
	self.bookData.playbackVolume = aVolumeLevel;
}
#pragma mark -
#pragma mark Private Methods


- (void)resetBook
{
	
//	if(_hasControlFile) 
//		[_controlDoc release];
//	
//	if(_hasPackageFile) 
//		[_packageDoc release];
//	
//	if(_smilDoc) 
//		[_smilDoc release];
//	if(_textDoc) 
//		[_textDoc release];
			
	bookIsAlreadyLoaded = NO;
	

	_levelNavConMode = levelNavigationControlMode; // set the default level mode
	_maxLevelConMode = levelNavigationControlMode; // set the default max level mode. 
	_controlMode = UnknownBookType; // set the default control mode to unknown
	
	_hasPageNavigation = NO;
	_hasPhraseNavigation = NO;
	_hasSentenceNavigation = NO;
	_hasWordNavigation = NO;
	
	self.canPlay = NO;
	//self.isPlaying = NO;
	
	playPositionID = @"";
	
	[bookData resetForNewBook];

}

- (BOOL)isSmilFilename:(NSString *)aFilename
{
	return [[[aFilename pathExtension] lowercaseString] isEqualToString:@"smil"];
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

// Pkugin Loading and Validation

- (BOOL)plugInClassIsValid:(Class)plugInClass
{
    if([plugInClass conformsToProtocol:@protocol(TBPluginInterface)])
    {
        if ([plugInClass instancesRespondToSelector: @selector(initializeClass)] && 
		    [plugInClass instancesRespondToSelector: @selector(terminateClass)] &&
			[plugInClass instancesRespondToSelector: @selector(plugins)] &&
			[plugInClass instancesRespondToSelector: @selector(openBook)] &&
			[plugInClass instancesRespondToSelector: @selector(infoMetadataNode)] &&
			[plugInClass instancesRespondToSelector: @selector(FormatDescription)] &&
			[plugInClass instancesRespondToSelector: @selector(smilPlugin)] &&
			[plugInClass instancesRespondToSelector: @selector(textPlugin)])
		{
            return YES;
        }
	}
	
	return NO;
}
	
		   


- (void)loadPlugins
{
	// look for internal plugins in the frameworks and the applications internal plugins folders.
	NSString *internalPluginsPath = [[NSBundle bundleForClass:[self class]] builtInPlugInsPath];
	NSString* applicationPuginsPath = [[NSBundle mainBundle] builtInPlugInsPath]; 
	
	if ((internalPluginsPath) || (applicationPuginsPath)) 
	{
		NSMutableArray *pathsArray = [[[NSMutableArray alloc] initWithArray:[NSBundle pathsForResourcesOfType:@"plugin" inDirectory:internalPluginsPath]] autorelease];
		[pathsArray addObjectsFromArray:[NSBundle pathsForResourcesOfType:@"plugin" inDirectory:applicationPuginsPath]];
		
		
		for (NSString *pluginPath in pathsArray) 
		{
			NSBundle* pluginBundle = [[NSBundle alloc] initWithPath:pluginPath];
			if ([pluginBundle load])
				[plugins addObjectsFromArray:[[pluginBundle principalClass] plugins]];
		}
	}
}

//- (NSMutableArray *)allBundles
//{
//    NSArray *librarySearchPaths;
//    NSEnumerator *searchPathEnum;
//    NSString *currPath;
//    NSMutableArray *bundleSearchPaths = [NSMutableArray array];
//    NSMutableArray *allBundles = [NSMutableArray array];
//	
//    librarySearchPaths = NSSearchPathForDirectoriesInDomains(
//															 NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
//	
//    searchPathEnum = [librarySearchPaths objectEnumerator];
//    while(currPath = [searchPathEnum nextObject])
//    {
//        [bundleSearchPaths addObject:
//		 [currPath stringByAppendingPathComponent:appSupportSubpath]];
//    }
//    [bundleSearchPaths addObject:
//	 [[NSBundle mainBundle] builtInPlugInsPath]];
//	
//    searchPathEnum = [bundleSearchPaths objectEnumerator];
//    while(currPath = [searchPathEnum nextObject])
//    {
//        NSDirectoryEnumerator *bundleEnum;
//        NSString *currBundlePath;
//        bundleEnum = [[NSFileManager defaultManager]
//					  enumeratorAtPath:currPath];
//        if(bundleEnum)
//        {
//            while(currBundlePath = [bundleEnum nextObject])
//            {
//                if([[currBundlePath pathExtension] isEqualToString:ext])
//                {
//					[allBundles addObject:[currPath
//										   stringByAppendingPathComponent:currBundlePath]];
//                }
//            }
//        }
//    }
//	
//    return allBundles;
//}

#pragma mark -
#pragma mark Delegate Methods



- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success
{
	if(bookData.mediaFormat <= AudioOnlyMediaFormat)
	{
		//[self updateAudioFile:[_controlDoc currentAudioFilename]];
		self.bookData.isPlaying = YES;
	}
	else
	{
		/// text only update calls here 
	}
	
}

@synthesize plugins, currentPlugin;

@synthesize bookData;
@synthesize speechSynth, preferredVoice;

@synthesize _controlMode;
@synthesize bookIsAlreadyLoaded, speakUserLevelChange, overrideRecordedContent;
@synthesize playPositionID, audioSegmentTimePosition;

//bindings
@synthesize canPlay;

@end
