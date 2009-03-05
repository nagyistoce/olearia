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
#import "BBSTBSharedBookData.h"
#import "OleariaPrefsController.h"
#import "AboutBoxController.h"


NSString * const OleariaPlaybackVolume = @"OleariaPlaybackVolume";
NSString * const OleariaPlaybackRate = @"OleariaPlaybackRate";
NSString * const OleariaPlaybackVoice = @"OleariaPlaybackVoice"; 
NSString * const OleariaUseVoiceForPlayback = @"OleariaUseVoiceForPlayback";
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
- (void)updateRecentBooks:(NSString *)pathToMove updateCurrentBookSettings:(BOOL)shouldUpdate;
- (void)loadHighContrastImages;
- (NSString *)controlFilenameFromFolder:(NSString *)aFolderPath;
- (BOOL)loadBookAtPath:(NSString *)aFilePath;

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

	// init the book object
	talkingBook = [[BBSTalkingBook alloc] init];
	
	// set the defaults before any book is loaded
	// these defaults will change after the book is loaded
	talkingBook.bookData.playbackRate = [_userSetDefaults floatForKey:OleariaPlaybackRate];
	talkingBook.bookData.playbackVolume = [_userSetDefaults floatForKey:OleariaPlaybackVolume];
	talkingBook.preferredVoice = [_userSetDefaults valueForKey:OleariaPlaybackVoice];
	[talkingBook updateSkipDuration:[_userSetDefaults floatForKey:OleariaChapterSkipIncrement]];
	
	validFileTypes = [[NSArray alloc] initWithObjects:@"opf",@"ncx",@"html",nil];
	
	// set the path to the recent books folder
	_recentBooksPlistPath = [[self applicationSupportFolder] stringByAppendingPathComponent:@"recentBooks.plist"];

	NSFileManager *fm = [NSFileManager defaultManager];
	// check if the support folder exists
	if([fm fileExistsAtPath:[self applicationSupportFolder] isDirectory:&isDir] && isDir)
	{
		// the folder exists so check if the recent files plist exists
		if([fm fileExistsAtPath:_recentBooksPlistPath])
		{
			// the file exists so read the file into the recentbooks dict
			_recentBooks = [NSMutableArray arrayWithContentsOfFile:_recentBooksPlistPath];
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

- (void) finalize
{
	[super finalize];
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
			[recentBooksMenu removeItemAtIndex:0];
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
		[talkingBook pauseAudio];
		// we switch the images like this to allow for differences between names when using normal 
		// or high contrast icons.
		NSImage *tempImage = [playPauseButton image];
		[playPauseButton setImage:[playPauseButton alternateImage]];
		[playPauseButton setAlternateImage:tempImage];
	}
	
	// get the position of the selected book from the recent books menu and
	// use that to get the path to the package or control file
	NSString *validFilePath = [[_recentBooks objectAtIndex:[recentBooksMenu indexOfItem:sender]] valueForKey:@"FilePath"];
	
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
		[_recentBooks removeObjectAtIndex:[recentBooksMenu indexOfItem:sender]];
		[recentBooksMenu removeItem:[sender selectedItem]];
		
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
				
		[talkingBook playAudio];
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
		
		[talkingBook pauseAudio];
		
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
		[talkingBook nextChapter];	
}

- (IBAction)fastRewind:(id)sender
{
		[talkingBook previousChapter];		
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
	[talkingBook showBookInfo];
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
	NSString *validFilePath = [self controlFilenameFromFolder:filename];
	if(nil != validFilePath)
	{
		loadedOK = [self loadBookAtPath:validFilePath];
	}
	
	return loadedOK;
}

- (void) removableMediaAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	BOOL bookLoaded = NO;
	
	if(returnCode == NSOKButton)
	{
		if(talkingBook.bookIsAlreadyLoaded)
		{
			[self updateRecentBooks:nil updateCurrentBookSettings:YES];
		}
		bookLoaded = [self loadBookAtPath:(NSString *)contextInfo];
		if (bookLoaded)
		{	
			[self updateRecentBooks:(NSString *)contextInfo updateCurrentBookSettings:NO];
			
		}
		else
		{
			// put up a dialog saying that there was a problem loadingthe book
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
	
	// update the current settings of the currently (if any) open Book
	[self updateRecentBooks:nil updateCurrentBookSettings:talkingBook.bookIsAlreadyLoaded];
	
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
			[talkingBook pauseAudio];
		}
		
		
		NSString *shortErrorMsg, *fullErrorMsg;
		BOOL bookLoaded = NO;
		
		[openPanel close];  // close the panel so it doesnt confuse the user that we are busy processing the book
		
		NSString *validFilePath = [self controlFilenameFromFolder:[[openPanel URL] path]];
				
		if(nil != validFilePath)
		{
			bookLoaded = [self loadBookAtPath:validFilePath];
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
	{
		_prefsController = [[OleariaPrefsController alloc] init];
		
	}
	[_prefsController showWindow:self];

}

- (IBAction)displayAboutPanel:(id)sender
{
	if(!_aboutController)
	{
		_aboutController = [[AboutBoxController alloc] init];
	}
	[_aboutController showWindow:self];
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

- (NSString *)controlFilenameFromFolder:(NSString *)aFolderPath
{
	//  return the full path to the control file if the path passed in is or contains a valid control document
	//  otherwise return nil;
	//  2.02 = ncc.html
	//  2002/2005/V3  = .opf or .ncx
	
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir;
	NSString * controlFilename = nil;	
	
	// first check that the file exists
	if ([fm fileExistsAtPath:aFolderPath isDirectory:&isDir])
	{
		// we have an item that exists 
		// is it a folder?
		if(isDir)
		{
			// check for a 2.02 control document
			NSString *nccPathString = [aFolderPath stringByAppendingPathComponent:@"ncc.html"];
			if([fm fileExistsAtPath:nccPathString])
			{
				controlFilename = nccPathString;
			}
			else
			{
				// iterate through the items in the folder
				// no need to search the subfolders
				NSArray *contents = [fm contentsOfDirectoryAtPath:aFolderPath error:NULL];
				if(nil != contents)
				{
					for(NSString *anItem in contents)
					{
						// get the extension
						NSString *extension = [NSString stringWithString:[[anItem pathExtension] lowercaseString]];
						// check for an opf or ncx extension
						if(([extension isEqualToString:@"opf"]) || ([extension isEqualToString:@"ncx"]))
						{
							controlFilename = [NSString stringWithString:[aFolderPath stringByAppendingPathComponent:anItem]];
							break;
						}
					}
				}
			}
			
		}
		else
		{
			// a file path was passed in
			// check for a 2.02 control document
			if([[[aFolderPath lastPathComponent] lowercaseString] isEqualToString:@"ncc.html"])
			{
				controlFilename = [NSString stringWithString:aFolderPath];
			}
			else
			{
				NSString *extension = [NSString stringWithString:[[aFolderPath pathExtension] lowercaseString]];
				// check for an opf or ncx extension
				if(([extension isEqualToString:@"opf"]) || ([extension isEqualToString:@"ncx"]))
				{
					controlFilename = [NSString stringWithString:aFolderPath];
				}
			}
		}
	}		
	
	return controlFilename;
}

- (BOOL)loadBookAtPath:(NSString *)aFilePath
{
	NSAssert(aFilePath != nil,@"File Path is nil and should not be"); 
	
	//BOOL shouldUpdate = talkingBook.bookIsAlreadyLoaded;
	BOOL loadedOK = NO;
	NSURL *validFileURL = [[NSURL alloc] initFileURLWithPath:aFilePath];
	
	// check if there is already a book loaded
	if(talkingBook.bookIsAlreadyLoaded) 
	{
		// update the saved settings for this book before we load the next
		[self updateRecentBooks:nil updateCurrentBookSettings:YES];
	}
	
	// load the talking book package or control file
	loadedOK = [talkingBook openWithFile:validFileURL];
	if(loadedOK)
	{
		//update the recent files list
		[self updateRecentBooks:[validFileURL path] updateCurrentBookSettings:NO];
	}
	
	return loadedOK;
}

- (void)updateRecentBooks:(NSString *)pathToMove updateCurrentBookSettings:(BOOL)shouldUpdate
{
    
	if(YES == shouldUpdate)
	{
		// get the settings that have been saved for the previously loaded book
		NSMutableDictionary *oldSettings = [[NSMutableDictionary alloc] initWithDictionary:[_recentBooks objectAtIndex:0]];
		
		// get the current settings from the book and save them to the recent files list
		[oldSettings setValue:[NSNumber numberWithFloat:talkingBook.bookData.playbackRate] forKey:@"Rate"];
		[oldSettings setValue:[NSNumber numberWithFloat:talkingBook.bookData.playbackVolume] forKey:@"Volume"];
		[oldSettings setValue:talkingBook.preferredVoice forKey:@"Voice"];
		[oldSettings setValue:talkingBook.playPositionID forKey:@"PlayPosition"];
		[oldSettings setValue:talkingBook.audioSegmentTimePosition forKey:@"TimePosition"];
		[_recentBooks replaceObjectAtIndex:0 withObject:oldSettings];
	}

	if(nil != pathToMove)
	{
		NSArray *filePaths = [_recentBooks valueForKey:@"FilePath"];
		
		NSUInteger foundIndex = [filePaths indexOfObject:pathToMove];				 
		// check if the path is in the recent books list
		if(foundIndex != NSNotFound)
		{   
			// get the dict of settings for the book
			// there will only be one path per book
			// but the same book can be in different formats and so will have the same title
			
			// get the settings that have been saved previously
			NSMutableDictionary *newSettings = [[NSMutableDictionary alloc] initWithDictionary:[_recentBooks objectAtIndex:foundIndex]];
			
			
			// set the newly loaded book to the settings that were saved for it	
			talkingBook.bookData.playbackRate = [[newSettings valueForKey:@"Rate"] floatValue];
			talkingBook.bookData.playbackVolume = [[newSettings valueForKey:@"Volume"] floatValue];
			talkingBook.preferredVoice = [newSettings valueForKey:@"Voice"];
			talkingBook.speakUserLevelChange = [_userSetDefaults boolForKey:OleariaEnableVoiceOnLevelChange];
			if(nil != [newSettings valueForKey:@"PlayPosition"])
			{	
				[talkingBook jumpToPosition:[newSettings valueForKey:@"PlayPosition"]];
				if(nil != [newSettings valueForKey:@"TimePosition"])
				{
				
					talkingBook.audioSegmentTimePosition = [newSettings valueForKey:@"TimePosition"];

				}
				
			}
			
			
			// only change the recent items position if its not already at the top of the list
			if(foundIndex > 0)
			{
				// remove the settings from their current position in the recent files list
				[_recentBooks removeObjectAtIndex:foundIndex];
				// and from the recent Books menu
				NSMenuItem *currentItem = [recentBooksMenu itemAtIndex:foundIndex];
				[recentBooksMenu removeItemAtIndex:foundIndex];
				//  insert the settings at the begining of the recent files list
				[_recentBooks insertObject:newSettings atIndex:0];
				// and at the top of the recent books menu
				[recentBooksMenu insertItem:currentItem atIndex:0];
			}
			
		}
		else // path not found in the recent files list
		{
			// this is the first time the book was opened so add its name and the current defaults 
			// to the dictionary along with the folder path it was loaded from.
			NSDictionary *defaultSettings = [[NSDictionary alloc] initWithObjectsAndKeys:[[talkingBook bookData] bookTitle],@"Title",
											 [pathToMove description],@"FilePath",
											 [NSNumber numberWithFloat:[_userSetDefaults floatForKey:OleariaPlaybackRate]],@"Rate",
											 [NSNumber numberWithFloat:[_userSetDefaults floatForKey:OleariaPlaybackVolume]],@"Volume",
											 [_userSetDefaults objectForKey:OleariaPlaybackVoice],@"Voice", 
											 nil];
			
			// put it at the beginning of the recent files list
			[_recentBooks insertObject:defaultSettings atIndex:0];
			// write out the recent books file
			[_recentBooks writeToFile:_recentBooksPlistPath atomically:YES]; // save the newly added book
			
			// set the book to the defaults set in the preferences	
			talkingBook.bookData.playbackRate = [_userSetDefaults floatForKey:OleariaPlaybackRate];
			talkingBook.bookData.playbackVolume = [_userSetDefaults floatForKey:OleariaPlaybackVolume];
			talkingBook.preferredVoice = [_userSetDefaults valueForKey:OleariaPlaybackVoice];
			talkingBook.speakUserLevelChange = [_userSetDefaults boolForKey:OleariaEnableVoiceOnLevelChange];
			
			NSString *loadedFromPrefix = NSLocalizedString(@"Loaded from - ",@"loaded from tooltip msg");
			
			NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:[[talkingBook bookData] bookTitle] action:@selector(openRecentBook:) keyEquivalent:@""];
			[newItem setToolTip:[loadedFromPrefix stringByAppendingString:[[defaultSettings valueForKey:@"FilePath"] stringByDeletingLastPathComponent]]];
			[recentBooksMenu insertItem:newItem atIndex:0];
		}
		
	}
	
}

- (void)populateRecentFilesMenu
{
	NSString *loadedFromPrefix = NSLocalizedString(@"Loaded from - ",@"loaded from tooltip msg");
	
	for (NSDictionary *aBook in _recentBooks)
	{
		NSMenuItem *theItem = [[NSMenuItem alloc] init];
		[theItem setTitle:[aBook valueForKey:@"Title"]];
		[theItem setAction:@selector(openRecentBook:)];
		[theItem setToolTip:[loadedFromPrefix stringByAppendingString:[[aBook valueForKey:@"FilePath"] stringByDeletingLastPathComponent]]];
		[recentBooksMenu addItem:theItem];
	}
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
	[defaultValuesDict setValue:[NSNumber numberWithBool:YES] forKey:OleariaEnableVoiceOnLevelChange];
	[defaultValuesDict setValue:[NSNumber numberWithBool:NO] forKey:OleariaShouldOpenLastBookRead];
	[defaultValuesDict setValue:[NSNumber numberWithBool:NO] forKey:OleariaShouldUseHighContrastIcons];
	
	// set them in the shared user defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:defaultValuesDict];
	
	// set the keys for the resetable prefs -- these make a subset of the entire userdefaults dict
    resettableKeys=[NSArray arrayWithObjects:OleariaPlaybackRate, 
					OleariaPlaybackVoice, 
					OleariaPlaybackVolume, 
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
	NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	
	// add the name of the application and return it
	return [basePath stringByAppendingPathComponent:@"Olearia"];
}

- (void)removableMediaMounted:(NSNotification *)aNote
{
	// check that we are not ignoring removablemedia alerts
	if(NO == [_userSetDefaults boolForKey:OleariaIgnoreBooksOnRemovableMedia])
	{
		NSString *controlFilePath = [NSString stringWithString:[self controlFilenameFromFolder:[[aNote userInfo] valueForKey:@"NSDevicePath"]]];
		
		if(nil != controlFilePath)
		{
			// check if we are playing a book
			if(talkingBook.bookData.isPlaying)
			{
				// pause the audio to make the user take notice of the dialog
				//[talkingBook pauseAudio];
				talkingBook.bookData.isPlaying = NO;
			}
			
			NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Book on Removable Media Found", @"removable media open alert short msg") 
											 defaultButton:NSLocalizedString(@"OK",@"ok string")
										   alternateButton:NSLocalizedString(@"Cancel",@"cancel string")
											   otherButton:nil
								 informativeTextWithFormat:NSLocalizedString(@"You have mounted a device containing a talking book.\nWould you like to open it?", @"removable media open alert long msg")];
			
			[alert setIcon:[NSImage imageNamed:@"olearia.icns"]];
			
			[alert beginSheetModalForWindow:mainWindow 
							  modalDelegate:self 
							 didEndSelector:@selector(removableMediaAlertDidEnd:returnCode:contextInfo:) 
								contextInfo:controlFilePath];
			
			
			
		}
		
	}
}

@synthesize talkingBook, _recentBooks, _recentBooksPlistPath;

@end
