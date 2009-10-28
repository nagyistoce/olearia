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
		// depending on how the Bookshare book was authored there will be 
		// one of 2 types of initial SMIL item
		NSString *smilFilename = [packageDocument stringForXquery:@"(/package[1]/manifest[1]/item[@id='SMIL']|/package[1]/manifest[1]/item[@id='SMIL1'])/data(@href)" ofNode:nil];
		// do a sanity check on the extension
		if([[smilFilename pathExtension] isEqualToString:@"smil"])
		{
			// check if the smil instance has been loaded
			if(!smilDocument)
				smilDocument = [[TBSMILDocument alloc] init];
			
			// check if the smil file REALLY needs to be loaded
			// Failsafe for single smil books 
			if(![currentSmilFilename isEqualToString:smilFilename])
			{
				currentSmilFilename = [smilFilename copy];
				[smilDocument openWithContentsOfURL:[NSURL URLWithString:currentSmilFilename relativeToURL:bookData.baseFolderPath]];
			}
		}
		
		// set the smil file to the correct start point for navigation and playback
		currentTag = [controlDocument currentIdTag];
		[smilDocument jumpToNodeWithIdTag:currentTag];
		
		
		// load the text content document
		if(nil != packageDocument.textContentFilename) 
		{
			if(!textDocument)
				textDocument = [[TBBookshareTextContentDoc alloc] init];
			
			if(![currentTextFilename isEqualToString:packageDocument.textContentFilename])
			{
				currentTextFilename = [[packageDocument textContentFilename] copy];
				[textDocument openWithContentsOfURL:[NSURL URLWithString:currentTextFilename relativeToURL:bookData.baseFolderPath]];
			}
			
			[textDocument updateDataAfterJump];
			
			
			
			
		}
		
	}
	
	
}

//- (void)resetController
//{	
//	// call the supers resetController method which
//	// will remove us from the notification center
//	// and reset all our local ivars
//	[super resetController];
//}

#pragma mark -
#pragma mark Private Methods

- (void)startPlayback
{
	if(_mainSynthIsSpeaking && !bookData.isPlaying)
		[mainSpeechSynth continueSpeaking];
	else
		[mainSpeechSynth startSpeakingString:[textDocument contentText]];
	
	bookData.isPlaying = YES;
}

- (void)stopPlayback
{
	_mainSynthIsSpeaking = [mainSpeechSynth isSpeaking];
	[mainSpeechSynth pauseSpeakingAtBoundary:NSSpeechWordBoundary];
	
	bookData.isPlaying = NO;
}


- (void)nextElement
{
//	if(controlDocument)
//	{	
//		[controlDocument moveToNextSegmentAtSameLevel];
//		currentTag = [controlDocument currentIdTag];
//	}
	
	if(smilDocument)
	{
		[smilDocument nextTextPlaybackPoint];
		[smilDocument updateAfterPositionChange];
		currentTag = [smilDocument currentIdTag];
	}
	
	//m_didUserNavigationChange = YES;
	
	//[super updateAfterNavigationChange];

	if(bookData.isPlaying)
	{
		//[textDocument updateDataAfterJump];
		
		//[textDocument startSpeakingFromIdTag:currentTag];
	}
	
}

- (void)previousElement
{
	if(smilDocument)
	{
		[smilDocument previousTextPlaybackPoint];
		currentTag = [smilDocument currentIdTag];
	}	
	m_didUserNavigationChange = YES;
	
	//[super updateAfterNavigationChange];
	
	[textDocument updateDataAfterJump];
	//[textDocument startSpeakingFromIdTag:currentTag];
}

- (void)goUpLevel
{
	if(controlDocument)
	{	
		[controlDocument goUpALevel];
		currentTag = [controlDocument currentIdTag];
	}
	
	m_didUserNavigationChange = YES;
	_mainSynthIsSpeaking = NO;
	[self updateAfterNavigationChange];
	
	[textDocument jumpToNodeWithIdTag:currentTag];
	[textDocument updateDataAfterJump];
	
	[self speakLevelChange];

	
}

- (void)goDownLevel
{
	if(controlDocument)
	{	
		[controlDocument goDownALevel];
		currentTag = [controlDocument currentIdTag];
	}
	m_didUserNavigationChange = YES;
	_mainSynthIsSpeaking = NO;
	[self updateAfterNavigationChange];
	
	[textDocument jumpToNodeWithIdTag:currentTag];
	[textDocument updateDataAfterJump];
	
	[self speakLevelChange];
	
}


@end
