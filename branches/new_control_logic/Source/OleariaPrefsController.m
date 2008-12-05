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

//@interface OleariaPrefsController(Private)

//- (void)relaunchAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;

//@end


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
	[[prefsWindow contentView] addSubview:generalPrefsView];
	
	[voicesPopup removeAllItems];
	// populate the voices popup with the names of all the voices available.
	for(NSString *voiceTitle in availableVoices)
	{	
		NSDictionary *voiceAttribs = [NSSpeechSynthesizer attributesForVoice:voiceTitle];
		[voicesPopup addItemWithTitle:[voiceAttribs objectForKey:NSVoiceName]];
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	// get the name of the voice the user set
	NSString *voiceName = [[NSSpeechSynthesizer attributesForVoice:[defaults objectForKey:OleariaPlaybackVoice]] objectForKey:NSVoiceName];
	// select the voicename in the popup
	[voicesPopup selectItemWithTitle:voiceName];
	
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

- (IBAction)displayVoicePrefsView:(id)sender
{
	NSView * currentView = [[[prefsWindow contentView] subviews] objectAtIndex:0];
	if(currentView != voicePrefsView)
	{
		[[NSAnimationContext currentContext] setDuration:0.5];
		[[[prefsWindow contentView] animator] replaceSubview:currentView with:voicePrefsView];
	}
	
	
}

- (IBAction)displayGeneralPrefsView:(id)sender
{
	NSView * currentView = [[[prefsWindow contentView] subviews] objectAtIndex:0];
	if(currentView != generalPrefsView)
	{
		[[NSAnimationContext currentContext] setDuration:0.5];
		[[[prefsWindow contentView] animator] replaceSubview:currentView with:generalPrefsView];
	}
	
	
}


- (IBAction)setSelectedPlaybackVoice:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setObject:[availableVoices objectAtIndex:[sender indexOfSelectedItem]] forKey:OleariaPlaybackVoice];
	[defaults synchronize];
}

- (IBAction)toggleHighContrastIcons:(id)sender
{
	// put up a dialog the user if they would like to relaunch the app with the new icons.
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:NSLocalizedString(@"Relaunch Required",@"relaunch required short msg")];
	[alert setInformativeText:NSLocalizedString(@"This setting will take effect on the next launch.",@"relaunch alert long msg")];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setIcon:[NSImage imageNamed:@"olearia.icns"]];
	[alert addButtonWithTitle:NSLocalizedString(@"Relaunch Now", @"relaunch alert button 1")];
	 [alert addButtonWithTitle:NSLocalizedString(@"Continue without relaunch", @"relaunch alert button 2")]; 
	[alert beginSheetModalForWindow:[self window] 
					  modalDelegate:self
					 didEndSelector:@selector(relaunchAlertDidEnd:returnCode:contextInfo:)
						contextInfo:nil];
	
	 
}

- (void)relaunchAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(NSAlertFirstButtonReturn == returnCode)
	{
		[[NSApp delegate] doRelaunch];
	}
}
@end
