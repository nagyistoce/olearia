//
//  OleariaPrefsController.m
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


#import "OleariaPrefsController.h"
#import "OleariaDelegate.h"

@implementation OleariaPrefsController

- (id) init
{
	if (![super initWithWindowNibName:@"Preferences"]) return nil;

	availableVoices = [NSSpeechSynthesizer availableVoices];
			
	return self;
}

- (void)windowDidLoad
{
	[prefsWindow makeKeyWindow];
	[[prefsWindow contentView] addSubview:soundPrefsView];
	
	[voicesPopup removeAllItems];
	for(NSString *voiceTitle in availableVoices)
	{	
		NSDictionary *voiceAttribs = [NSSpeechSynthesizer attributesForVoice:voiceTitle];
		[voicesPopup addItemWithTitle:[voiceAttribs objectForKey:NSVoiceName]];
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[voicesPopup selectItemWithTitle:[defaults objectForKey:OleariaPlaybackVoice]];

}

#pragma mark -
#pragma mark Action Methods

- (IBAction)displaySoundPrefsView:(id)sender
{
	NSView * currentView = [[[prefsWindow contentView] subviews] objectAtIndex:0];
	if(currentView != soundPrefsView)
	{
		[[NSAnimationContext currentContext] setDuration:0.5];
		[[[prefsWindow contentView] animator] replaceSubview:currentView with:soundPrefsView];
	}
	
}

- (IBAction)displayTextPrefsView:(id)sender
{
	NSView * currentView = [[[prefsWindow contentView] subviews] objectAtIndex:0];
	if(currentView != textPrefsView)
	{

		[[NSAnimationContext currentContext] setDuration:0.5];
		[[[prefsWindow contentView] animator] replaceSubview:currentView with:textPrefsView];

	}
	
}

- (IBAction)toggleAudioOverride:(id)sender
{
	
}

- (IBAction)setSelectedPlaybackVoice:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setObject:[availableVoices objectAtIndex:[sender indexOfSelectedItem]] forKey:OleariaPlaybackVoice];
	[defaults synchronize];
}

@end
