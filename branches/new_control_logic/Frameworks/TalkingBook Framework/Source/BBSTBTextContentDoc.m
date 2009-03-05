//
//  BBSTBTextContentDoc.m
//  TalkingBook Framework
//
//  Created by Kieren Eaton on 31/08/08.
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

#import "BBSTBTextContentDoc.h"
#import "BBSTBSharedBookData.h"
#import <AppKit/NSSpeechSynthesizer.h>

@implementation BBSTBTextContentDoc

- (id) init
{
	if (!(self=[super init])) return nil;
		
	textSynth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
	[textSynth setDelegate:self];
	
	bookData = [BBSTBSharedBookData sharedInstance];
	
	return self;
}

- (void) dealloc
{
	if([textSynth isSpeaking])
		[textSynth stopSpeaking];
	
	[textSynth release];
	
	[xmlTextContentDoc release];
	
	[super dealloc];
}


- (BOOL)openWithContentsOfURL:(NSURL *)fileURL
{
	BOOL loadedOk = NO;
	
	NSError *theError;
	
	// open the validated URL
	xmlTextContentDoc = [[NSXMLDocument alloc] initWithContentsOfURL:fileURL options:NSXMLDocumentTidyXML error:&theError];
	
	if(xmlTextContentDoc)
	{
		loadedOk = YES;
	}
	else // we got a nil return so display the error to the user
	{
		NSAlert *theAlert = [NSAlert alertWithError:theError];
		[theAlert setMessageText:NSLocalizedString(@"Error Opening Textual Content", @"text open fail alert short msg")];
		[theAlert setInformativeText:NSLocalizedString(@"Failed to open textual content file.\n Please check book structure or try another book.", @"text open fail alert long msg")];
		[theAlert beginSheetModalForWindow:[NSApp keyWindow] 
							 modalDelegate:nil 
							didEndSelector:nil 
							   contextInfo:nil];
	}
	
	
	return loadedOk;
}

- (NSString *)stringForXquery:(NSString *)aQuery ofNode:(NSXMLNode *)theNode
{
	return [[theNode objectsForXQuery:aQuery error:nil] objectAtIndex:0];
}

#pragma mark -
#pragma mark Subclass Overridden Methods

- (BOOL)processMetadata
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}


@end
