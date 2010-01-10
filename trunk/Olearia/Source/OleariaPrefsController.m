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
#import <TalkingBook/TBTalkingBook.h>

@implementation OleariaPrefsController


- (void)setupToolbar
{
	[self addView:generalPrefsView label:NSLocalizedString(@"General",@"General Toolbar item title")];
	[self addView:soundPrefsView label:NSLocalizedString(@"Sound",@"Sound Toolbar item title")];
	[self addView:voicePrefsView label:NSLocalizedString(@"Voice",@"Voice Toolbar item title")];
	//[self addView:textPrefsView label:NSLocalizedString(@"Text",@"Text Toolbar item title")];

	
}


- (void) dealloc
{
	[_availableVoices release];
	
	[super dealloc];
}


- (void)windowDidLoad
{	
	
	// get all the identifiers and names of the available voices
	NSMutableArray *someVoices = [[[NSMutableArray alloc] init] autorelease];
	for(NSString *voiceIdentifier in [NSSpeechSynthesizer availableVoices])
	{
		NSString *voiceName = [[NSSpeechSynthesizer attributesForVoice:voiceIdentifier] objectForKey:NSVoiceName];
		NSDictionary *voiceAtts = [[NSDictionary alloc] initWithObjectsAndKeys:voiceIdentifier,@"identifier",voiceName,@"name",nil];
		
		[someVoices addObject:voiceAtts];
	}
	
	
	_availableVoices = [[NSArray arrayWithArray:someVoices] retain]; 
	[voicesArrayController setContent:_availableVoices];
	
	[super windowDidLoad];
}



#pragma mark -
#pragma mark Action Methods


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

- (IBAction)setNewSkipDuration:(id)sender
{
	[[[NSApp delegate] talkingBook] setAudioSkipDuration:([sender doubleValue] * (double)60)];
}

#pragma mark -


- (void)relaunchAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(NSAlertFirstButtonReturn == returnCode)
	{
		[[NSApp delegate] doRelaunch];
	}
}

@end
