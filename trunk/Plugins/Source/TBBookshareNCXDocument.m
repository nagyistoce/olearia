//
//  TBBookshareNCXDocument.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 18/11/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import "TBBookshareNCXDocument.h"


@implementation TBBookshareNCXDocument

- (id) init
{
	if (!(self=[super init])) return nil;
	
	m_currentNavPointIndex = 0;

	return self;
}

- (void) dealloc
{
	[super dealloc];
}


- (void)processData
{

	NSMutableArray *theNavPoints;
	
	
	
//	NSString *tempStr = @"";
//	
//	if([bookData.bookTitle isEqualToString:LocalizedStringInTBStdPluginBundle(@"No Title", @"no title string")])
//	{
//		// set the book title
//		tempStr = [self stringForXquery:@"./dc-metadata/data(*:Title)" ofNode:[self metadataNode]];
//		bookData.bookTitle = (tempStr) ? tempStr : bookData.bookTitle; 
//	}
//	
//	tempStr = nil;
//	
//	if([bookData.bookSubject isEqualToString:LocalizedStringInTBStdPluginBundle(@"No Subject", @"no subject string")])
//	{
//		// set the subject
//		tempStr = [self stringForXquery:@"./dc-metadata/data(*:Subject)" ofNode:[self metadataNode]];
//		bookData.bookSubject =  (tempStr) ? tempStr : bookData.bookSubject;
//	}
//	
//	tempStr = nil;
//	
//	if(bookData.totalPages == 0)
//	{
//		// check for total page count
//		tempStr = [self stringForXquery:@"/ncx/head/meta[@name][ends-with(@name,'totalPageCount')]/data(@content)" ofNode:nil];
//		if(nil == tempStr)
//			tempStr = [self stringForXquery:@"/ncx/head/meta[@name][ends-with(@name,'maxPageNormal')]/data(@content)" ofNode:nil];
//		bookData.totalPages = (tempStr) ? [tempStr intValue] : 0; 
//	
//	}
//	
//	if(nil != tempStr)
//		tempStr = nil;
//	
//	[self jumpToNodeWithPath:nil];
	
	[self processData];

}


- (BOOL)moveToNextSegment
{
	BOOL didMove = NO;
	
	if([self canGoDownLevel]) // first check if we can go down a level
	{	
		currentNavPoint = [[currentNavPoint nodesForXPath:@"navPoint" error:nil] objectAtIndex:0]; // get the first navpoint on the next level down
		bookData.currentLevel++; // increment the level
		didMove = YES;
	}
	else if([self canGoNext]) // we then check if there is another navPoint at the same level
	{	
		currentNavPoint = [currentNavPoint nextSibling];
		didMove = YES;
	}
	else if([self canGoUpLevel]) // we have reached the end of the current level so go up
	{
		if(nil != [[currentNavPoint parent] nextSibling]) // check that there is something after the parent to play
		{	
			// get the parent then its sibling as we have already played 
			// the parent before dropping into this level
			currentNavPoint = [[currentNavPoint parent] nextSibling];
			bookData.currentLevel--; // decrement the current level
			didMove = YES;
		}
	}

	return didMove;
}



- (NSUInteger)navPointsOnCurrentLevel
{
	NSUInteger navPointCount = [[[currentNavPoint parent] nodesForXPath:@"navPoint" error:nil] count];
	return  navPointCount;
}

- (NSUInteger)navPointIndexOnCurrentLevel
{
	// returns an index of the current navPoint relative to the other navPoints on the same level
	NSUInteger currentIndex = [[[currentNavPoint parent] nodesForXPath:@"navPoint" error:nil] indexOfObject:currentNavPoint];
	return currentIndex;
}

- (NSInteger)levelOfNode:(NSXMLNode *)aNode
{
	// we set this so that if the node does not contain level information we return the same level
	NSInteger thislevel = bookData.currentLevel;
	NSString *attribContent = [self stringForXquery:@"data(@class)" ofNode:aNode];
	
	if((nil != attribContent) ) // check that we have something to evaluate
	{
		if([attribContent length] >= 2)
		{
			// get the ascii code of the characters at index 0 and 1
			unichar prefixChar = [attribContent characterAtIndex:0];
			unichar levelChar =  [attribContent characterAtIndex:1];
			
			if(('h' == prefixChar) && (YES == isdigit(levelChar)))
			{
				thislevel = levelChar - 48;
			}
		}
		
	}
	
	return thislevel;
}


- (NSArray *)processNavMap
{
	NSMutableArray *tempNavMapPoints = [[[NSMutableArray alloc] init] autorelease];
	
	// get the navMap node
	NSXMLNode *navMapHeadNode = [[NSArray arrayWithArray:[[xmlControlDoc rootElement] elementsForName:@"navMap"]] objectAtIndex:0];
	if([navMapHeadNode childCount] > 0)
		[tempNavMapPoints addObjectsFromArray:[navMapHeadNode children]];
		
	// check if we had no nav points
	if([tempNavMapPoints count] == 0)
		return nil;
	
	return tempNavMapPoints;
}




@end
