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

#import "TBSpeechController.h"
#import "TBNavigationController.h"

@implementation TBSpeechController

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		bookData = [TBBookData sharedBookData];
		
		_audioIsPlaying = NO;
		_mainIsSpeaking = NO;
		
		_auxSpeechSynth = [[[NSSpeechSynthesizer alloc] initWithVoice:bookData.preferredVoice] retain];
		[_auxSpeechSynth setDelegate:self];
		
		[bookData addObserver:self 
				   forKeyPath:@"preferredVoice"
					  options:NSKeyValueObservingOptionNew
					  context:NULL];
		
	}
	return self;
}

- (void) dealloc
{
	[_auxSpeechSynth release];
	
	[super dealloc];
}

- (void)speakLevelChange
{
	if(bookData.speakUserLevelChange)
	{	
		_mainIsSpeaking = [[bookData talkingBookSpeechSynth] isSpeaking];
		
		if(_mainIsSpeaking)
			[[bookData talkingBookSpeechSynth] stopSpeaking];
		
		if(bookData.isPlaying)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:TBStdPluginShouldStopPlayback object:nil ];
			_audioIsPlaying = YES;
		}
		
		[_auxSpeechSynth startSpeakingString:[NSString stringWithFormat:@"Level %d",bookData.currentLevel]];
	}
		

}

#pragma mark -
#pragma mark KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([keyPath isEqualToString:@"preferredVoice"])	
		[_auxSpeechSynth setVoice:bookData.preferredVoice];
	else
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
}


- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success
{
	if(sender == _auxSpeechSynth)
	{	
		if(_mainIsSpeaking)
			[[bookData talkingBookSpeechSynth] continueSpeaking];
		else if(_audioIsPlaying)
			[[NSNotificationCenter defaultCenter] postNotificationName:TBStdPluginShouldStartPlayback object:nil];
	}
			
	
}

@end
