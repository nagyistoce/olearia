//
//  TBBookshareTextContentDoc.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 13/07/09.
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

#import "TBBookshareTextContentDoc.h"
#import "NSXMLNode-TBAdditions.h"

@interface TBBookshareTextContentDoc ()


@end

@interface TBBookshareTextContentDoc (Private)

- (NSUInteger)itemsOnCurrentLevel;
- (NSUInteger)itemIndexOnCurrentLevel;
- (BOOL)isHeadingNode:(NSXMLNode *)aNode;
//- (BOOL)moveToNextSuitableNode;

@end


@implementation TBBookshareTextContentDoc

- (id)init
{
	if (!(self=[super init])) return nil;
	
	//bookData = [TBBookData sharedBookData];
//	
//	
//	singleSpecifiers = [[NSArray arrayWithObjects:@"pagenum",@"sent",@"img",@"prodnote",@"caption",nil] retain];
//	prefixSpecifiers = [[NSArray arrayWithObjects:@"level",@"h",nil] retain];
//	groupSpecifiers = [[NSArray arrayWithObjects:@"p",@"imggroup",nil] retain];
//	
//	[[bookData talkingBookSpeechSynth] setDelegate:self];
	
	return self;
}

- (void) dealloc
{
//	[singleSpecifiers release];
//	[prefixSpecifiers release];
//	[xmlTextDoc release];
	
	[super dealloc];
}


@end

@implementation TBBookshareTextContentDoc (Synchronization)


@end


@implementation TBBookshareTextContentDoc (Navigation)



- (void)moveToNextSegmentAtSameLevel
{
	NSLog(@"bookshare move to next segent at this level");
	// this only used when the user chooses to go to the next file on a given level
//	currentNavPoint = [currentNavPoint nextSibling];
//	[self updateDataForCurrentPosition];
}

- (void)moveToPreviousSegment
{
	
//		BOOL foundNode = NO;
//	
//	if(NO == navigateForChapters)
//	{
//		// we have a node on this level
//		currentNavPoint = [currentNavPoint previousSibling];
//	}
//	else
//	{
//		// we only make it here if we are travelling backwards across segments
//		
//		// reset the flag
//		navigateForChapters = NO;
//		
//		// look back through the previous nodes for a navpoint
//		while(NO == foundNode)
//		{
//			currentNavPoint = [currentNavPoint previousNode];
//			if([[currentNavPoint name] isEqualToString:@"navPoint"])
//				foundNode = YES;
//		}
//		
//		
//		//self.bookData.currentLevel = [self levelOfNode:currentNavPoint];
//		
//		
//		
//		
//	}
//	
//	//self.bookData.sectionTitle = [self stringForXquery:@"navLabel/data(text)" ofNode:currentNavPoint];
//
//	[self updateDataForCurrentPosition];
	
}

- (void)goUpALevel
{
	
}

- (void)goDownALevel
{
	
}

@end


@implementation TBBookshareTextContentDoc (Information)

- (BOOL)canGoNext
{
	// return YES if we can go forward in the navmap
	return ([self itemIndexOnCurrentLevel] < ([self itemsOnCurrentLevel] - 1)) ? YES : NO; 
}

- (BOOL)canGoPrev
{
	// return YES if we can go backwards
	return ([self itemIndexOnCurrentLevel] > 0) ? YES : NO;
}

- (BOOL)canGoUpLevel
{
	// return Yes if we are at a lower level
	return (bookData.currentLevel > 1) ? YES : NO;
}

- (BOOL)canGoDownLevel
{
	// return YES if there is level? node as the next node
	NSString *newLevelString = [NSString stringWithFormat:@"level%d",bookData.currentLevel+1];
	return ([[[currentNode nextNode] name] isEqualToString:newLevelString]);
}

@end

@implementation TBBookshareTextContentDoc (Private)

- (NSUInteger)itemsOnCurrentLevel
{
	return [[currentNode parent] childCount]; 
}

- (NSUInteger)itemIndexOnCurrentLevel
{
	// returns an index of the current node relative to the other nodes on the same level
	return [currentNode index];
}


- (BOOL)isHeadingNode:(NSXMLNode *)aNode
{
	NSString *nodeName = [aNode name];
	if((nil != nodeName) && ([nodeName length] >= 2))
	{
		unichar checkChar =  [nodeName characterAtIndex:0];
		unichar levelChar =  [nodeName characterAtIndex:1];
		
		// check if we have a 'h' as the first character which denotes a level header AND the second character is a digit
		return (('h' == checkChar) && (isdigit(levelChar))) ? YES : NO; 

	}
	
	return NO;
}

//- (BOOL)moveToNextSuitableNode
//{
//	BOOL foundNode = NO;
//	NSXMLNode *tempNode = [currentNode nextNode];
//	if(tempNode != nil)
//	{
//		if([tempNode kind] == NSXMLTextKind)
//		{	
//			tempNode = ([currentNode nextSibling]) ? [currentNode nextSibling] : [[currentNode parent] nextSibling];
//			if(tempNode != nil)
//			{
//				currentNode = tempNode;
//				return YES;
//				
//			}
//		}
//		
//		if([groupSpecifiers containsObject:[tempNode name]])
//			currentNode = [tempNode childAtIndex:0];
//		else if([singleSpecifiers containsObject:[tempNode name]])
//		{	
//			currentNode = tempNode;
//			foundNode = YES;
//		}
//		else
//			for(NSString *aPrefix in prefixSpecifiers)
//			{
//				if([[tempNode name] hasPrefix:aPrefix])
//				{
//					currentNode = tempNode;
//					foundNode = YES;
//					break;
//				}
//			}
//	}
//	
//	return foundNode;
//	
//}

//- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success
//{
//	if((sender == bookData.talkingBookSpeechSynth) && (success) && (!endOfBook))
//	{	
//		if([self moveToNextSuitableNode])
//		{	
//			[self updateDataForCurrentPosition];
//			[[bookData talkingBookSpeechSynth] startSpeakingString:contentStr];
//		}
//		else
//		{
//			contentStr = @"End of book.";
//			endOfBook = YES;
//			[[bookData talkingBookSpeechSynth] startSpeakingString:contentStr];
//		}
//	}
//	else
//		if((sender == bookData.talkingBookSpeechSynth) && (endOfBook))
//		{
//			// remove ourselves as the speech synth delegate
//			[[bookData talkingBookSpeechSynth] setDelegate:nil];
//			// post a notification back to the controller that the book has finished
//		}
//	
//}
//
//- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender willSpeakWord:(NSRange)wordToSpeak ofString:(NSString *)text
//{
//	
//	// send a notifcation or tell the web/text view to 
//	//highlight the current word about to be spoken
//	//NSString *wordIs = [text substringWithRange:wordToSpeak];
//	//NSLog(@"speaking -> %@",wordIs);
//}

@end


