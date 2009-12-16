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

@property (readwrite, retain)	NSMutableArray	*formatPlugins;

@property (readwrite)	BOOL	_wasPlaying;

@property (readwrite, assign)		id<TBPluginInterface>	currentPlugin;

// Bindings related
@property (readwrite)	BOOL	canPlay;


@end

@interface TBTalkingBook (Private)

- (void)errorDialogDidEnd;
- (void)resetBook;

// Plugin Loading and Validation
- (BOOL)plugInClassIsValid:(Class)plugInClass;
- (void)loadPlugins;
- (NSArray *)availBundles;

@end


@implementation TBTalkingBook

- (id) init
{
	if (!(self=[super init])) return nil;
	
	bookData = [TBBookData sharedBookData];
	
	formatPlugins = [[NSMutableArray alloc] init];
	currentPlugin = nil;
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
	[infoPanel release];
	[textWindow release];

	currentPlugin = nil;
	[formatPlugins release];
	
	self.bookData = nil;
	
	[super dealloc];
}


- (BOOL)openBookWithURL:(NSURL *)aURL
{
	// reset everything ready for a new book to be loaded
	[self resetBook];
	
	BOOL bookDidOpen = NO;
	
	// iterate throught the formatPlugins to see if one will open the URL correctly 
	for(id thePlugin in formatPlugins)
	{
#ifdef DEBUG
		NSLog(@"Checking Plugin : %@",[thePlugin description]);
#endif
		
		if([thePlugin openBook:aURL])
		{	
			// set the currentplugin to the plugin that did open the book
			currentPlugin = thePlugin;
			bookDidOpen = YES;
			self.bookIsLoaded = YES;
			self.canPlay = YES;
			if([infoPanel isVisible])
			{	
				[infoView addSubview:[currentPlugin bookInfoView]];
				
			}
			if([textWindow isVisible])
			{	
				[textView replaceSubview:[[textView subviews] objectAtIndex:0] with:[currentPlugin bookTextView]];
				[[currentPlugin bookTextView] setFrame:[textView frame]];
			}
			break;
		}
	}
	
	
	return bookDidOpen;
	
}

// takes the number of seconds to skip forwards or backwards on audio segments
- (void)setAudioSkipDuration:(double)newDuration
{
	self.bookData.audioSkipDuration = QTMakeTimeWithTimeInterval(newDuration);
}

#pragma mark -
#pragma mark Play Methods

- (void)play
{
	if(currentPlugin)
		[currentPlugin startPlayback];
}

- (void)pause
{	
	if(currentPlugin)
		[currentPlugin stopPlayback];
}


#pragma mark -
#pragma mark Navigation Methods

- (void)nextSegment
{
	if([currentPlugin respondsToSelector:@selector(nextReadingElement)])
		[currentPlugin nextReadingElement];
}

- (void)previousSegment 
{
	if([currentPlugin respondsToSelector:@selector(previousReadingElement)])
		[currentPlugin previousReadingElement];
}

- (void)upOneLevel
{
	if([currentPlugin respondsToSelector:@selector(moveUpALevel)])
	{
		[currentPlugin moveUpALevel];
	}
	
}

- (void)downOneLevel
{
	if([currentPlugin respondsToSelector:@selector(moveDownALevel)])
	{
		[currentPlugin moveDownALevel];
	}
}

- (void)fastForwardAudio
{
	if([currentPlugin respondsToSelector:@selector(skipAudioForwards)])
	{
		[currentPlugin skipAudioForwards];
	}
}

- (void)fastRewindAudio
{
	if([currentPlugin respondsToSelector:@selector(skipAudioBackwards)])
	{
		[currentPlugin skipAudioBackwards];
	}
}

- (void)gotoPage
{
	
}

#pragma mark -
#pragma mark Position Loading & Saving

- (void)jumpToPoint:(NSString *)aNodePath andTime:(NSString *)aTimeStr
{
	if(aNodePath && currentPlugin)
		[currentPlugin jumpToControlPoint:aNodePath andTime:aTimeStr];
}

- (NSString *)currentTimePosition
{
	if([currentPlugin respondsToSelector:@selector(currentPlaybackTime)])
		return [currentPlugin currentPlaybackTime]; 
	
	return nil;
}

- (NSString *)currentControlPositionID
{
	if([currentPlugin respondsToSelector:@selector(currentControlPoint)])
		return [currentPlugin currentControlPoint];

	return nil;
}


#pragma mark -
#pragma mark View Methods

- (void)showHideBookInfo
{
	if(infoPanel)
	{
		if([infoPanel isVisible])
			[infoPanel orderOut:nil];
		else
		{
			[infoView addSubview:[currentPlugin bookInfoView]];
			[infoPanel makeKeyAndOrderFront:self];
		}
	}
	else
		if([NSBundle loadNibNamed:@"TBBookInfo" owner:self])
		{	
			[infoView addSubview:[currentPlugin bookInfoView]];
			[infoPanel makeKeyAndOrderFront:self];
		}
	
	
}

- (void)showHideTextWindow
{
	if(textWindow)
	{
		if([textWindow isVisible])
			[textWindow orderOut:nil];
		else
		{

			[textView replaceSubview:[[textView subviews] objectAtIndex:0] with:[currentPlugin bookTextView]];
			[[currentPlugin bookTextView] setFrame:[textView frame]];
			
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
	self.bookData.preferredVoiceIdentifier = aVoiceID;
}




- (void)setAudioPlayRate:(float)aRate
{
	self.bookData.audioPlaybackRate = aRate;
}

- (void)setAudioVolume:(float)aVolumeLevel
{
	self.bookData.audioPlaybackVolume = aVolumeLevel;
}

@synthesize formatPlugins, currentPlugin;
@synthesize bookData;

//@synthesize _controlMode;
@synthesize _wasPlaying;
@synthesize bookIsLoaded;


//bindings
@synthesize canPlay;

@end

@implementation TBTalkingBook (Private)


- (void)resetBook
{
	
	bookIsLoaded = NO;
	
	_levelNavConMode = levelNavigationControlMode; // set the default level mode
	_maxLevelConMode = levelNavigationControlMode; // set the default max level mode. 
//	_controlMode = UnknownBookType; // set the default control mode to unknown
	
	_hasPageNavigation = NO;
	_hasPhraseNavigation = NO;
	_hasSentenceNavigation = NO;
	_hasWordNavigation = NO;
	
	self.canPlay = NO;
	
	[bookData resetData];
	
	if(currentPlugin)
		[currentPlugin reset];
}

- (void)errorDialogDidEnd
{
	[self resetBook];
}

// Plugin Loading and Validation

- (BOOL)plugInClassIsValid:(Class)plugInClass
{    
	if([plugInClass conformsToProtocol:@protocol(TBPluginInterface)])
		return YES;
	
	return NO;
}




- (void)loadPlugins
{
	NSArray *bundlePaths = [self availBundles];
	if([bundlePaths count])
	{
		for (NSString *pluginPath in bundlePaths) 
		{
			NSBundle* pluginBundle = [[[NSBundle alloc] initWithPath:pluginPath] autorelease];
			if (YES == [pluginBundle load])
			{
				if([self plugInClassIsValid:[pluginBundle principalClass]])
					[formatPlugins addObjectsFromArray:[[pluginBundle principalClass] plugins]];
			}
		}
	}
	else 
	{
		// put up a dialog saying that there were no plugins found
		NSAlert *anAlert = [[NSAlert alloc] init];
		[anAlert setMessageText:LocalizedStringInTBFrameworkBundle(@"No Plugins Found", @"No plugins found short msg")];
		[anAlert setInformativeText:LocalizedStringInTBFrameworkBundle(@"There were no suitable plugins available.\nPlease put them in the correct folder\nand restart the application.",@"no plugins found long msg")];
		[anAlert setAlertStyle:NSWarningAlertStyle];
		[anAlert setIcon:[NSApp applicationIconImage]];
		// we dont need a response from the user so set all options except window to nil;
		[anAlert beginSheetModalForWindow:[NSApp mainWindow]
							modalDelegate:nil 
						   didEndSelector:nil 
							  contextInfo:nil];
		anAlert = nil;
		
	}

}

- (NSArray *)availBundles
{
	NSArray *librarySearchPaths;
	NSString *currPath;
	NSMutableArray *bundleSearchPaths = [NSMutableArray array];
	NSMutableArray *allBundles = [NSMutableArray array];
	
	librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);

	NSString *appName =[[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
	for(currPath in librarySearchPaths)
	{
		[bundleSearchPaths addObject:[currPath stringByAppendingPathComponent:appName]];
	}
	
	[bundleSearchPaths addObject:[[NSBundle mainBundle] builtInPlugInsPath]];
	
	for(currPath in bundleSearchPaths)
	{
		NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:currPath error:nil];
		if(dirContents)
			for(NSString *currBundlePath in dirContents)
			{
				if([[currBundlePath pathExtension] isEqualToString:@"plugin"])
					[allBundles addObject:[currPath stringByAppendingPathComponent:currBundlePath]];
			}
	}
	
	return allBundles;
}

- (BOOL)windowShouldClose:(id)sender
{
	if(sender == textWindow)
	{	
		[sender orderOut:nil];
		return NO;
	}
	else if(sender == infoPanel)
		infoPanel = nil;
	
	return YES;
}

@end

