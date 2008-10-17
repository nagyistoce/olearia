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
#import "BBSTalkingBook.h"
#import "OleariaPrefsController.h"
#import "AboutBoxController.h"


NSString * const OleariaPlaybackVolume = @"OleariaPlaybackVolume";
NSString * const OleariaPlaybackRate = @"OleariaPlaybackRate";
NSString * const OleariaPlaybackVoice = @"OleariaPlaybackVoice"; 
NSString * const OleariaUseVoiceForPlayback = @"OleariaUseVoiceForPlayback";
NSString * const OleariaChapterSkipIncrement = @"OleariaChapterSkipIncrement";

@interface OleariaDelegate (Private)

+ (void)setupDefaults;

@end



@implementation OleariaDelegate

@synthesize talkingBook;

+ (void) initialize
{
	[self setupDefaults];
}

+ (void)setupDefaults
{
    NSMutableDictionary *defaultValuesDict = [NSMutableDictionary dictionary];
	NSDictionary *initialValuesDict;
	NSArray *resettableKeys;
	
	// setup the default values for our prefs keys
	[defaultValuesDict setValue:[NSNumber numberWithFloat:1.0] forKey:OleariaPlaybackRate];
	[defaultValuesDict setValue:[NSNumber numberWithFloat:1.0] forKey:OleariaPlaybackVolume];
	[defaultValuesDict setValue:[NSNumber numberWithBool:NO] forKey:OleariaUseVoiceForPlayback];
	[defaultValuesDict setObject:[NSSpeechSynthesizer defaultVoice] forKey:OleariaPlaybackVoice];
	[defaultValuesDict setValue:[NSNumber numberWithFloat:0.5] forKey:OleariaChapterSkipIncrement];
    
	// set them in the standard user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValuesDict];
	
	// set the keys for the resetable prefs -- these make a subset of the entire userdefaults dict
    resettableKeys=[NSArray arrayWithObjects:OleariaPlaybackRate, 
					OleariaPlaybackVoice, 
					OleariaPlaybackVolume, 
					OleariaUseVoiceForPlayback, 
					OleariaChapterSkipIncrement,
					nil];
    // get the values for the specified keys
	initialValuesDict=[defaultValuesDict dictionaryWithValuesForKeys:resettableKeys];
    // Set the initial values in the shared user defaults controller
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];
}


- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		// get the defaults
		userDefaults = [NSUserDefaults standardUserDefaults];
		// init the book object
		talkingBook = [[BBSTalkingBook alloc] init];
		
		// set the defaults before any book is loaded
		// these defaults will change after the book is loaded
		talkingBook.playbackRate = [userDefaults floatForKey:OleariaPlaybackRate];
		talkingBook.playbackVolume = [userDefaults floatForKey:OleariaPlaybackVolume];
		talkingBook.preferredVoice = [userDefaults valueForKey:OleariaPlaybackVoice];
		talkingBook.chapterSkipIncrement = [userDefaults floatForKey:OleariaChapterSkipIncrement];
		
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
	
	// set the sliders to default values
	// these values will change once the book is loaded if it has settings
	[playbackVolumeSlider setFloatValue:[userDefaults floatForKey:OleariaPlaybackVolume]];
	[playbackSpeedSlider setFloatValue:[userDefaults floatForKey:OleariaPlaybackRate]];
	
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
	//[talkingBook playAudio];
}

- (IBAction)downLevel:(id)sender
{
	[talkingBook downOneLevel];
	//[talkingBook playAudio];
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

#pragma mark  TODO add reference to recent doc not userdefaults
- (IBAction)setPlaybackSpeed:(NSSlider *)sender
{	
	float newRate = [sender floatValue];
	if(newRate != [userDefaults floatForKey:OleariaPlaybackRate])
	{
		talkingBook.playbackRate = newRate; 
		[userDefaults setFloat:newRate forKey:OleariaPlaybackRate];
		[userDefaults synchronize];
	}
	

}
#pragma mark  TODO add reference to recent doc not userdefaults
- (IBAction)setPlaybackVolume:(NSSlider *)sender
{
	float newVolume = [sender floatValue];
	if(newVolume != [userDefaults floatForKey:OleariaPlaybackVolume])
	{
		talkingBook.playbackVolume = newVolume; 
		[userDefaults setFloat:newVolume forKey:OleariaPlaybackVolume];
		[userDefaults synchronize];
	}

}

- (void)openPanelDidEnd:(NSOpenPanel *)openPanel 
             returnCode:(int)returnCode 
            contextInfo:(void *)x 
{ 
	if(returnCode == NSOKButton)
	{	
		NSFileManager *fm = [NSFileManager defaultManager];
		BOOL isDir, bookLoaded = NO;
		NSString *shortErrorMsg, *fullErrorMsg;
		
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
					// setup the user saved settings (if Any) for playback
					talkingBook.chapterSkipIncrement = [userDefaults floatForKey:OleariaChapterSkipIncrement];
					
					[talkingBook nextSegment]; // load the first segment ready for play
				}
				else
				{
					shortErrorMsg = [NSString stringWithString:@"Invalid File"];
					fullErrorMsg = [NSString stringWithString:@"The File you chose to open was not a valid Package (OPF) or Control (NCX or NCC.html) Document."];
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
							// setup the user saved settings for playback
							talkingBook.chapterSkipIncrement = [userDefaults floatForKey:OleariaChapterSkipIncrement];
							// we will get the settings from the recent documents dict if required
							[talkingBook nextSegment]; // load the first segment ready for play
							//[talkingBook updateForPosInBook];
							break;
						}
						else
						{
							break;
						}
					}
				}
				if(NO == bookLoaded)
				{
					shortErrorMsg = [NSString stringWithString:@"Invalid Folder"];
					fullErrorMsg = [NSString stringWithString:@"The Folder you chose to open did not contain a valid Package (OPF) or Control (NCC.html) Document."];
				}
				
			}
			
			// check if we failed loading at all
			if(NO == bookLoaded)
			{
				// close the panel before we show the error dialog
				[openPanel close];
				
				// put up a dialog saying that the folder chosen did not a valid document for opening the book.
				NSAlert *alert = [[NSAlert alloc] init];
				[alert setMessageText:shortErrorMsg];
				[alert setInformativeText:fullErrorMsg];
				[alert setAlertStyle:NSWarningAlertStyle];
				[alert setIcon:[NSImage imageNamed:@"olearia.icns"]];
				// we dont need a response from the user so set all options except window to nil;
				[alert beginSheetModalForWindow:mainWindow 
								  modalDelegate:nil 
								 didEndSelector:nil 
									contextInfo:nil];
				alert = nil;
			}
		}
	}

} 

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
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

- (IBAction)displayAboutPanel:(id)sender
{
	if(!aboutController)
	{
		aboutController = [[AboutBoxController alloc] init];
	}
	[aboutController showWindow:self];
}

@end
