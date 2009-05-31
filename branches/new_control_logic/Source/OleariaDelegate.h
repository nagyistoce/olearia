//
//  OleariaDelegate.h
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

#import <Cocoa/Cocoa.h>
#import <TalkingBook/TBTalkingBook.h>

@class OleariaPrefsController, AboutBoxController;

extern NSString * const OleariaPlaybackVolume;
extern NSString * const OleariaPlaybackRate;
extern NSString * const OleariaPlaybackVoice;
extern NSString * const OleariaUseVoiceForPlayback;
extern NSString * const OleariaChapterSkipIncrement;
extern NSString * const OleariaEnableVoiceOnLevelChange;
extern NSString * const OleariaShouldOpenLastBookRead;
extern NSString * const OleariaShouldUseHighContrastIcons;
extern NSString * const OleariaIgnoreBooksOnRemovableMedia;
extern NSString * const OleariaShouldRelaunchNotification;

@interface OleariaDelegate : NSObject
{
	NSArray				*validFileTypes;
	TBTalkingBook		*talkingBook;
	
	OleariaPrefsController *_prefsController;
	AboutBoxController	*_aboutController;
	NSMutableArray		*_recentBooks; 
	NSUserDefaults		*_userSetDefaults;
	
	NSString			*_recentBooksPlistPath;
	
	BOOL				shouldReLaunch;

	NSRect				navBoxOrigSize;
	NSRect				toolBoxOrigSize;
	
	IBOutlet NSWindow	*mainWindow;
	
	IBOutlet NSView			*soundView;
	IBOutlet NSView			*toolsView;
	IBOutlet NSBox			*toolsBox;
	
	IBOutlet NSButton		*playPauseButton;
	IBOutlet NSButton		*nextButton;
	IBOutlet NSButton		*prevButton;
	IBOutlet NSButton		*upLevelButton;
	IBOutlet NSButton		*downLevelButton;
	IBOutlet NSButton		*fastForwardButton;
	IBOutlet NSButton		*fastBackButton;
	IBOutlet NSButton		*infoButton;
	IBOutlet NSButton		*bookmarkButton;
	IBOutlet NSButton		*gotoPageButton;
	
	IBOutlet NSMenuItem		*playPauseMenuItem;
	IBOutlet NSMenuItem		*minimizeMenuItem;
	IBOutlet NSMenu			*recentBooksMenu;
	
}

- (void)doRelaunch;
- (IBAction)displayPrefsPanel:(id)sender;
- (IBAction)displayAboutPanel:(id)sender;
- (IBAction)showBookInfo:(id)sender;

- (IBAction)openDocument:(id)sender;
- (IBAction)PlayPause:(id)sender;
- (IBAction)upLevel:(id)sender;
- (IBAction)downLevel:(id)sender;
- (IBAction)nextSegment:(id)sender;
- (IBAction)previousSegment:(id)sender;
- (IBAction)fastForward:(id)sender;
- (IBAction)fastRewind:(id)sender;
- (IBAction)gotoPage:(id)sender;
- (IBAction)getInfo:(id)sender;
- (IBAction)addBookmark:(id)sender;

- (IBAction)setPlaybackSpeed:(NSSlider *)sender;
- (IBAction)setPlaybackVolume:(NSSlider *)sender;

- (IBAction)showBookmarks:(id)sender;

@property (readwrite,retain) TBTalkingBook *talkingBook;

@end
