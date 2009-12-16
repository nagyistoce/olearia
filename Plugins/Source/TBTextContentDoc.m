//
//  TBTextContentDoc.m
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

#import "TBTextContentDoc.h"
#import "NSXMLNode-TBAdditions.h"

@interface TBTextContentDoc ()

@property (readwrite,copy)		NSString	*contentText;

@end

@interface TBTextContentDoc (Private)

- (NSUInteger)itemsOnCurrentLevel;
- (NSUInteger)itemIndexOnCurrentLevel;
- (BOOL)isHeadingNode:(NSXMLNode *)aNode;

@end


@implementation TBTextContentDoc

- (id)init
{
	if (!(self=[super init])) return nil;
	
	bookData = [TBBookData sharedBookData];
	self.contentText = @"";
	self.currentNode = nil;
	
	singleSpecifiers = [[NSArray arrayWithObjects:@"pagenum",@"sent",@"img",@"prodnote",@"caption",@"docauthor",@"doctitle",@"span",nil] retain];
	specifiers = [[NSArray arrayWithObjects:@"p",@"imggroup",@"level",@"h",nil] retain];
	
	return self;
}

- (void) dealloc
{
	[specifiers release];

	[xmlTextDoc release];
	self.contentText = nil;
	self.currentNode = nil;
	bookData = nil;
	
	[super dealloc];
}


- (BOOL)openWithContentsOfURL:(NSURL *)aURL
{
	BOOL loadedOk = NO;
	NSError *theError = nil;
	
	xmlTextDoc = [[NSXMLDocument alloc] initWithContentsOfURL:aURL options:NSXMLDocumentTidyXML error:&theError];
	
	if(xmlTextDoc)
	{	
	
		NSArray *startNodes = nil;
		startNodes = [xmlTextDoc nodesForXPath:@"(/dtbook[1]|/dtbook3[1])/book[1]/*" error:nil];
		self.currentNode = (startNodes) ? [startNodes objectAtIndex:0] : nil;
		
		if(nil != currentNode)
		{	
			
			[self moveToNextSuitableNode];
			[self updateDataForCurrentPosition];
			endOfBook = NO;
			loadedOk = YES;
			
		}
	}
	else // we got a nil return so display the error to the user
	{
		NSAlert *theAlert = [NSAlert alertWithError:theError];
		[theAlert setMessageText:LocalizedStringInTBStdPluginBundle(@"Error Opening Text Content", @"text content open fail alert short msg")];
		[theAlert setInformativeText:LocalizedStringInTBStdPluginBundle(@"There was a problem opening the textual content file (.xml).\n This book may still play if it has audio content.", @"text content open fail alert long msg")];
		[theAlert beginSheetModalForWindow:[NSApp keyWindow] 
							 modalDelegate:nil 
							didEndSelector:nil 
							   contextInfo:nil];
	}
	
	return loadedOk;
}

@synthesize contentText, currentNode;

@end

@implementation TBTextContentDoc (Synchronization)

- (void)jumpToNodeWithPath:(NSString *)fullPathToNode
{
	NSArray *nodes = nil;
	if(nil != fullPathToNode)
		nodes = [xmlTextDoc nodesForXPath:fullPathToNode error:nil];
	self.currentNode = ([nodes count] > 0) ? [nodes objectAtIndex:0] : currentNode;
	self.contentText = [currentNode contentValue];
}

- (void)jumpToNodeWithIdTag:(NSString *)aTag
{
	if(aTag)
	{	
		NSString *queryStr = [NSString stringWithFormat:@"/dtbook[1]/book[1]//*[@id='%@']",aTag];
		NSArray *tagNodes = nil;
		tagNodes = [xmlTextDoc nodesForXPath:queryStr error:nil];
		
		self.currentNode = ([tagNodes count]) ? [tagNodes objectAtIndex:0] : currentNode;
		self.contentText = [currentNode contentValue];
	}
	
}

// this method is used when a user changes the position in the 
// document and we have to establish the current positional data
// from the path we are now at
- (void)updateDataAfterJump
{
	NSXMLNode *tempNode = currentNode;
	BOOL levelHasBeenSet = NO;
	
	while(![[tempNode name] isEqualToString:@"book"])
	{
		if([[tempNode name] hasPrefix:@"level"])
		{	
			if(!levelHasBeenSet)
			{	
				bookData.currentLevel = [[[tempNode name] substringFromIndex:5] integerValue];
				bookData.hasLevelUp = (bookData.currentLevel > 1) ? YES : NO;
				
				levelHasBeenSet = YES;
				
			}
		}
		
		if([[tempNode name] isEqualToString:@"pagenum"])
		{	
			bookData.currentPageNumber = [[tempNode contentValue] intValue];
		}
		else if([self isHeadingNode:tempNode])
		{	
			bookData.sectionTitle = [tempNode contentValue];
		}
		
		tempNode = [tempNode parent];

		
	}
	
	
	
}


// this method is used when auto navigating through the document
- (void)updateDataForCurrentPosition 
{

	
	if([[currentNode name] hasPrefix:@"level"])
	{	
		bookData.currentLevel = [[[currentNode name] substringFromIndex:5] integerValue];
		[self moveToNextSuitableNode];
	}
	
	if([[currentNode name] isEqualToString:@"pagenum"])
	{	
		bookData.currentPageNumber = [[currentNode stringValue] intValue];
		if(bookData.speakPageNumbers)
			self.contentText = [[NSString stringWithFormat:@"Page, %d",bookData.currentPageNumber] copy];
		else
			[self moveToNextSuitableNode];
	}
	else if([self isHeadingNode:currentNode])
	{	
		bookData.sectionTitle = [currentNode stringValue];
		self.contentText = [[NSString stringWithFormat:@"Heading, %@",bookData.sectionTitle] copy];
	}
	else if([[currentNode name] isEqualToString:@"img"])
	{
		NSXMLNode *tempNode = [(NSXMLElement *)currentNode attributeForName:@"alt"];
		self.contentText = [[NSString stringWithFormat:@"Image caption, %@",[tempNode contentValue]] copy];
	}
	else
		self.contentText = [currentNode contentValue];
	
}

- (NSString *)currentIdTag
{
	NSString *aTag = nil;
	aTag = [[(NSXMLElement *)currentNode attributeForName:@"id"] stringValue];
	
	return aTag;
}

@end



@implementation TBTextContentDoc (Navigation)

- (BOOL)moveToNextSuitableNode
{
	BOOL foundNode = NO;
	NSXMLNode *tempNode = currentNode;

	if (([[tempNode name] isEqualToString:@"frontmatter"]) || ([[tempNode name] isEqualToString:@"bodymatter"])) 
	{
		tempNode = [tempNode childAtIndex:0];
		
	}

		if([tempNode nextNode] != nil)
		{
			
			//if([[tempNode nextNode] kind] == NSXMLTextKind)
			//{	
			//tempNode = [tempNode nextNode];
				//NSLog(@"node name -> %@",[tempNode name]);
			
			
			while ((!foundNode))
			{
				tempNode = [tempNode nextNode];
				if ([specifiers containsObject:[tempNode name]])
				{
					if (([tempNode childCount] > 1))  
					{
						if([[tempNode nextNode] kind] != NSXMLTextKind)
						{
							currentNode = [tempNode childAtIndex:0];
							foundNode = YES;
						}
						
					}
					else 
					{
						currentNode = tempNode;
						foundNode = YES;
					}

					
				}	
				else if([singleSpecifiers containsObject:[tempNode name]])
				{
					currentNode = tempNode;
					foundNode = YES;
				}
				
			}
			
	}

	return foundNode;	
}

@end


@implementation TBTextContentDoc (Information)

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

@implementation TBTextContentDoc (Private)

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


@end


