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
	
	
	// set the path to the recent books folder
	_recentBooksPlistPath = [[self applicationSupportFolder] stringByAppendingPathComponent:@"recentBooks.plist"];
	
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
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
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
			// init the recent books dict
			_recentBooks = [[NSMutableArray alloc] init];
		}
	}
	else
	{
		// create the application support folder
		// which will be used to hold our support files
		[fm createDirectoryAtPath:[self applicationSupportFolder] withIntermediateDirectories:YES attributes:nil error:nil];
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
	
	//[self populateRecentFilesMenu];
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

#pragma mark  TODO add reference to recent doc not userdefaults
- (IBAction)setPlaybackSpeed:(NSSlider *)sender
{	
		talkingBook.playbackRate = [sender floatValue]; 
}

#pragma mark  TODO add reference to recent doc not userdefaults
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
		NSString *validFilePath = nil;
		BOOL shouldUpdate = talkingBook.bookIsAlreadyLoaded;
		
		[openPanel close];  // close the panel so it doesnt confuse the user that we are busy processing the book
		
		// check if the settings for the currently loaded book have changed
		if(talkingBook.bookIsAlreadyLoaded) // if so save them before we attempt to load the next book
		{
			
			[_recentBooks writeToFile:_recentBooksPlistPath atomically:YES];
		}
		
		NSFileManager *fm = [NSFileManager defaultManager];
		BOOL isDir, bookLoaded = NO;
		NSString *shortErrorMsg, *fullErrorMsg;
		
		// first check that the file exists
		if ([fm fileExistsAtPath:[[openPanel URL] path] isDirectory:&isDir] && isDir)
		{
			// the path is a directory
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
						break;
					}
					else
					{
						shortErrorMsg = [NSString stringWithString:@"Invalid Folder"];
						fullErrorMsg = [NSString stringWithString:@"The Folder you chose to open did not contain a valid Package (OPF) or Control (NCC.html) Document."];

						break;
					}
				}
			}
		}
		else // file exists and its not a folder
		{
			// selected a file
			
			// try to load the file
			bookLoaded = [talkingBook openWithFile:[openPanel URL]];
			if(NO == bookLoaded)
			{
				shortErrorMsg = [NSString stringWithString:@"Invalid File"];
				fullErrorMsg = [NSString stringWithString:@"The File you chose to open was not a valid Package (OPF) or Control (NCX or NCC.html) Document."];
			}
		}
				
		// check if the book loaded correctly		
		if(bookLoaded)
		{
			validFilePath = [talkingBook fullBookPath];
			
			//update the recent files list
			[self updateRecentBooks:validFilePath updateSettings:shouldUpdate];
			
			// load the first segment ready for play
			[talkingBook nextSegment]; 
			
			//NSLog(@"rate = %f",talkingBook.playbackRate);
		}
		else
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
	// use this method to process opf and ncc.html files that are double clicked on in the finder  
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// stop playing if we are
	if(talkingBook.isPlaying)
		[talkingBook pauseAudio];

	// update the recent files to the current settings
	[self updateRecentBooks:talkingBook.fullBookPath updateSettings:talkingBook.bookIsAlreadyLoaded];
	
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

- (void)updateRecentBooks:(NSString *)pathToMove updateSettings:(BOOL)shouldUpdate
{
	NSAssert(pathToMove != nil, @"path to move is nil");
	
	NSArray *filePaths = [_recentBooks valueForKeyPath:@"Book.FilePath"];
	
	
	NSUInteger foundIndex = [filePaths indexOfObject:pathToMove];				 
	// check if the path is in the recent books list
	if(foundIndex != NSNotFound)
	{   
		// get the dict of settings for the book
		// there will only be one path per book
		// but the same book can be in different formats and so will have the same title
				
		// get the settings that have been saved previously
		NSMutableDictionary *newSettings = [[NSMutableDictionary alloc] init];
		
		if(YES == shouldUpdate)
		{
			// get the settings that have been saved previously
			NSMutableDictionary *oldSettings = [[NSMutableDictionary alloc] init];
			[oldSettings addEntriesFromDictionary:[_recentBooks objectAtIndex:0]];

			// get the current settings from the book before we move the recent item
			[oldSettings setValue:[NSNumber numberWithFloat:self.talkingBook.playbackRate] forKeyPath:@"Book.Rate"];
			[oldSettings setValue:[NSNumber numberWithFloat:self.talkingBook.playbackVolume] forKeyPath:@"Book.Volume"];
			[oldSettings setValue:[self.talkingBook.preferredVoice description] forKeyPath:@"Book.Voice"];
			[_recentBooks replaceObjectAtIndex:0 withObject:oldSettings];
			oldSettings = nil;
			
		}
		
		[newSettings addEntriesFromDictionary:[_recentBooks objectAtIndex:foundIndex]];
		// set the book to the saved settings	
		self.talkingBook.playbackRate = [[newSettings valueForKeyPath:@"Book.Rate"] floatValue];
		self.talkingBook.playbackVolume = [[newSettings valueForKeyPath:@"Book.Volume"] floatValue];
		self.talkingBook.preferredVoice = [newSettings valueForKeyPath:@"Book.Voice"];
		
		// only change the recent items position if its not already at the top of the list
		if(foundIndex > 0)
		{
			// remove the settings from their current position in the recent files list
			[_recentBooks removeObjectAtIndex:foundIndex];
			//  insert the settings at the begining of the recent files list
			[_recentBooks insertObject:newSettings atIndex:0];
		}
		newSettings = nil;
	}
	else // path not found in the recent files list
	{
		if(YES == shouldUpdate)
		{
			// get the settings that have been saved previously
			NSMutableDictionary *oldSettings = [NSMutableDictionary dictionaryWithDictionary:[_recentBooks objectAtIndex:0]];
			
			// get the current settings from the book before we move the recent item
			[oldSettings setValue:[NSNumber numberWithFloat:self.talkingBook.playbackRate] forKeyPath:@"Book.Rate"];
			[oldSettings setValue:[NSNumber numberWithFloat:self.talkingBook.playbackVolume] forKeyPath:@"Book.Volume"];
			[oldSettings setValue:[self.talkingBook.preferredVoice description] forKeyPath:@"Book.Voice"];
			[_recentBooks replaceObjectAtIndex:0 withObject:oldSettings];
			oldSettings = nil;
			
		}
		
		// this is the first time the book was opened so add its name and the current defaults 
		// to the dictionary along with the folder path it was loaded from.
		NSDictionary *defaultSettings = [[NSDictionary alloc] initWithObjectsAndKeys:[[talkingBook bookTitle] description],@"Title",
								  [pathToMove description],@"FilePath",
								  [NSNumber numberWithFloat:[_userSetDefaults floatForKey:OleariaPlaybackRate]],@"Rate",
								  [NSNumber numberWithFloat:[_userSetDefaults floatForKey:OleariaPlaybackVolume]],@"Volume",
								  [_userSetDefaults objectForKey:OleariaPlaybackVoice],@"Voice", 
								  nil];
		
		NSDictionary *newBook = [[NSDictionary alloc] initWithObjectsAndKeys:defaultSettings, @"Book", nil];
		// put it at the beginning of the recent files list
		[_recentBooks insertObject:newBook atIndex:0];
		[_recentBooks writeToFile:_recentBooksPlistPath atomically:YES]; // save the newly added book
		
		// set the book to the just saved defaults	
		self.talkingBook.playbackRate = [_userSetDefaults floatForKey:OleariaPlaybackRate];
		self.talkingBook.playbackVolume = [_userSetDefaults floatForKey:OleariaPlaybackVolume];
		self.talkingBook.preferredVoice = [_userSetDefaults objectForKey:OleariaPlaybackVoice];
		
	}
	
	//NSLog(@"recent books list \n%@",_recentBooks);
/*	
	// get the settings that have been saved previously
	NSDictionary *updatedSettings = [NSDictionary dictionaryWithDictionary:[_recentBooks objectAtIndex:0]];
	// set the book to the saved settings	
	talkingBook.playbackRate = [[updatedSettings valueForKeyPath:@"Book.Rate"] floatValue];
	talkingBook.playbackVolume = [[updatedSettings valueForKeyPath:@"Book.Volume"] floatValue];
	talkingBook.preferredVoice = [updatedSettings valueForKeyPath:@"Book.Voice"];
*/
 
 }

- (void)populateRecentFilesMenu
{
	/*
	int i;
	NSInteger items = [openRecentMenu numberOfItems] -1;
	if(items > 1)
	{ 
		for(i = 0; i < items ; i++)
			[openRecentMenu removeItemAtIndex:0];
	}
	*/
	NSArray *bookTitles = [_recentBooks valueForKeyPath:@"Book.Title"];
	
	for(NSString *aTitle in bookTitles)
	{
		[openRecentMenu addItemWithTitle:aTitle action:NULL keyEquivalent:@""];
		
	}
/*	
	for(NSDictionary *bookSettings in _recentBooks)
	{
		
		//NSString *keyPath = [NSString stringWithFormat:@"%@.Title",[[bookSettings allKeys] objectAtIndex:0]];
		NSLog(@"%@",[bookSettings valueForKey:@"Title"]);
		NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:[bookSettings valueForKey:@"Title"] action:NULL keyEquivalent:@""];
		[openRecentMenu addItem:newItem];
	}
 */
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
