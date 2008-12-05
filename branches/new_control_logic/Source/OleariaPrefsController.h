//
//  OleariaPrefsController.h
//  Olearia
//
//  Created by Kieren Eaton on 21/08/08.
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

@interface OleariaPrefsController : NSWindowController 
{
	NSArray					*availableVoices;
		
	IBOutlet NSPopUpButton	*voicesPopup;
	IBOutlet NSButton		*highContrastCheckBox;
	
	IBOutlet NSWindow		*prefsWindow;
	IBOutlet NSView			*soundPrefsView;
	IBOutlet NSView			*textPrefsView;
	IBOutlet NSView			*voicePrefsView;
	IBOutlet NSView			*generalPrefsView;
	
	
}

- (IBAction)displaySoundPrefsView:(id)sender;
- (IBAction)displayTextPrefsView:(id)sender;
- (IBAction)displayVoicePrefsView:(id)sender;
- (IBAction)displayGeneralPrefsView:(id)sender;
- (IBAction)setSelectedPlaybackVoice:(id)sender;
- (IBAction)toggleHighContrastIcons:(id)sender;

@end
