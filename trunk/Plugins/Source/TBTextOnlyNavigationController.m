//
//  TBTextOnlyNavigationController.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 3/07/09.
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
#import "TBTextOnlyNavigationController.h"
#import "TBOPFDocument.h"
#import "TBNCXDocument.h"
#import "TBSMILDocument.h"

@interface TBTextOnlyNavigationController ()



@end


@implementation TBTextOnlyNavigationController

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
	
	
	if(controlDocument)
	{
		
		NSString *filename = [controlDocument contentFilenameFromCurrentNode];
		if([[filename pathExtension] isEqualToString:@"smil"])
		{
			if(!smilDocument)
				smilDocument = [[TBSMILDocument alloc] init];
			
			// check if the smil file REALLY needs to be loaded
			// Failsafe for single smil books 
			if(![currentSmilFilename isEqualToString:filename])
			{
				currentSmilFilename = [filename copy];
				[smilDocument openWithContentsOfURL:[NSURL URLWithString:currentSmilFilename relativeToURL:bookData.folderPath]];
			}
			
			filename = [smilDocument relativeTextFilePath];
			
			if(!textDocument)
				textDocument = [[TBTextContentDoc alloc] init];
			
			if(![currentTextFilename isEqualToString:filename])
			{
				currentTextFilename = [filename copy];
				[textDocument openWithContentsOfURL:[NSURL URLWithString:currentTextFilename relativeToURL:bookData.folderPath]];
			}
		}
		else
		{
			// no smil filename so look for the text filename in the control document
			
		}
		
	}
	else if(packageDocument)
	{
		// setup for package navigation
	}
	
	[[bookData talkingBookSpeechSynth] setDelegate:self];
}

- (void)resetController
{
	
	currentSmilFilename = nil;
	currentTextFilename = nil;
	currentTag = nil;
	_didUserNavigation = NO;
	_isSpeaking = NO;
	
	// call the supers resetController method which
	// will remove us from the notification center
	[super resetController];
	
	
}

#pragma mark -
#pragma mark Private Methods

- (void)startPlayback
{
	if(_isSpeaking && !bookData.isPlaying)
		[[bookData talkingBookSpeechSynth] continueSpeaking];
	else
		[[bookData talkingBookSpeechSynth] startSpeakingString:[textDocument contentText]];
	
	bookData.isPlaying = YES;
}

- (void)stopPlayback
{
	_isSpeaking = [[bookData talkingBookSpeechSynth] isSpeaking];
	[[bookData talkingBookSpeechSynth] pauseSpeakingAtBoundary:NSSpeechWordBoundary];
	
	bookData.isPlaying = NO;
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success
{
	if(smilDocument && success)
	{	
		[smilDocument nextTextPlaybackPoint];
		
	}
	
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender willSpeakWord:(NSRange)wordToSpeak ofString:(NSString *)text
{
	
	// send a notifcation or tell the web/text view to 
	//highlight the current word about to be spoken
	NSString *wordIs = [text substringWithRange:wordToSpeak];
	NSLog(@"speaking -> %@",wordIs);
}


@end
