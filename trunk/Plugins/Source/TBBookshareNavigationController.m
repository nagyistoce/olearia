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
		[mainSpeechSynth setDelegate:self];
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
				self.currentSmilFilename = filename;
				[smilDocument openWithContentsOfURL:[NSURL URLWithString:currentSmilFilename relativeToURL:bookData.baseFolderPath]];
			}
			
			// set the smil file to the correct start point for navigation and playback
			self.currentTag = [controlDocument currentIdTag];
			[smilDocument jumpToNodeWithIdTag:currentTag];
			
			filename = [smilDocument relativeTextFilePath];
			if(filename)
			{
				if(!textDocument)
					textDocument = [[TBBookshareTextContentDoc alloc] init];
				
				if(![currentTextFilename isEqualToString:filename])
				{
					self.currentTextFilename = filename;
					[textDocument openWithContentsOfURL:[NSURL URLWithString:currentTextFilename relativeToURL:bookData.baseFolderPath]];
				}
				[textDocument jumpToNodeWithIdTag:currentTag];
				[textDocument updateDataAfterJump];
				self.contentToSpeak = [[textDocument contentText] copy];
			}
			else // no audio filenames found 
			{
				
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
	
//	if(controlDocument)
//	{
//		// depending on how the Bookshare book was authored there will be 
//		// one of 2 types of initial SMIL item
//		NSString *smilFilename = [packageDocument stringForXquery:@"(/package[1]/manifest[1]/((item[@id='SMIL'])|(item[@id='SMIL1'])))/data(@href)" ofNode:nil];
//		// do a sanity check on the extension
//		if([[smilFilename pathExtension] isEqualToString:@"smil"])
//		{
//			// check if the smil instance has been loaded
//			if(!smilDocument)
//				smilDocument = [[TBSMILDocument alloc] init];
//			
//			// check if the smil file REALLY needs to be loaded
//			// Failsafe for single smil books 
//			if(![_currentSmilFilename isEqualToString:smilFilename])
//			{
//				_currentSmilFilename = [smilFilename copy];
//				[smilDocument openWithContentsOfURL:[NSURL URLWithString:_currentSmilFilename relativeToURL:bookData.baseFolderPath]];
//			}
//		}
//		
//		// set the smil file to the correct start point for navigation and playback
//		_currentTag = [controlDocument currentIdTag];
//		[smilDocument jumpToNodeWithIdTag:_currentTag];
//		
//		
//		// load the text content document
//		if(nil != packageDocument.textContentFilename) 
//		{
//			if(!textDocument)
//				textDocument = [[TBBookshareTextContentDoc alloc] init];
//			
//			if(![_currentTextFilename isEqualToString:packageDocument.textContentFilename])
//			{
//				_currentTextFilename = [[packageDocument textContentFilename] copy];
//				[textDocument openWithContentsOfURL:[NSURL URLWithString:_currentTextFilename relativeToURL:bookData.baseFolderPath]];
//			}
//			[textDocument jumpToNodeWithIdTag:_currentTag];
//			_contentToSpeak = [textDocument contentText];
//			[self updateAfterNavigationChange];
//			
//		}
//		
//	}
	
	
}

#pragma mark -
#pragma mark Private Methods

//- (void)startPlayback
//{
//	if(_mainSynthIsSpeaking && !bookData.isPlaying)
//		[mainSpeechSynth continueSpeaking];
//	else
//		[mainSpeechSynth startSpeakingString:[textDocument contentText]];
//	
//	bookData.isPlaying = YES;
//}

//- (void)stopPlayback
//{
//	_mainSynthIsSpeaking = [mainSpeechSynth isSpeaking];
//	[mainSpeechSynth pauseSpeakingAtBoundary:NSSpeechWordBoundary];
//	
//	bookData.isPlaying = NO;
//}


//- (void)nextElement
//{
//	if(controlDocument)
//	{	
//		[controlDocument moveToNextSegmentAtSameLevel];
//		_currentTag = [controlDocument currentIdTag];
//	}
//	
//	//if(smilDocument)
////	{
////		[smilDocument nextTextPlaybackPoint];
////		[smilDocument updateAfterPositionChange];
////		_currentTag = [smilDocument currentIdTag];
////	}
//	
//	_didUserNavigationChange = YES;
//
//	if(bookData.isPlaying)
//	{
//		if ([mainSpeechSynth isSpeaking]) 
//		{
//			[mainSpeechSynth pauseSpeakingAtBoundary:NSSpeechWordBoundary];
//		}
//		[textDocument jumpToNodeWithIdTag:_currentTag];
//		[textDocument updateDataAfterJump];
//		_contentToSpeak = [textDocument contentText];
//		[mainSpeechSynth startSpeakingString:_contentToSpeak];
//	}
//	
//}
//
//- (void)previousElement
//{
//	if(smilDocument)
//	{
//		[smilDocument previousTextPlaybackPoint];
//		_currentTag = [smilDocument currentIdTag];
//	}	
//	_didUserNavigationChange = YES;
//	
//	//[super updateAfterNavigationChange];
//	
//	[textDocument updateDataAfterJump];
//	//[textDocument startSpeakingFromIdTag:_currentTag];
//}

- (void)goUpLevel
{
	if(controlDocument)
	{	
		[controlDocument goUpALevel];
		self.currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigationChange = YES;
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
		self.currentTag = [controlDocument currentIdTag];
	}
	_didUserNavigationChange = YES;
	_mainSynthIsSpeaking = NO;
	[self updateAfterNavigationChange];
	
	[textDocument jumpToNodeWithIdTag:currentTag];
	[textDocument updateDataAfterJump];
	
	[self speakLevelChange];
	
}


@end

@implementation TBBookshareNavigationController (SpeechDelegate)

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success
{
	if(sender == mainSpeechSynth)
	{	
		if (!_didUserNavigationChange)// auto play
		{
			if(controlDocument)
			{
				[controlDocument moveToNextSegment];
				self.currentTag = [controlDocument currentIdTag];
				//[controlDocument updatea
				[textDocument jumpToNodeWithIdTag:currentTag];
				[textDocument updateDataForCurrentPosition];
				self.contentToSpeak = [[textDocument contentText] copy];
				[self startPlayback];
				
			}
			
		}
		else // user navigation
		{
			//if (smilDocument)
//			{
//				[smilDocument nextTextPlaybackPoint];
//				_currentTag = [smilDocument currentIdTag];
//							
//			}
			_didUserNavigationChange = NO;
			[self startPlayback];
		}

		
		//		if(_mainSynthIsSpeaking)
		//			[mainSpeechSynth continueSpeaking];
		//				else
		//				{	
		//				if(!_didUserNavigationChange)
		//					[[NSNotificationCenter defaultCenter] postNotificationName:TBAuxSpeechConDidFinishSpeaking object:self];
		//					else
		//					{	
		//						_didUserNavigationChange = NO;
		//					[[NSNotificationCenter defaultCenter] postNotificationName:TBAuxSpeechConDidFinishSpeaking object:self];
		//				}
		
		
		
	}
	
	
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender willSpeakWord:(NSRange)wordToSpeak ofString:(NSString *)text
{
	//	if(sender == mainSpeechSynth)
	//	{
	//		//NSLog(@"word num is %d",wordToSpeak.location);
	//	}
	// send a notifcation or tell the web/text view to 
	//highlight the current word about to be spoken
	//NSString *wordIs = [text substringWithRange:wordToSpeak];
	//NSLog(@"speaking -> %@",wordIs);
}


@end

