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
				[smilDocument openWithContentsOfURL:[NSURL URLWithString:currentSmilFilename relativeToURL:bookData.baseFolderPath]];
			}
			
			filename = [smilDocument relativeTextFilePath];
			
			if(!textDocument)
				textDocument = [[TBTextContentDoc alloc] init];
			
			if(![currentTextFilename isEqualToString:filename])
			{
				currentTextFilename = [filename copy];
				[textDocument openWithContentsOfURL:[NSURL URLWithString:currentTextFilename relativeToURL:bookData.baseFolderPath]];
			}
			[noteCentre addObserver:self
						   selector:@selector(startPlayback)
							   name:TBAuxSpeechConDidFinishSpeaking
							 object:speechCon];

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

- (void)nextElement
{
	if(controlDocument)
	{	
		[controlDocument moveToNextSegmentAtSameLevel];
		currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigation = YES;
	
	[super updateAfterNavigationChange];

	[textDocument startSpeakingFromIdTag:currentTag];
}

- (void)previousElement
{
	if(controlDocument)
	{	
		[controlDocument moveToPreviousSegment];
		currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigation = YES;
	
	[super updateAfterNavigationChange];
	
	[textDocument startSpeakingFromIdTag:currentTag];
}

- (void)goUpLevel
{
	if(controlDocument)
	{	
		[controlDocument goUpALevel];
		currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigation = YES;
	_isSpeaking = NO;
	[self updateAfterNavigationChange];
	
	[textDocument jumpToNodeWithIdTag:currentTag];
	[textDocument updateDataAfterJump];
	
	[speechCon speakUserLevelChange];

	
}

- (void)goDownLevel
{
	if(controlDocument)
	{	
		[controlDocument goDownALevel];
		currentTag = [controlDocument currentIdTag];
	}
	_didUserNavigation = YES;
	_isSpeaking = NO;
	[self updateAfterNavigationChange];
	
	[textDocument jumpToNodeWithIdTag:currentTag];
	[textDocument updateDataAfterJump];
	
	[speechCon speakUserLevelChange];
	
}

- (void)moveControlPoint:(NSString *)aNodePath withTime:(NSString *)aTime
{
	// the control document will always be our first choice for navigation
	if(controlDocument)
	{	
		[controlDocument jumpToNodeWithPath:aNodePath];
		currentTag = [controlDocument currentIdTag];
	}
	else if(packageDocument)
	{
		// need to add navigation methods for package documents
	}
	
	_didUserNavigation = YES;
	
	[textDocument jumpToNodeWithIdTag:currentTag];
	
	[self updateAfterNavigationChange];
	[textDocument updateDataAfterJump];
	
}

- (NSString *)currentNodePath
{
	if(controlDocument)
		return [controlDocument currentPositionID];
	
	return nil;
}

- (NSString *)currentTime
{	
	// return nil as there is no time sig in textOnly
	// books
	
	return nil;
}

- (void)updateAfterNavigationChange
{
	
	[textDocument updateDataForCurrentPosition];
	
}

@end
