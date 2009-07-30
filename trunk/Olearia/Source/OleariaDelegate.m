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
#import <TalkingBook/TBTalkingBook.h>
#import <TalkingBook/TBBookData.h>
#import "OleariaPrefsController.h"
#import "AboutBoxController.h"


NSString * const OleariaAudioPlaybackVolume = @"OleariaAudioPlaybackVolume";
NSString * const OleariaAudioPlaybackRate = @"OleariaAudioPlaybackRate";
NSString * const OleariaPreferredVoice = @"OleariaPreferredVoice"; 
NSString * const OleariaUseVoiceForPlayback = @"OleariaUseVoiceForPlayback";
NSString * const OleariaVoiceVolume = @"OleariaVoiceVolume";
NSString * const OleariaVoicePlaybackRate = @"OleariaVoicePlaybackRate";
NSString * const OleariaChapterSkipIncrement = @"OleariaChapterSkipIncrement";
NSString * const OleariaEnableVoiceOnLevelChange = @"OleariaEnableVoiceOnLevelChange";
NSString * const OleariaShouldOpenLastBookRead = @"OleariaShouldOpenLastBookRead";
NSString * const OleariaShouldUseHighContrastIcons = @"OleariaShouldUseHighContrastIcons";
NSString * const OleariaIgnoreBooksOnRemovableMedia = @"OleariaIgnoreBooksOnRemovableMedia";
NSString * const OleariaShouldRelaunchNotification = @"OleariaShouldRelaunchNotification";

@interface OleariaDelegate ()

+ (void)setupDefaults;
- (NSString *)applicationSupportFolder;
- (void)populateRecentFilesMenu;
- (void)updateRecentBooks:(NSString *)currentBookPath;
- (void)loadHighContrastImages;
- (BOOL)loadBookAtPath:(NSString *)aFilePath;
- (void)saveCurrentBookSettings;
- (void)updateOldPrefSettings;

@property (readwrite, retain) NSMutableArray *_recentBooks;
@property (readwrite, retain) NSString *_recentBooksPlistPath;

@end


@implementation OleariaDelegate

+ (void) initialize
{
	[self setupDefaults];
}

- (id) init
{
	if (!(self=[super init])) return nil;
	
	shouldReLaunch = NO; 
	
	BOOL isDir;
	// get the defaults
	_userSetDefaults = [NSUserDefaults standardUserDefaults];
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self 
														   selector:@selector(removableMediaMounted:) 
															   name:NSWorkspaceDidMountNotification
															 object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(windowDidMinimize:) 
												 name:NSWindowDidMiniaturizeNotification 
											   object:mainWindow ];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(windowDidDeminimize:) 
												 name:NSWindowDidDeminiaturizeNotification 
											   object:mainWindow];

	// init the framework
	talkingBook = [[TBTalkingBook alloc] init];
	
	// set the defaults before any book is loaded
	// these defaults will change after the book is loaded
	talkingBook.bookData.playbackRate = [_userSetDefaults floatForKey:OleariaAudioPlaybackRate];
	talkingBook.bookData.playbackVolume = [_userSetDefaults floatForKey:OleariaAudioPlaybackVolume];
	talkingBook.bookData.preferredVoice = [_userSetDefaults valueForKey:OleariaPreferredVoice];
	talkingBook.bookData.voiceVolume = [_userSetDefaults floatForKey:OleariaVoiceVolume];
	[talkingBook updateSkipDuration:[_userSetDefaults floatForKey:OleariaChapterSkipIncrement]];
	
	// do a check if we need to upgrade the old settings 
	if([_userSetDefaults valueForKey:@"OleariaPlaybackVoice"] != nil)
		[self updateOldPrefSettings];
	
	validFileTypes = [[NSArray alloc] initWithObjects:@"opf",@"ncx",@"html",nil];
	
	// set the path to the recent books folder
	_recentBooksPlistPath = [[NSString alloc] initWithString:[[self applicationSupportFolder] stringByAppendingPathComponent:@"recentBooks.plist"]];

	NSFileManager *fm = [NSFileManager defaultManager];
	// check if the support folder exists
	if([fm fileExistsAtPath:[self applicationSupportFolder] isDirectory:&isDir] && isDir)
	{
		// the folder exists so check if the recent files plist exists
		if([fm fileExistsAtPath:_recentBooksPlistPath])
		{
			// the file exists so read the file into the recentbooks dict
			_recentBooks = [[NSMutableArray alloc] initWithContentsOfFile:_recentBooksPlistPath];
		}
		else
		{
			// the file doesnt exist so just init the recent books dict
			_recentBooks = [[NSMutableArray alloc] init];
		}
	}
	else
	{
		// create the application support folder
		// which will be used to hold our support files
		[fm createDirectoryAtPath:[self applicationSupportFolder] withIntermediateDirectories:YES attributes:nil error:nil];
		// init the recent books dict
		_recentBooks = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[talkingBook release];
	[_recentBooks release];
	[_recentBooksPlistPath release];
	[validFileTypes release];
	[_aboutController release];
	[_prefsController release];
	
	[super dealloc];
}



- (void) awakeFromNib
{
	[mainWindow makeKeyAndOrderFront:self];
	
	// 0x0020 is the space bar character
	[playPauseButton setKeyEquivalent:[NSString stringWithFormat:@"%C",0x0020]];
	
	// set the title of the play/pause menu item
	[playPauseMenuItem setTitle:NSLocalizedString(@"Play          <space>", @"menu item play string")];
	// resize all the menu items so they sho;; their entire content
	[[[playPauseMenuItem menu] supermenu] sizeToFit];
	
	// load our recent books (if any) into the Recent Books menu
	[self populateRecentFilesMenu];
	
	if([_userSetDefaults boolForKey:OleariaShouldUseHighContrastIcons])
	{
		[self loadHighContrastImages];
	}
	
	if([_userSetDefaults boolForKey:OleariaShouldOpenLastBookRead] && ([_recentBooks count] > 0))
	{
		// get the first item in the recent books list
		NSString *validFilePath = [[_recentBooks objectAtIndex:0] valueForKey:@"FilePath"];
		// check that we did get a file path
		if(nil != validFilePath)
		if(NO == [self loadBookAtPath:validFilePath])
		{
			//[recentBooksMenu removeItemAtIndex:0];
			[_recentBooks removeObjectAtIndex:0];
		}
	}
	
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


- (IBAction)openRecentBook:(id)sender
{
	
	BOOL bookLoaded = NO;
	
	if(talkingBook.bookData.isPlaying)
	{
		[talkingBook pause];
		// we switch the images like this to allow for differences between names when using normal 
		// or high contrast icons.
		NSImage *tempImage = [playPauseButton image];
		[playPauseButton setImage:[playPauseButton alternateImage]];
		[playPauseButton setAlternateImage:tempImage];
	}
	
	// get the position of the selected book from the recent books menu and
	// use that to get the path to the package or control file
	NSString *validFilePath = [[_recentBooks objectAtIndex:[[recentBooksMenuItem submenu] indexOfItem:sender]] valueForKey:@"FilePath"];
	
	bookLoaded = [self loadBookAtPath:validFilePath];
	if (!bookLoaded)
	{
		// put up a dialog saying that there was a problem finding the recent book selected.
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:NSLocalizedString(@"Invalid File",@"invalid file short msg")];
		[alert setInformativeText:NSLocalizedString(@"There was a problem opening the chosen book.  \nIt may have been deleted or moved to a different location.",@"recent load fail alert long msg")];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert setIcon:[NSImage imageNamed:@"olearia.icns"]];
		// we dont need a response from the user so set all options except window to nil;
		[alert beginSheetModalForWindow:mainWindow 
						  modalDelegate:nil 
						 didEndSelector:nil 
							contextInfo:nil];
		alert = nil;

		// seeing as we failed to open the book remove it from the recent files list and the menu too
		[_recentBooks removeObjectAtIndex:[[recentBooksMenuItem submenu] indexOfItem:sender]];
		[self populateRecentFilesMenu];
		
	}
}

- (IBAction)PlayPause:(id)sender
{
	if(talkingBook.bookData.isPlaying == NO)
	{
		// set the button status and menuitem title 
		[playPauseMenuItem setTitle:NSLocalizedString(@"Pause         <space>",@"menu item pause string")];
		[[playPauseMenuItem menu] sizeToFit];
		
		// we switch the images like this to allow for differences between names when using normal 
		// or high contrast icons.
		NSImage *tempImage = [playPauseButton image];
		[playPauseButton setImage:[playPauseButton alternateImage]];
		[playPauseButton setAlternateImage:tempImage];
				
		talkingBook.bookData.isPlaying = YES;
				
		[talkingBook play];
	}
	else // isPlaying == YES
	{
		[playPauseMenuItem setTitle:NSLocalizedString(@"Play          <space>", @"menu item play string")];
		[[playPauseMenuItem menu] sizeToFit];
	
		talkingBook.bookData.isPlaying = NO;
		
		// we switch the images like this to allow for differences between names when using normal 
		// or high contrast icons.
		NSImage *tempImage = [playPauseButton image];
		[playPauseButton setImage:[playPauseButton alternateImage]];
		[playPauseButton setAlternateImage:tempImage];
		
		[talkingBook pause];
		
	}
}

- (IBAction)upLevel:(id)sender
{
	[talkingBook upOneLevel];
}

- (IBAction)downLevel:(id)sender
{
	[talkingBook downOneLevel];
}

- (IBAction)nextSegment:(id)sender
{
	[talkingBook nextSegment];
}

- (IBAction)previousSegment:(id)sender
{
	[talkingBook previousSegment];
}

- (IBAction)fastForward:(id)sender
{
		[talkingBook fastForwardAudio];	
}

- (IBAction)fastRewind:(id)sender
{
		[talkingBook fastRewindAudio];		
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

- (IBAction)showBookInfo:(id)sender
{
	[talkingBook showHideBookInfo];
}

- (IBAction)showTextWindow:(id)sender
{
	[talkingBook showHideTextWindow];
}

- (IBAction)setPlaybackSpeed:(NSSlider *)sender
{	
	[talkingBook setAudioPlayRate:[sender floatValue]]; 
}

- (IBAction)setPlaybackVolume:(NSSlider *)sender
{
	[talkingBook setAudioVolume:[sender floatValue]];
}



#pragma mark -
#pragma mark Delegate Methods

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	// use this method to process files that are double clicked on in the finder  
	BOOL loadedOK = NO;

	if(nil != filename)
	{
		loadedOK = [self loadBookAtPath:filename];
	}
	
	return loadedOK;
}

- (void) removableMediaAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	BOOL bookLoaded = NO;
	
	if(returnCode == NSOKButton)
	{
		if(talkingBook.bookIsLoaded)
			[self saveCurrentBookSettings];
		bookLoaded = [self loadBookAtPath:(NSString *)contextInfo];
		if (bookLoaded)
		{	
			//update the recent files list
			[self updateRecentBooks:[[[talkingBook currentPlugin] loadedURL] path]];
		}
		else
		{
			// put up a dialog saying that there was a problem loading the book
			NSAlert *anAlert = [[NSAlert alloc] init];
			[anAlert setMessageText:NSLocalizedString(@"Failed To Open", @"removable media load fail alert short msg")];
			[anAlert setInformativeText:NSLocalizedString(@"There was a problem opening the chosen book.  \nIt may have be corrupted.",@"removable media load fail alert long msg")];
			[anAlert setAlertStyle:NSWarningAlertStyle];
			[anAlert setIcon:[NSImage imageNamed:@"olearia.icns"]];
			// we dont need a response from the user so set all options except window to nil;
			[anAlert beginSheetModalForWindow:mainWindow 
							  modalDelegate:nil 
							 didEndSelector:nil 
								contextInfo:nil];
			anAlert = nil;
		}
	}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// stop playing if we are playing
	if(talkingBook.bookData.isPlaying)
		//[talkingBook pauseAudio];
		talkingBook.bookData.isPlaying = NO;
	
	if(talkingBook.bookIsLoaded)
		[self saveCurrentBookSettings];
	
	// save the recent books settings
	if([_recentBooks count] > 0)
		[_recentBooks writeToFile:_recentBooksPlistPath atomically:YES];
	
	if(shouldReLaunch)
	{
		NSArray *helperArguments = [NSArray arrayWithObjects: [[NSBundle mainBundle] bundlePath], nil];
		[NSTask launchedTaskWithLaunchPath:[[NSBundle mainBundle] pathForResource:@"RelaunchHelper" ofType:@""] arguments:helperArguments];
	}
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)openPanelDidEnd:(NSOpenPanel *)openPanel 
             returnCode:(int)returnCode 
            contextInfo:(void *)x 
{ 
	
	if(returnCode == NSOKButton)
	{	
		if(talkingBook.bookData.isPlaying)
		{
			talkingBook.bookData.isPlaying = NO;
			// we switch the images like this to allow for differences between names when using normal 
			// or high contrast icons.
			NSImage *tempImage = [playPauseButton image];
			[playPauseButton setImage:[playPauseButton alternateImage]];
			[playPauseButton setAlternateImage:tempImage];
			[talkingBook pause];
		}
		
		
		NSString *shortErrorMsg, *fullErrorMsg;
		BOOL bookLoaded = NO;
		
		[openPanel close];  // close the panel so it doesnt confuse the user that we are busy processing the book
		
		NSString *bookPath = [[openPanel URL] path];
				
		if(nil != bookPath)
		{
			bookLoaded = [self loadBookAtPath:bookPath];
			if (!bookLoaded)
			{
				shortErrorMsg = [NSString stringWithString:NSLocalizedString(@"Invalid File", @"invalid file short msg")];
				fullErrorMsg = [NSString stringWithString:NSLocalizedString(@"The File you chose to open was not a valid Package (OPF) or Control (NCX or NCC.html) Document.", @"invalid file long msg")];
			}
		}
		else
		{
			shortErrorMsg = [NSString stringWithString:NSLocalizedString(@"Invalid File or Folder", @"invalid file or folder short msg")];
			fullErrorMsg = [NSString stringWithString:NSLocalizedString(@"The File or Folder you chose to open did not contain or was not a valid Package (OPF) or Control (NCC.html) Document.", @"invalid file or folder long msg")];
		}
		
		if(!bookLoaded)
		{
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

#pragma mark -
#pragma mark Notification Methods

- (void)windowDidMinimize:(NSNotification *)aNote
{
	[minimizeMenuItem setEnabled:NO];
}

- (void)windowDidDeminimize:(NSNotification *)aNote
{
	[minimizeMenuItem setEnabled:YES];
}



#pragma mark -
#pragma mark View Display Methods



- (IBAction)displayPrefsPanel:(id)sender
{
	 
	if(!_prefsController)
		_prefsController = [[OleariaPrefsController alloc] init];
	
	[_prefsController showWindow:nil];

}

- (IBAction)displayAboutPanel:(id)sender
{
	if(!_aboutController)
		_aboutController = [[AboutBoxController alloc] init];
	
	[_aboutController showWindow:nil];
}






#pragma mark -
#pragma mark Private Methods

- (void)doRelaunch
{
	// set our flag to let us know that we want to restart
	shouldReLaunch = YES;
	// we use terminate: here instead of stop: to use the NSApp delegate methods for nice cleanup and shutdown
	[NSApp terminate:self];
}

- (void)loadHighContrastImages
{
	[playPauseButton setImage:[NSImage imageNamed:@"HC-button-play"]];
	[playPauseButton setAlternateImage:[NSImage imageNamed:@"HC-button-pause"]];
	[nextButton setImage:[NSImage imageNamed:@"HC-ForwardArrow"]];
	[prevButton setImage:[NSImage imageNamed:@"HC-BackArrow"]];
	[upLevelButton setImage:[NSImage imageNamed:@"HC-UpArrow"]];
	[downLevelButton setImage:[NSImage imageNamed:@"HC-DownArrow"]];
	[fastForwardButton setImage:[NSImage imageNamed:@"HC-button-forward"]];
	[fastBackButton setImage:[NSImage imageNamed:@"HC-button-rewind"]];
	[infoButton setImage:[NSImage imageNamed:@"HC-info"]];
	[bookmarkButton setImage:[NSImage imageNamed:@"HC-bookmark"]];
	[gotoPageButton setImage:[NSImage imageNamed:@"HC-gotoPage"]];
	
}


- (BOOL)loadBookAtPath:(NSString *)aFilePath
{
	NSAssert(aFilePath != nil,@"File Path is nil and should not be"); 
	
	BOOL loadedOK = NO;
	NSURL *validFileURL = [[[NSURL alloc] initFileURLWithPath:aFilePath] autorelease];
	
	// check if there is already a book loaded
	if(talkingBook.bookIsLoaded) 
		[self saveCurrentBookSettings];

	// load the talking book
	if(validFileURL)
		loadedOK = [talkingBook openBookWithURL:validFileURL];
	if(loadedOK)
		[self updateRecentBooks:[[[talkingBook currentPlugin] loadedURL] path]];
	
	
	return loadedOK;
}

- (void)saveCurrentBookSettings
{
	// get the settings that have been saved for the currently loaded book
	NSMutableDictionary *oldSettings = [[NSMutableDictionary alloc] init];

	[oldSettings addEntriesFromDictionary:[_recentBooks objectAtIndex:0]];
		
		// get the current settings from the book and save them to the recent files list
	[oldSettings setValue:[NSNumber numberWithFloat:talkingBook.bookData.playbackRate] forKey:@"Rate"];
	[oldSettings setValue:[NSNumber numberWithFloat:talkingBook.bookData.playbackVolume] forKey:@"Volume"];
	[oldSettings setValue:talkingBook.bookData.preferredVoice forKey:@"Voice"];

	
	[oldSettings setValue:[talkingBook currentControlPositionID] forKey:@"PlayPosition"];
	[oldSettings setValue:[talkingBook currentTimePosition] forKey:@"TimePosition"];
	[_recentBooks replaceObjectAtIndex:0 withObject:oldSettings];

}

- (void)updateRecentBooks:(NSString *)currentBookPath
{
    
	if(nil != currentBookPath)
	{
		NSArray *filePaths = [NSArray arrayWithArray:[_recentBooks valueForKey:@"FilePath"]];
		
		NSUInteger foundIndex = [filePaths indexOfObject:currentBookPath];				 
		// check if the path is in the recent books list
		if(foundIndex != NSNotFound)
		{   
			// get the settings that have been saved previously
			NSMutableDictionary *savedSettings = [[NSMutableDictionary alloc] initWithDictionary:[_recentBooks objectAtIndex:foundIndex]];
			
			// set the newly loaded book to the settings that were saved for it	
			talkingBook.bookData.playbackRate = [[savedSettings valueForKey:@"Rate"] floatValue];
			talkingBook.bookData.playbackVolume = [[savedSettings valueForKey:@"Volume"] floatValue];
			talkingBook.bookData.preferredVoice = [savedSettings valueForKey:@"Voice"];
			talkingBook.bookData.speakUserLevelChange = [_userSetDefaults boolForKey:OleariaEnableVoiceOnLevelChange];
				
			[talkingBook jumpToPoint:[savedSettings valueForKey:@"PlayPosition"] andTime:[savedSettings valueForKey:@"TimePosition"]];
						
			// only change the recent items position if its not already at the top of the list
			if(foundIndex > 0)
			{
				// remove the settings from their current position in the recent files list
				[_recentBooks removeObjectAtIndex:foundIndex];
				//  insert the settings at the begining of the recent files list
				[_recentBooks insertObject:savedSettings atIndex:0];
				
				// write out the changed recent books file
				[_recentBooks writeToFile:_recentBooksPlistPath atomically:YES];
				// update the recent files menu
				[self populateRecentFilesMenu];
				
			}
			
		}
		else // path not found in the recent files list
		{
			// this is the first time the book was opened so add its name and the current defaults 
			// to the dictionary along with the folder path it was loaded from.
			NSDictionary *defaultSettings = [[NSDictionary alloc] initWithObjectsAndKeys:[[talkingBook bookData] bookTitle],@"Title",
											 [currentBookPath description],@"FilePath",
											 [NSNumber numberWithFloat:[_userSetDefaults floatForKey:OleariaAudioPlaybackRate]],@"Rate",
											 [NSNumber numberWithFloat:[_userSetDefaults floatForKey:OleariaAudioPlaybackVolume]],@"Volume",
											 [_userSetDefaults objectForKey:OleariaPreferredVoice],@"Voice", 
											 nil];
			
			// put it at the beginning of the recent files list
			[_recentBooks insertObject:defaultSettings atIndex:0];
			
			// set the book to the defaults set in the preferences	
			talkingBook.bookData.playbackRate = [_userSetDefaults floatForKey:OleariaAudioPlaybackRate];
			talkingBook.bookData.playbackVolume = [_userSetDefaults floatForKey:OleariaAudioPlaybackVolume];
			talkingBook.bookData.preferredVoice = [_userSetDefaults valueForKey:OleariaPreferredVoice];
			talkingBook.bookData.voiceVolume = [_userSetDefaults floatForKey:OleariaVoiceVolume];
			talkingBook.bookData.voicePlaybackRate = [_userSetDefaults floatForKey:OleariaVoicePlaybackRate];
			talkingBook.bookData.speakUserLevelChange = [_userSetDefaults boolForKey:OleariaEnableVoiceOnLevelChange];
			
			// write out the changed recent books file
			[_recentBooks writeToFile:_recentBooksPlistPath atomically:YES];
			// update the recent files menu
			[self populateRecentFilesMenu];
			
		}
	}
}

- (void)populateRecentFilesMenu
{
	NSString *loadedFromPrefix = NSLocalizedString(@"Loaded from - ",@"loaded from tooltip msg");
	NSMenu *newRecentMenu = [[NSMenu alloc] init];
	
	for (NSDictionary *aBook in _recentBooks)
	{
		NSMenuItem *theItem = [[NSMenuItem alloc] init];
		[theItem setTitle:[aBook valueForKey:@"Title"]];
		[theItem setAction:@selector(openRecentBook:)];
		[theItem setToolTip:[loadedFromPrefix stringByAppendingString:[[aBook valueForKey:@"FilePath"] stringByDeletingLastPathComponent]]];
		[newRecentMenu addItem:theItem];
	}
	// add a separator if there are any items
	if([_recentBooks count])
		[newRecentMenu addItem:[NSMenuItem separatorItem]];
	// add the clear recent item
	NSMenuItem *theItem = [[NSMenuItem alloc] init];
	[theItem setTitle:@"Clear Books"];
	[theItem setAction:@selector(clearRecentBooks)];
	if(![_recentBooks count])
	{	
		[theItem setEnabled:NO];
		[newRecentMenu setAutoenablesItems:NO];
	}
	[newRecentMenu addItem:theItem];
	
	[recentBooksMenuItem setSubmenu:newRecentMenu];
}

- (void)clearRecentBooks
{
	[_recentBooks removeAllObjects];
	// write out the recent books file
	[_recentBooks writeToFile:_recentBooksPlistPath atomically:YES];
	// update the recent files menu;
	[self populateRecentFilesMenu];
}

+ (void)setupDefaults
{
    NSMutableDictionary *defaultValuesDict = [NSMutableDictionary dictionary];
	NSDictionary *initialValuesDict;
	NSArray *resettableKeys;
	
	// setup the default values for our prefs keys
	[defaultValuesDict setValue:[NSNumber numberWithFloat:1.0] forKey:OleariaAudioPlaybackRate];
	[defaultValuesDict setValue:[NSNumber numberWithFloat:1.0] forKey:OleariaAudioPlaybackVolume];
	[defaultValuesDict setValue:[NSNumber numberWithBool:NO] forKey:OleariaUseVoiceForPlayback];
	[defaultValuesDict setObject:[NSSpeechSynthesizer defaultVoice] forKey:OleariaPreferredVoice];
	[defaultValuesDict setObject:[NSNumber numberWithFloat:1.0] forKey:OleariaVoiceVolume];
	[defaultValuesDict setObject:[NSNumber numberWithFloat:1.0] forKey:OleariaVoicePlaybackRate];
	[defaultValuesDict setValue:[NSNumber numberWithFloat:0.5] forKey:OleariaChapterSkipIncrement];
	[defaultValuesDict setValue:[NSNumber numberWithBool:YES] forKey:OleariaEnableVoiceOnLevelChange];
	[defaultValuesDict setValue:[NSNumber numberWithBool:NO] forKey:OleariaShouldOpenLastBookRead];
	[defaultValuesDict setValue:[NSNumber numberWithBool:NO] forKey:OleariaShouldUseHighContrastIcons];
	
	// set them in the shared user defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:defaultValuesDict];
	
	// set the keys for the resetable prefs -- these make a subset of the entire userdefaults dict
    resettableKeys=[NSArray arrayWithObjects:OleariaAudioPlaybackRate, 
					OleariaAudioPlaybackVolume, 
					OleariaPreferredVoice,
					OleariaVoiceVolume,
					OleariaVoicePlaybackRate,
					OleariaUseVoiceForPlayback, 
					OleariaChapterSkipIncrement,
					OleariaShouldUseHighContrastIcons,
					OleariaShouldOpenLastBookRead,
					nil];
	
    // get the values for the specified keys
	
	initialValuesDict=[defaultValuesDict dictionaryWithValuesForKeys:resettableKeys];
    // Set the initial values in the shared user defaults controller
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];
	
}

- (NSString *)applicationSupportFolder 
{
	// return the application support folder relative to the users home folder 
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	// set the folder name if the array has an item otherwise use a temp folder
	NSString *basePath = ([paths count] > 0) ? [[paths objectAtIndex:0] copy] : NSTemporaryDirectory();
	
	// add the name of the application and return it
	return [basePath stringByAppendingPathComponent:@"Olearia"];
}

- (void)removableMediaMounted:(NSNotification *)aNote
{
//	// check that we are not ignoring removablemedia alerts
//	if(NO == [_userSetDefaults boolForKey:OleariaIgnoreBooksOnRemovableMedia])
//	{
//		NSString *controlFilePath = [NSString stringWithString:[self controlFilenameFromFolder:[[aNote userInfo] valueForKey:@"NSDevicePath"]]];
//		
//		if(nil != controlFilePath)
//		{
//			// check if we are playing a book
//			if(talkingBook.bookData.isPlaying)
//			{
//				// pause the audio to make the user take notice of the dialog
//				talkingBook.bookData.isPlaying = NO;
//			}
//			
//			NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Book on Removable Media Found", @"removable media open alert short msg") 
//											 defaultButton:NSLocalizedString(@"OK",@"ok string")
//										   alternateButton:NSLocalizedString(@"Cancel",@"cancel string")
//											   otherButton:nil
//								 informativeTextWithFormat:NSLocalizedString(@"You have mounted a device containing a talking book.\nWould you like to open it?", @"removable media open alert long msg")];
//			
//			[alert setIcon:[NSImage imageNamed:@"olearia.icns"]];
//			
//			[alert beginSheetModalForWindow:mainWindow 
//							  modalDelegate:self 
//							 didEndSelector:@selector(removableMediaAlertDidEnd:returnCode:contextInfo:) 
//								contextInfo:controlFilePath];
//			
//			
//			
//		}
//		
//	}
}

- (void)updateOldPrefSettings
{
	// copy the old settings into the new keys
	[_userSetDefaults setValue:[_userSetDefaults valueForKey:@"OleariaPlaybackRate"] forKey:OleariaAudioPlaybackRate];
	[_userSetDefaults setValue:[_userSetDefaults valueForKey:@"OleariaPlaybackVolume"] forKey:OleariaAudioPlaybackVolume];
	[_userSetDefaults setObject:[_userSetDefaults objectForKey:@"OleariaPlaybackVoice"] forKey:OleariaPreferredVoice];
	// remove the old keys
	[_userSetDefaults removeObjectForKey:@"OleariaPlaybackRate"];
	[_userSetDefaults removeObjectForKey:@"OleariaPlaybackVolume"];
	[_userSetDefaults removeObjectForKey:@"OleariaPlaybackVoice"];
	[_userSetDefaults synchronize];
	
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Preferences Updated", @"preferences updated alert short msg") 
									 defaultButton:NSLocalizedString(@"OK",@"ok string") 
								   alternateButton:nil 
									   otherButton:nil 
						 informativeTextWithFormat:NSLocalizedString(@"Your preferences have been updated./nPrevious Versions will not work with the new settings.", @"preferences update alert long msg")];
	
	[alert setIcon:[NSImage imageNamed:@"olearia.icns"]];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert runModal];
	

}

@synthesize talkingBook, _recentBooks, _recentBooksPlistPath;

@end
