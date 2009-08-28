//
//  TBBookshareNavigationController.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 25/08/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
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

#import "TBBookshareNavigationController.h"
#import "TBOPFDocument.h"
#import "TBNCXDocument.h"
#import "TBSMILDocument.h"
#import "TBBookshareTextContentDoc.h"

@interface TBBookshareNavigationController ()



@end


@implementation TBBookshareNavigationController

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		
	}
	
	return self;
}

- (void) dealloc
{
	
	[super dealloc];
}

- (void)prepareForPlayback
{
	[self resetController];
	
	if(packageDocument)
	{
		
		NSString *smilFilename = [packageDocument stringForXquery:@"(/package[1]/manifest[1]/item[@id='SMIL']|/package[1]/manifest[1]/item[@id='SMIL1'])/data(@href)" ofNode:nil];
		// do a sanity check on the extension
		if([[smilFilename pathExtension] isEqualToString:@"smil"])
		{
			if(!smilDocument)
				smilDocument = [[TBSMILDocument alloc] init];
			
			// check if the smil file REALLY needs to be loaded
			// Failsafe for single smil books 
			if(![currentSmilFilename isEqualToString:smilFilename])
			{
				currentSmilFilename = [smilFilename copy];
				[smilDocument openWithContentsOfURL:[NSURL URLWithString:currentSmilFilename relativeToURL:bookData.folderPath]];
			}
		}
		
		// load the text content document
		if(nil != packageDocument.textContentFilename) 
		{
			if(!textDocument)
				textDocument = [[TBBookshareTextContentDoc alloc] init];
			
			if(![currentTextFilename isEqualToString:packageDocument.textContentFilename])
			{
				currentTextFilename = [[packageDocument textContentFilename] copy];
				[textDocument openWithContentsOfURL:[NSURL URLWithString:currentTextFilename relativeToURL:bookData.folderPath]];
			}
			
			[noteCentre addObserver:self
						   selector:@selector(startPlayback)
							   name:TBAuxSpeechConDidFinishSpeaking
							 object:speechCon];
		}
		
	}
	
	
}

- (void)resetController
{	
	// call the supers resetController method which
	// will remove us from the notification center
	// and reset all our local ivars
	[super resetController];
}

#pragma mark -
#pragma mark Private Methods

- (void)startPlayback
{
	if(_isSpeaking && !bookData.isPlaying)
		[[bookData talkingBookSpeechSynth] continueSpeaking];
	else
		[textDocument startSpeaking];
	
	bookData.isPlaying = YES;
}

- (void)stopPlayback
{
	_isSpeaking = [[bookData talkingBookSpeechSynth] isSpeaking];
	[[bookData talkingBookSpeechSynth] pauseSpeakingAtBoundary:NSSpeechWordBoundary];
	
	bookData.isPlaying = NO;
}




@end
