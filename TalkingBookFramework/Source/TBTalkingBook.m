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
#import <QTKit/QTKit.h>

@interface TBTalkingBook ()

- (void)errorDialogDidEnd;
- (void)resetBook;

- (BOOL)isSmilFilename:(NSString *)aFilename;

// Pkugin Loading and Validation
- (BOOL)plugInClassIsValid:(Class)plugInClass;
- (void)loadPlugins;
- (void)updateInfoView;
- (void)updateTextView;

@property (readwrite, retain)	NSMutableArray	*plugins;
@property (readwrite, copy)		id<TBPluginInterface>	currentPlugin;
@property (readwrite, retain)	NSSpeechSynthesizer *speechSynth;
@property (readwrite)			TalkingBookType _controlMode;

@property (readwrite)	BOOL	_wasPlaying;

// Bindings related
@property (readwrite)	BOOL	canPlay;


@end

@implementation TBTalkingBook

- (id) init
{
	if (!(self=[super init])) return nil;

	speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
	[speechSynth setDelegate:self];
	
	self.bookData = [TBSharedBookData sharedInstance];
	
	plugins = [[NSMutableArray alloc] init];
	[self loadPlugins];
		
	[self resetBook];
	
	bookIsLoaded = NO;

	infoPanel = nil;
	infoView = nil;
	textView = nil;
	
	return self;
}



- (void) dealloc
{
	if([speechSynth isSpeaking])
		[speechSynth stopSpeaking];
	
	[speechSynth release];
	
	if(_infoController)
		[_infoController release];

	[textWindow release];
	[infoPanel	release];
	
	
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
			bookIsLoaded = YES;
			self.canPlay = YES;
			if([infoPanel isVisible])
				[self updateInfoView];
			break;
		}
	}
	
		
	return bookDidOpen;
	
}

- (void)updateSkipDuration:(float)newDuration
{
	self.bookData.chapterSkipDuration = QTMakeTimeWithTimeInterval((double)newDuration * (double)60);
}

#pragma mark -
#pragma mark Play Methods

- (void)play
{
	[currentPlugin startPlayback];
}

- (void)pause
{	

	[currentPlugin stopPlayback];
}


#pragma mark -
#pragma mark Navigation Methods

- (void)nextSegment
{
	[currentPlugin nextReadingElement];
}

- (void)previousSegment 
{
	[currentPlugin previousReadingElement];
}

- (void)upOneLevel
{
	if(speakUserLevelChange)
	{
		self.bookData.isPlaying = NO;
		_wasPlaying = YES;
		[currentPlugin upLevel];
		[speechSynth startSpeakingString:[NSString stringWithFormat:NSLocalizedString(@"Level %d.", @"VO level string"),bookData.currentLevel]];
	}
	else
	{
		[currentPlugin upLevel];
	}

}

- (void)downOneLevel
{
	if(speakUserLevelChange)
	{
		self.bookData.isPlaying = NO;
		_wasPlaying = YES;
		[currentPlugin downLevel];
		[speechSynth startSpeakingString:[NSString stringWithFormat:NSLocalizedString(@"Level %d.", @"VO level string"),bookData.currentLevel]];
	}
	else
	{
		[currentPlugin downLevel];
	}
	
	
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
#pragma mark Position Loading & Saving

- (void)jumpToPoint:(NSString *)aNodePath andTime:(NSString *)aTimeStr
{
	if(aNodePath)
		[currentPlugin jumpToControlPoint:aNodePath andTime:aTimeStr];

}

- (NSString *)currentControlPositionID
{
	return [currentPlugin currentControlPoint];
}

- (NSString *)currentPlaybackTime
{
	return [currentPlugin currentPlaybackTime];
}

#pragma mark -
#pragma mark Information Methods

- (NSString *)currentTimePosition
{
	NSString *nowTime = nil;
	if(currentPlugin)
		nowTime = [currentPlugin currentPlaybackTime]; 
	
	return nowTime;
}



- (void)showHideBookInfo
{
	if(infoPanel)
	{
		if([infoPanel isVisible])
			[infoPanel close];
		else
		{
			[self updateInfoView];
			[infoPanel makeKeyAndOrderFront:self];
		}
	}
	else
		if([NSBundle loadNibNamed:@"TBBookInfo" owner:self])
		{	
			[infoView addSubview:[currentPlugin bookInfoView]];
			[currentPlugin updateInfoFromPlugin:currentPlugin];
			[infoPanel makeKeyAndOrderFront:self];
		}
	
	
}

- (void)showHideTextWindow
{
	if(textWindow)
	{
		if([textWindow isVisible])
			[textWindow close];
		else
		{
			[self updateTextView];
			[textWindow makeKeyAndOrderFront:self];
		}
	}
	else
		if([NSBundle loadNibNamed:@"TBTextWindow" owner:self])
		{	
			if(currentPlugin)
			{	
				[textView addSubview:[currentPlugin bookTextView]];
				[[currentPlugin bookTextView] setFrame:[textView frame]];
			}
			
			[textWindow makeKeyAndOrderFront:self];
		}
	
	
}

- (void)updateInfoView
{
	if([[infoView subviews] objectAtIndex:0] != [currentPlugin bookInfoView])
	{	
		[infoView replaceSubview:[[infoView subviews] objectAtIndex:0] with:[currentPlugin bookInfoView]];
		[[currentPlugin bookInfoView] setFrame:[infoView frame]];
	}

	[currentPlugin updateInfoFromPlugin:currentPlugin];

}

- (void)updateTextView
{
	if([[textView subviews] objectAtIndex:0] != [currentPlugin bookTextView])
	{	
		[textView replaceSubview:[[textView subviews] objectAtIndex:0] with:[currentPlugin bookTextView]];
		[[currentPlugin bookTextView] setFrame:[textView frame]];
	}
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
			
	bookIsLoaded = NO;
	
	_levelNavConMode = levelNavigationControlMode; // set the default level mode
	_maxLevelConMode = levelNavigationControlMode; // set the default max level mode. 
	_controlMode = UnknownBookType; // set the default control mode to unknown
	
	_hasPageNavigation = NO;
	_hasPhraseNavigation = NO;
	_hasSentenceNavigation = NO;
	_hasWordNavigation = NO;
	
	self.canPlay = NO;
	
	[bookData resetForNewBook];
	
	if(currentPlugin)
		[currentPlugin reset];
}

- (BOOL)isSmilFilename:(NSString *)aFilename
{
	return [[[aFilename pathExtension] lowercaseString] isEqualToString:@"smil"];
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
			NSBundle* pluginBundle = [[[NSBundle alloc] initWithPath:pluginPath] autorelease];
			if (YES == [pluginBundle load])
			{
				
				[plugins addObjectsFromArray:[[pluginBundle principalClass] plugins]];
				[plugins makeObjectsPerformSelector:@selector(setSharedBookData:) withObject:bookData];
			}
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
	if(_wasPlaying)
		self.bookData.isPlaying = YES;
}

@synthesize plugins, currentPlugin;

@synthesize bookData;
@synthesize speechSynth, preferredVoice;

@synthesize _controlMode;
@synthesize _wasPlaying;
@synthesize bookIsLoaded, speakUserLevelChange, overrideRecordedContent;


//bindings
@synthesize canPlay;

@end
