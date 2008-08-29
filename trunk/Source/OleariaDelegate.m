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

- (IBAction)openDocument:(id)sender
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
		NSFileManager *fm = [NSFileManager defaultManager];
		BOOL isDir, bookLoaded = NO;
		
		// first check that the file exists
		if ([fm fileExistsAtPath:[[openPanel URL] path] isDirectory:&isDir])
		{
			// check if its a folder
			if(NO == isDir)
			{
				// load the talking book package or control file
				bookLoaded = [talkingBook openWithFile:[openPanel URL]];
				if(bookLoaded)
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
			else // the path is a directory
			{
				NSString *pathStr = [[NSString alloc] initWithString:[[openPanel URL] path]];
				NSArray *folderContents = [fm contentsOfDirectoryAtPath:pathStr error:nil];
				
				for(NSString *file in folderContents)
				{
					NSString *extension = [NSString stringWithString:[[file pathExtension] lowercaseString]];
					if([extension isEqualToString:@"opf"] || [[file lowercaseString] isEqualToString:@"ncc.html"])
					{
						NSURL *validFileURL = [[NSURL alloc] initFileURLWithPath:[pathStr stringByAppendingPathComponent:file]];
						// load the talking book package or control file
						bookLoaded = [talkingBook openWithFile:validFileURL];
						if(bookLoaded)
						{
							[talkingBook nextSegment]; // load the first segment ready for play
							break;
						}
						else
						{
							// put up a dialog saying that the folder chosen did not a valid document for opening the book.
							NSAlert *alert = [[NSAlert alloc] init];
							[alert addButtonWithTitle:@"OK"];
							
							[alert setMessageText:@"Invalid Folder"];
							[alert setInformativeText:@"The Folder you chose to open did not contain a valid Package (OPF) or Control (NCC.html) Document."];
							[alert setAlertStyle:NSWarningAlertStyle];
							
							[alert runModal];
							
							alert = nil;
							break;
						}
					}
				}
			}
			
		}
	}
	

} 

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	return YES;
}



#pragma mark -
#pragma mark View Display Methods



- (IBAction)displayPrefsPanel:(id)sender
{
	if(!prefsController)
	{
		prefsController = [[OleariaPrefsController alloc] init];
		
	}
	[prefsController showWindow:self];

}

@end
