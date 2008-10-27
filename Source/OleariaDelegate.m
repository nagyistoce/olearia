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
NSString * const OleariaEnableVoiceOnLevelChange = @"OleariaEnableVoiceOnLevelChange";


@interface OleariaDelegate ()

+ (void)setupDefaults;
- (NSString *)applicationSupportFolder;
- (void)populateRecentFilesMenu;
- (void)updateRecentBooks:(NSString *)pathToMove updateSettings:(BOOL)shouldUpdate;
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
	
	BOOL isDir;
	// get the defaults
	_userSetDefaults = [NSUserDefaults standardUserDefaults];
	
		
	// init the book object
	talkingBook = [[BBSTalkingBook alloc] init];
	
	// set the defaults before any book is loaded
	// these defaults will change after the book is loaded
	talkingBook.playbackRate = [_userSetDefaults floatForKey:OleariaPlaybackRate];
	talkingBook.playbackVolume = [_userSetDefaults floatForKey:OleariaPlaybackVolume];
	talkingBook.preferredVoice = [_userSetDefaults valueForKey:OleariaPlaybackVoice];
	talkingBook.chapterSkipIncrement = [_userSetDefaults floatForKey:OleariaChapterSkipIncrement];
	
	isPlaying = NO;
	
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

	validFileTypes = nil;
	_userSetDefaults = nil;
	talkingBook = nil;
	
	[super finalize];
}


- (void) awakeFromNib
{
	// 0x0020 is the space bar character
	[playPauseButton setKeyEquivalent:[NSString stringWithFormat:@"%C",0x0020]];
	
	// load our recent books (if any) into the Recent Books menu
	[self populateRecentFilesMenu];
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
	
	// get the position of the selected book from the recent books menu and
	// use that to get the path to the package or control file
	NSString *validFilePath = [[_recentBooks objectAtIndex:[recentBooksMenu indexOfItem:sender]] valueForKey:@"FilePath"];
	
	bookLoaded = [self loadBookAtPath:validFilePath];
	if (!bookLoaded)
	{
		// put up a dialog saying that there was a problem finding the recent book selected.
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"Invalid File"];
		[alert setInformativeText:@"There was a problem opening the chosen book.  \nIt may have been deleted or moved to a different location."];
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
}

- (IBAction)downLevel:(id)sender
{
	[talkingBook downOneLevel];
}

- (IBAction)nextSegment:(id)sender
{
	// check if we traversed to the next segment ok
	if(YES == [talkingBook nextSegmentOnLevel])
	{
		[talkingBook playAudio];
	}

}

- (IBAction)previousSegment:(id)sender
{
	// check if we traversed to the previous segment ok
	if(YES == [talkingBook previousSegment]);
	{
		[talkingBook playAudio];
	}
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

- (IBAction)setPlaybackSpeed:(NSSlider *)sender
{	
	talkingBook.playbackRate = [sender floatValue]; 
}

- (IBAction)setPlaybackVolume:(NSSlider *)sender
{
	talkingBook.playbackVolume = [sender floatValue];
}

- (void)openPanelDidEnd:(NSOpenPanel *)openPanel 
             returnCode:(int)returnCode 
            contextInfo:(void *)x 
{ 
	
	if(returnCode == NSOKButton)
	{	
		NSString *shortErrorMsg, *fullErrorMsg;
		BOOL bookLoaded = NO;
		
		[openPanel close];  // close the panel so it doesnt confuse the user that we are busy processing the book
		
		NSString *validFilePath = [self controlFilenameFromFolder:[[openPanel URL] path]];
				
		if(nil != validFilePath)
		{
			bookLoaded = [self loadBookAtPath:validFilePath];
			if (!bookLoaded)
			{
				shortErrorMsg = [NSString stringWithString:@"Invalid File"];
				fullErrorMsg = [NSString stringWithString:@"The File you chose to open was not a valid Package (OPF) or Control (NCX or NCC.html) Document."];
			}
		}
		else
		{
			shortErrorMsg = [NSString stringWithString:@"Invalid File or Folder"];
			fullErrorMsg = [NSString stringWithString:@"The File or Folder you chose to open did not contain or was not a valid Package (OPF) or Control (NCC.html) Document."];
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

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// stop playing if we are playing
	if(talkingBook.isPlaying)
		[talkingBook pauseAudio];

	// update the current settings of the currently (if any) open Book
	[self updateRecentBooks:nil updateSettings:talkingBook.bookIsAlreadyLoaded];
	
	// save the settings
	[_recentBooks writeToFile:_recentBooksPlistPath atomically:YES];
	
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
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
			NSArray *contents = [fm contentsOfDirectoryAtPath:aFolderPath error:NULL];
			if(nil != contents)
			{
				for(NSString *anItem in contents)
				{
					NSString *extension = [NSString stringWithString:[[anItem pathExtension] lowercaseString]];
					// check for an opf or ncx extension
					if(([extension isEqualToString:@"opf"]) || ([extension isEqualToString:@"ncx"]))
					{
						controlFilename = [NSString stringWithString:[aFolderPath stringByAppendingPathComponent:anItem]];
						break;
					}
					else
					{
						// check for a 2.02 control document
						if([[[anItem lastPathComponent] lowercaseString] isEqualToString:@"ncc.html"])
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
			NSString *extension = [NSString stringWithString:[[aFolderPath pathExtension] lowercaseString]];
			// check for an opf or ncx extension
			if(([extension isEqualToString:@"opf"]) || ([extension isEqualToString:@"ncx"]))
			{
				controlFilename = [NSString stringWithString:aFolderPath];
			}
			else
			{
				// check for a 2.02 control document
				if([[[aFolderPath lastPathComponent] lowercaseString] isEqualToString:@"ncc.html"])
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
		[self updateRecentBooks:nil updateSettings:YES];
	}
	
	// load the talking book package or control file
	loadedOK = [talkingBook openWithFile:validFileURL];
	if(loadedOK)
	{
		//update the recent files list
		[self updateRecentBooks:[talkingBook fullBookPath] updateSettings:NO];
		
		// load the first segment ready for play
		[talkingBook nextSegment]; 
	}
	
	return loadedOK;
}

- (void)updateRecentBooks:(NSString *)pathToMove updateSettings:(BOOL)shouldUpdate
{
    
	if(YES == shouldUpdate)
	{
			// get the settings that have been saved for the previously loaded book
			NSMutableDictionary *oldSettings = [[NSMutableDictionary alloc] initWithDictionary:[_recentBooks objectAtIndex:0]];

			// get the current settings from the book and save them to the recent files list
			[oldSettings setValue:[NSNumber numberWithFloat:self.talkingBook.playbackRate] forKey:@"Rate"];
			[oldSettings setValue:[NSNumber numberWithFloat:self.talkingBook.playbackVolume] forKey:@"Volume"];
			[oldSettings setValue:[self.talkingBook.preferredVoice description] forKey:@"Voice"];
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
			self.talkingBook.playbackRate = [[newSettings valueForKey:@"Rate"] floatValue];
			self.talkingBook.playbackVolume = [[newSettings valueForKey:@"Volume"] floatValue];
			self.talkingBook.preferredVoice = [newSettings valueForKey:@"Voice"];
			self.talkingBook.speakUserLevelChange = [_userSetDefaults boolForKey:OleariaEnableVoiceOnLevelChange];
			
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
			NSDictionary *defaultSettings = [[NSDictionary alloc] initWithObjectsAndKeys:[[talkingBook bookTitle] description],@"Title",
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
			self.talkingBook.playbackRate = [_userSetDefaults floatForKey:OleariaPlaybackRate];
			self.talkingBook.playbackVolume = [_userSetDefaults floatForKey:OleariaPlaybackVolume];
			self.talkingBook.preferredVoice = [_userSetDefaults valueForKey:OleariaPlaybackVoice];
			self.talkingBook.speakUserLevelChange = [_userSetDefaults boolForKey:OleariaEnableVoiceOnLevelChange];
			
			NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:talkingBook.bookTitle action:@selector(openRecentBook:) keyEquivalent:@""];
			[recentBooksMenu insertItem:newItem atIndex:0];
		}
		
	}
	
}

- (void)populateRecentFilesMenu
{
	NSArray *bookTitles = [_recentBooks valueForKeyPath:@"Title"];
	
	for(NSString *aTitle in bookTitles)
	{
		[recentBooksMenu addItemWithTitle:aTitle action:@selector(openRecentBook:) keyEquivalent:@""];
		
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
	
	// set them in the shared user defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:defaultValuesDict];
	
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

- (NSString *)applicationSupportFolder 
{
	// return the application support folder relative to the users home folder 
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	// set the folder name if the array has an item otherwise use a temp folder
	NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	
	// add the name of the application and return it
	return [basePath stringByAppendingPathComponent:@"Olearia"];
}

@synthesize talkingBook, _recentBooks, _recentBooksPlistPath;

@end
