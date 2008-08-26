//
//  OleariaDelegate.m
//  Olearia
//
//  Created by Kieren Eaton on 4/05/08.
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

#import "OleariaDelegate.h"
#import <Cocoa/Cocoa.h>
#import "BBSTalkingBook.h"
#import "OleariaPrefsController.h"

@interface OleariaDelegate ()


@end


@implementation OleariaDelegate

@synthesize talkingBook;


- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		talkingBook = [[BBSTalkingBook alloc] init];
		
		isPlaying = NO;
		
		validFileTypes = [[NSArray alloc] initWithObjects:@"opf",@"ncx",@"html",nil];
	}
	return self;
}

- (void) finalize
{

	validFileTypes = nil;
	talkingBook = nil;
	
	[super finalize];
}


- (void) awakeFromNib
{
	//[toolsView addSubview:volumeRateView];
	
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
                   modalForWindow:mainWindow 
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
		
		//[self disableAllControls];
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
		// load the talking book package or control file 
		if([talkingBook openWithFile:[openPanel URL]])
		{
			[talkingBook nextSegment]; // load the first segment ready for play
		}
		else
		{
			
			// put up a dialog saying that the file chosen was not a valid control document for the book.
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:@"OK"];
	
			[alert setMessageText:@"Invalid File"];
			[alert setInformativeText:@"The File you chose to open was not a valid Package (OPF) or Control (NCX or NCC.html) Document."];
			[alert setAlertStyle:NSWarningAlertStyle];
		
			[alert runModal];
			
			alert = nil;
		}
	}
	

} 

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	return YES;
}

#pragma mark -
#pragma mark Private Methods

- (IBAction)toggleNavigationBox:(NSButton *)sender
{
	// get the size of the window
	NSRect windowRect = [mainWindow frame];
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
	[[mainWindow animator] setFrame:windowRect display:YES animate:YES];
	//[[documentWindow contentView] setWantsLayer:NO];
	[NSAnimationContext endGrouping];

}

- (IBAction)toggleToolBox:(NSButton *)sender
{
	/*
	// get the size of the window
	NSRect windowRect = [mainWindow frame];
	//NSRect toolboxrect = [toolBox frame];
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

		//toolboxrect.size.height = toolBoxOrigSize.size.height;

		discFrame.origin.y =  discFrame.origin.y + (toolBoxOrigSize.size.height - 26);
	}
	else // collapsing
	{
		//windowRect.origin.y = windowRect.origin.y + (toolboxrect.size.height -  26);
		windowRect.size.height = windowRect.size.height - (toolboxrect.size.height -  26);
		//toolboxrect.size.height = 26;
		discFrame.origin.y =  discFrame.origin.y - (toolBoxOrigSize.size.height - 26);
	}
	[[toolBoxDisclosure animator] setFrame:discFrame];
	[[toolBox animator] setFrame:toolboxrect];
	[[mainWindow animator] setFrame:windowRect display:NO animate:YES];
	[NSAnimationContext endGrouping];
	*/
}

#pragma mark -
#pragma mark View Display Methods

- (IBAction)displaySoundView:(id)sender
{
	

}

- (IBAction)displayPrefsPanel:(id)sender
{
	if(!prefsController)
	{
		prefsController = [[OleariaPrefsController alloc] init];
		
	}
	[prefsController showWindow:self];

}

@end
