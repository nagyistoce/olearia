//
//  OleariaDelegate.m
//  Olearia
//
//  Created by Kieren Eaton on 4/05/08.
//  BrainBender Software 2008.
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

#import "OleariaDelegate.h"
#import <Cocoa/Cocoa.h>
//#import <AppKit/Appkit.h>
#import "BBSTalkingBook/BBSTalkingBook.h"

@interface OleariaDelegate ()

- (void)enableLevelButtons:(BOOL)aState;
- (void)enableToolButtons:(BOOL)aState;
- (void)disableAllControls;

@end


@implementation OleariaDelegate

@synthesize talkingBook;

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		isPlaying = NO;
		
		validFileTypes = [[NSArray alloc] initWithObjects:@"opf",@"ncx",@"html",nil];
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		
		[nc addObserver:self selector:@selector(updateInterface:) name:BBSTBCanGoNextFileNotification object:nil];
		[nc addObserver:self selector:@selector(updateInterface:) name:BBSTBCanGoPrevFileNotification object:nil];
		[nc addObserver:self selector:@selector(updateInterface:) name:BBSTBCanGoUpLevelNotification object:nil];
		[nc addObserver:self selector:@selector(updateInterface:) name:BBSTBCanGoDownLevelNotification object:nil];
		[nc addObserver:self selector:@selector(updateInterface:) name:BBSTBhasNextChapterNotification object:nil];
		[nc addObserver:self selector:@selector(updateInterface:) name:BBSTBhasPrevChapterNotification object:nil];
		
	}
	return self;
}

- (void) finalize
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	validFileTypes = nil;
	talkingBook = nil;
	
	[super finalize];
}

/*
- (void)dealloc
{
	[validFileTypes release];
	
	[talkingBook release];
	[super dealloc];
}
*/


- (void) awakeFromNib
{
	[documentWindow setTitle:@"Olearia"];
	[currentPageTextfield setStringValue:@""];
	[currentLevelTextfield setStringValue:@""];
	navBoxOrigSize = [navBox frame];
	toolBoxOrigSize = [toolBox frame];
	[self disableAllControls];
	[playbackSpeedSlider setFloatValue:1.0];
	[playbackSpeedTextfield setFloatValue:[playbackSpeedSlider floatValue]];
	[playbackVolumeSlider setFloatValue:1.0];
	[playbackVolumeTextfield setFloatValue:[playbackVolumeSlider floatValue]];
	
	// 0x0020 is the space character
	[playPauseButton setKeyEquivalent:[NSString stringWithFormat:@"%C",0x0020]];
}



#pragma mark -
#pragma mark Actions

- (IBAction)open:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:YES];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseFiles:YES];
	// Run the open panel 
    [panel beginSheetForDirectory:nil 
                             file:nil 
                            types:validFileTypes 
                   modalForWindow:documentWindow 
                    modalDelegate:self 
                   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
                      contextInfo:NULL]; 
	
	
}


- (IBAction)PlayPause:(id)sender
{
	
	if(isPlaying == NO)
	{
		// set the button stat and menuitem title 
		[playPauseMenuItem setTitle:@"Pause         <space>"];
		
		// switch the play and pause icons on the button
		NSImage *tempImage = [playPauseButton image];
		[playPauseButton setImage:[playPauseButton alternateImage]];
		[playPauseButton setAlternateImage:tempImage];
		
		isPlaying = YES;
				
		[talkingBook playAudio];
	}
	else // isPlaying == YES
	{
		[playPauseMenuItem setTitle:@"Play          <space>"];
		
		isPlaying = NO;
		
		// switch the play and pause icons on the button
		NSImage *tempImage = [playPauseButton image];
		[playPauseButton setImage:[playPauseButton alternateImage]];
		[playPauseButton setAlternateImage:tempImage];
		
		[talkingBook pauseAudio];
		
		[self disableAllControls];
		[playPauseMenuItem setEnabled:YES];
		[playPauseButton setEnabled:YES];
	}
}

- (IBAction)upLevel:(id)sender
{
	[talkingBook upOneLevel];
	[talkingBook playAudio];
}

- (IBAction)downLevel:(id)sender
{
	[talkingBook downOneLevel];
	[talkingBook playAudio];
}

- (IBAction)nextSegment:(id)sender
{
	if(YES == [talkingBook nextSegmentOnLevel])
	{
		[talkingBook playAudio];
	}

}

- (IBAction)previousSegment:(id)sender
{
	if(YES == [talkingBook previousSegment]);
	{
		[talkingBook playAudio];
	}
}

- (IBAction)fastForward:(id)sender
{
	//if(YES == [talkingBook hasChapters])
	//{
		[talkingBook nextChapter];
	//}
}

- (IBAction)fastRewind:(id)sender
{
	//if(YES == [talkingBook hasChapters])
	//{
		[talkingBook previousChapter];
	//}
	
}

- (IBAction)gotoPage:(id)sender
{
	
}

- (IBAction)getInfo:(id)sender
{
	
}

- (IBAction)showBookmarks:(id)sender
{
	
}
	
- (IBAction)addBookmark:(id)sender
{
		
}

- (IBAction)setPlaybackSpeed:(NSSlider *)sender
{	
	[playbackSpeedTextfield setFloatValue:[sender floatValue]];
	[talkingBook setNewPlaybackRate:[sender floatValue]];
}

- (IBAction)setPlaybackVolume:(NSSlider *)sender
{
	[playbackVolumeTextfield setFloatValue:[sender floatValue]];
	[talkingBook setNewVolumeLevel:[sender floatValue]]; 
}

#pragma mark -
#pragma mark Delegate Methods

- (void)openPanelDidEnd:(NSOpenPanel *)openPanel 
             returnCode:(int)returnCode 
            contextInfo:(void *)x 
{ 
	if(returnCode == NSOKButton)
	{	
		// init the talking book 
		talkingBook = [[BBSTalkingBook alloc] initWithFile:[openPanel URL]];
		// check it loaded ok
		if(talkingBook != nil)
		{
			[documentWindow setTitle:[talkingBook bookTitle]];
			[talkingBook setNewPlaybackRate:[playbackSpeedSlider floatValue]];
			[talkingBook setNewVolumeLevel:[playbackVolumeSlider floatValue]];
			[playPauseButton setEnabled:YES];
			[playPauseMenuItem setEnabled:YES];
			[playbackSpeedSlider setEnabled:YES];
			[playbackVolumeSlider setEnabled:YES];
			[self enableToolButtons:YES];
			[talkingBook nextSegment]; // load the first segment ready for play
			[talkingBook sendNotificationsForPosInBook]; // update the display 
			
		}
		else
		{
			//[talkingBook release];
			// put up a dialog saying that the file chosen was not a valid control document for the book.
		}
	}
	

} 

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	return YES;
}

#pragma mark -
#pragma mark Private Methods

- (void)enableLevelButtons:(BOOL)aState
{
	[upLevelButton setEnabled:aState];
	[downLevelButton setEnabled:aState];
	[upLevelMenuItem setEnabled:aState];
	[downLevelMenuItem setEnabled:aState];

}

- (void)enableToolButtons:(BOOL)aState
{
	[bookmarkButton setEnabled:aState];
	[infoButton setEnabled:aState];
	[gotoPageButton setEnabled:aState];
}

- (void)disableAllControls
{
	[playPauseButton setEnabled:NO];
	[playPauseMenuItem setEnabled:NO];
	
	[prevButton setEnabled:NO];
	[prevSegmentMenuItem setEnabled:NO];
	
	[nextButton setEnabled:NO];
	[nextSegmentMenuItem setEnabled:NO];
	
	[fastBackButton setEnabled:NO]; 
	[fastBackMenuItem setEnabled:NO];
	
	[fastForwardButton setEnabled:NO];
	[fastForwardMenuItem setEnabled:NO];
	
	[self enableToolButtons:NO];
	[self enableLevelButtons:NO];

	
}

- (IBAction)toggleNavigationBox:(NSButton *)sender
{
	// get the size of the window
	NSRect windowRect = [documentWindow frame];
	NSRect navBoxRect = [navBox frame];
	NSPoint navBoxOrigin = navBoxRect.origin;
	 
	
	
	// start the grouped animation set
	[NSAnimationContext beginGrouping];
	// set the length of the animation 
	[[NSAnimationContext currentContext] setDuration:0.4];
	
	//[[documentWindow contentView] setWantsLayer:YES];
	// check what we are doing
	if([sender state] == NSOnState) // expanding
	{
		//[upLevelButton setAlphaValue:1.0];
		
		windowRect.size.height = windowRect.size.height + (navBoxOrigSize.size.height - 26);
		windowRect.origin.y = windowRect.origin.y - (navBoxOrigSize.size.height - 26);
		navBoxRect.size.height = navBoxOrigSize.size.height;
		navBoxOrigin.y = navBoxOrigin.y - (26);
	}
	else // collapsing
	{
		//[upLevelButton setAlphaValue:0.0];
		windowRect.origin.y = windowRect.origin.y + (navBoxOrigSize.size.height - 26);
		windowRect.size.height = windowRect.size.height - (navBoxOrigSize.size.height - 26);
		navBoxRect.size.height = 26;
		navBoxOrigin.y = navBoxOrigin.y + (navBoxOrigSize.size.height - 26);
	}
	[[navBox animator] setFrameOrigin:navBoxOrigin]; //:navBoxRect];
	[[navBox animator] setFrameSize:navBoxRect.size];
	//[[documentWindow animator] setFrame:windowRect.size];
	//[[documentWindow animator] setFrameOrigin:windowRect.origin];
	[[documentWindow animator] setFrame:windowRect display:YES animate:YES];
	//[[documentWindow contentView] setWantsLayer:NO];
	[NSAnimationContext endGrouping];
	
	
	

}

- (IBAction)toggleToolBox:(NSButton *)sender
{
	// get the size of the window
	NSRect windowRect = [documentWindow frame];
	NSRect toolboxrect = [toolBox frame];
	NSRect discFrame = [toolBoxDisclosure frame];
	// start the grouped animation set
	[NSAnimationContext beginGrouping];
	// set the length of the animation 
	[[NSAnimationContext currentContext] setDuration:0.3];
	
	// check what we are doing
	if([sender state] == NSOnState) // expanding
	{
		windowRect.size.height = windowRect.size.height + (toolBoxOrigSize.size.height - 26);
		windowRect.origin.y = windowRect.origin.y -  (toolBoxOrigSize.size.height - 26);

		toolboxrect.size.height = toolBoxOrigSize.size.height;

		discFrame.origin.y =  discFrame.origin.y + (toolBoxOrigSize.size.height - 26);
	}
	else // collapsing
	{
		windowRect.origin.y = windowRect.origin.y + (toolboxrect.size.height -  26);
		windowRect.size.height = windowRect.size.height - (toolboxrect.size.height -  26);
		toolboxrect.size.height = 26;
		discFrame.origin.y =  discFrame.origin.y - (toolBoxOrigSize.size.height - 26);
	}
	[[toolBoxDisclosure animator] setFrame:discFrame];
	[[toolBox animator] setFrame:toolboxrect];
	[[documentWindow animator] setFrame:windowRect display:NO animate:YES];
	[NSAnimationContext endGrouping];
	
}


#pragma mark -
#pragma mark Notifications

- (void)updateInterface:(NSNotification *)aNote
{
	if(isPlaying)
	{
		BOOL state = [[[aNote userInfo] valueForKey:@"state"] boolValue];
		
		if([[aNote name] isEqualToString:BBSTBCanGoNextFileNotification])
		{	
			[nextButton setEnabled:state];
			[nextSegmentMenuItem setEnabled:state];
			
		}
		else if([[aNote name] isEqualToString:BBSTBCanGoPrevFileNotification])
		{		
			[prevButton setEnabled:state];
			[prevSegmentMenuItem setEnabled:state];
		}
		else if([[aNote name] isEqualToString:BBSTBCanGoUpLevelNotification])
		{		
			[upLevelButton setEnabled:state];
			[upLevelMenuItem setEnabled:state];
		}
		else if([[aNote name] isEqualToString:BBSTBCanGoDownLevelNotification])
		{		
			[downLevelButton setEnabled:state];
			[downLevelMenuItem setEnabled:state];
		}
		else if([[aNote name] isEqualToString:BBSTBhasNextChapterNotification])
		{
			[fastForwardButton setEnabled:state];
			[fastForwardMenuItem setEnabled:state];
		}
		else if([[aNote name] isEqualToString:BBSTBhasPrevChapterNotification])
		{
			[fastBackButton setEnabled:state];
			[fastBackMenuItem setEnabled:state];
		}
		
	}
	
	[segmentTitleTextfield setStringValue:[talkingBook sectionTitle]];
	[currentLevelTextfield setIntValue:[talkingBook currentLevelIndex]];					
		
}


@end
