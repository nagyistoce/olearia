//
//  TBSpeechController.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 28/07/09.
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

NSString * const TBSpeechConDidFinishSpeaking = @"TBSpeechConDidFinishSpeaking";

#import "TBSpeechController.h"

@implementation TBSpeechController

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		bookData = [TBBookData sharedBookData];

		auxSpeechSynth = [[[NSSpeechSynthesizer alloc] initWithVoice:bookData.preferredVoiceIdentifier] retain];
		[auxSpeechSynth setDelegate:self];
		
		[bookData addObserver:self 
				   forKeyPath:PreferredSynthesizerVoice
					  options:NSKeyValueObservingOptionNew
					  context:NULL];
		
	}
	return self;
}

- (void) dealloc
{
	[bookData removeObserver:self forKeyPath:PreferredSynthesizerVoice];
	[auxSpeechSynth release];
	
	[super dealloc];
}

- (void)speakLevelChange
{
	if(bookData.speakUserLevelChange)
	{	
		[auxSpeechSynth startSpeakingString:[NSString stringWithFormat:@"Level %d",bookData.currentLevel]];
	}
}

#pragma mark -
#pragma mark KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([keyPath isEqualToString:PreferredSynthesizerVoice])	
		[auxSpeechSynth setVoice:bookData.preferredVoiceIdentifier];
}


- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success
{
	if(sender == auxSpeechSynth && success)
	{	
		[[NSNotificationCenter defaultCenter] postNotificationName:TBSpeechConDidFinishSpeaking object:self];
	}
}

@end
