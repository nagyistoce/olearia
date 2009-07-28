//
//  BBSTBNCXDocument.m
//  TalkingBook Framework
//
//  Created by Kieren Eaton on 15/04/08.
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

#import "TBNCXDocument.h"

@interface TBNCXDocument ()

@property (readwrite, retain)	NSXMLNode		*navListNode;
@property (readwrite, retain)	NSArray			*navTargets;

- (NSUInteger)navPointsOnCurrentLevel;
- (NSUInteger)navPointIndexOnCurrentLevel;
- (NSInteger)levelOfNode:(NSXMLNode *)aNode;


@end


@implementation TBNCXDocument 

- (id) init
{
	if (!(self=[super init])) return nil;
	
	shouldUseNavmap = NO;

	return self;
}

- (void) dealloc
{
	[super dealloc];
}


- (void)processData
{

	NSString *tempStr = [[[NSString alloc] init] autorelease];
	
	if([bookData.bookTitle isEqualToString:@""])
	{
		// set the book title
		tempStr = [self stringForXquery:@"./dc-metadata/data(*:Title)" ofNode:[self metadataNode]];
		self.bookData.bookTitle = (tempStr) ? tempStr : NSLocalizedString(@"No Title", @"no title string"); 
	}
	
	if([bookData.bookSubject isEqualToString:@""])
	{
		// set the subject
		tempStr = [self stringForXquery:@"./dc-metadata/data(*:Subject)" ofNode:[self metadataNode]];
		self.bookData.bookSubject =  (tempStr) ? tempStr : NSLocalizedString(@"No Subject", @"no subject string");
	}
	
	if(bookData.totalPages == 0)
	{
		// check for total page count
		tempStr = [self stringForXquery:@"/ncx/head/meta[@name][ends-with(@name,'totalPageCount')]/data(@content)" ofNode:nil];
		if(!tempStr)
			tempStr = [self stringForXquery:@"/ncx/head/meta[@name][ends-with(@name,'maxPageNormal')]/data(@content)" ofNode:nil];
		self.bookData.totalPages = (tempStr) ? [tempStr intValue] : 0; 
	}
		
}

#pragma mark -
#pragma mark Information

- (void)updateDataForCurrentPosition
{
	NSString *sectionStr = [self stringForXquery:@"navLabel/data(text)" ofNode:currentNavPoint];
	self.bookData.sectionTitle = (sectionStr != nil) ? [sectionStr copy] : self.bookData.sectionTitle;   
	self.bookData.currentLevel = [self levelOfNode:currentNavPoint];
	self.bookData.hasLevelUp = [self canGoUpLevel];
	self.bookData.hasLevelDown = [self canGoDownLevel];
	self.bookData.hasPreviousSegment = [self canGoPrev];
	self.bookData.hasNextSegment = [self canGoNext];
}

#pragma mark -
#pragma mark Public Methods

- (NSXMLNode *)metadataNode
{
	NSArray *metaNodes = [xmlControlDoc nodesForXPath:@"/ncx/head" error:nil];
	return ([metaNodes count] > 0) ? [metaNodes objectAtIndex:0] : nil;
}

- (void)jumpToNodeWithPath:(NSString *)fullPathToNode
{
	// check if we were given a node to jump to
	if(fullPathToNode)
		// set the current point to the saved one
		currentNavPoint = [[xmlControlDoc nodesForXPath:fullPathToNode error:nil] objectAtIndex:0];
	else
	{
		// find the first navpoint node
		NSArray *navmapNodes = [xmlControlDoc nodesForXPath:@"/ncx/navMap[1]/navPoint[1]" error:nil];
		if([navmapNodes count] > 0)
			currentNavPoint = [navmapNodes objectAtIndex:0];
	}
	
	[self updateDataForCurrentPosition];
}

- (void)jumpToNodeWithIdTag:(NSString *)anIdTag
{
	if(anIdTag)
	{	
		NSString *queryStr = [NSString stringWithFormat:@"/ncx[1]/navMap[1]//*[@id='%@']",anIdTag];
		NSArray *tagNodes = nil;
		tagNodes = [xmlControlDoc nodesForXPath:queryStr error:nil];
		currentNavPoint = ([tagNodes count]) ? [tagNodes objectAtIndex:0] : currentNavPoint;
	}
}

- (void)moveToNextSegment
{
	if(YES == [self canGoDownLevel]) // first check if we can go down a level
	{	
		currentNavPoint = [[currentNavPoint nodesForXPath:@"navPoint" error:nil] objectAtIndex:0]; // get the first navpoint on the next level down
		bookData.currentLevel++; // increment the level
	}
	else if(YES == [self canGoNext]) // we then check if there is another navPoint at the same level
		currentNavPoint = [currentNavPoint nextSibling];
	else if(YES == [self canGoUpLevel]) // we have reached the end of the current level so go up
	{
		if(nil != [[currentNavPoint parent] nextSibling]) // check that there is something after the parent to play
		{	
			// get the parent then its sibling as we have already played 
			// the parent before dropping into this level
			currentNavPoint = [[currentNavPoint parent] nextSibling];
			bookData.currentLevel--; // decrement the current level
		}
	}
}

- (void)moveToNextSegmentAtSameLevel
{
	// this only used when the user chooses to go to the next file on a given level
	currentNavPoint = [currentNavPoint nextSibling];
	[self updateDataForCurrentPosition];
}

- (void)moveToPreviousSegment
{

	BOOL foundNode = NO;
	
	if(NO == navigateForChapters)
	{
		// we have a node on this level
		currentNavPoint = [currentNavPoint previousSibling];
	}
	else
	{
		// we only make it here if we are travelling backwards across segments
		
		// reset the flag
		navigateForChapters = NO;
		
		// look back through the previous nodes for a navpoint
		while(NO == foundNode)
		{
			currentNavPoint = [currentNavPoint previousNode];
			if([[currentNavPoint name] isEqualToString:@"navPoint"])
				foundNode = YES;
		}
		
		
		//self.bookData.currentLevel = [self levelOfNode:_currentNavPoint];
		
		
		
		
	}
	
	//self.bookData.sectionTitle = [self stringForXquery:@"navLabel/data(text)" ofNode:_currentNavPoint];

	[self updateDataForCurrentPosition];
}

/*
- (NSArray *)chaptersForSegment
{
	NSAssert(smilDoc != nil,@"smilDoc is nil");

	
	NSInteger inc = 0; // 
	
	// get the chapter list as ann array of QTTime Strings from the Smil file 
#pragma mark TODO pass in ids to be chaptered between
	NSArray *smilChapters = [smilDoc chapterMarkersFromId:@"" toId:nil];
	NSMutableArray *outputChapters = [[NSMutableArray alloc] init];
	if(nil != smilChapters)
	{
		for(NSDictionary *aChapter in smilChapters)
		{
			NSMutableDictionary *thisChapter = [[NSMutableDictionary alloc] init];
			//QTTime aTime = QTTimeFromString();
			// just pass back the string without the timescale
			[thisChapter setObject:[aChapter valueForKey:BBSTBClipBeginKey] forKey:QTMovieChapterStartTime];
			
			inc++;
			[thisChapter setObject:[[NSNumber numberWithInt:inc] stringValue] forKey:QTMovieChapterName];
			
			[outputChapters addObject:thisChapter]; 
			
		}
	}
	
	if([outputChapters count] == 0)
		return nil;
	
	return outputChapters;
}

- (NSArray *)chaptersForSegmentWithTimescale:(long)aTimeScale
{
	NSAssert(smilDoc != nil,@"smilDoc is nil");
	
	NSInteger inc = 0; // 

#pragma mark TODO pass in ids to be chaptered between
	NSArray *smilChapters = [smilDoc chapterMarkersFromId:@"" toId:nil];
	NSMutableArray *outputChapters = [[NSMutableArray alloc] init];
	if(nil != smilChapters)
	{
		for(NSDictionary *aChapter in smilChapters)
		{
			NSMutableDictionary *thisChapter = [[NSMutableDictionary alloc] init];
			NSString *clipBeginWthScale = [[aChapter valueForKey:BBSTBClipBeginKey] stringByAppendingFormat:@"/%ld",aTimeScale];
			QTTime aTime = QTTimeFromString(clipBeginWthScale);
			
			[thisChapter setObject:[NSValue valueWithQTTime:aTime] forKey:QTMovieChapterStartTime];
			
			inc++;
			[thisChapter setObject:[[NSNumber numberWithInt:inc] stringValue] forKey:QTMovieChapterName];
			
			[outputChapters addObject:thisChapter]; 
		}
	}
	
	if([outputChapters count] == 0)
		return nil;
	
	return outputChapters;
}
*/

- (NSString *)contentFilenameFromCurrentNode
{
	NSString *filenameWithID = [self stringForXquery:@"./content/data(@src)" ofNode:currentNavPoint];
	return (filenameWithID) ? [self filenameFromID:filenameWithID] : nil;
}

- (NSString *)currentIdTag
{
	NSString *idTag = [self stringForXquery:@"data(@id)" ofNode:currentNavPoint];
	return (idTag) ? idTag : nil;
}

- (void)goDownALevel
{
	if([self canGoDownLevel]) // first check if we can go down a level
	{	
		currentNavPoint = [[currentNavPoint nodesForXPath:@"navPoint" error:nil] objectAtIndex:0]; // get the first navpoint on the next level down
		bookData.currentLevel = [self levelOfNode:currentNavPoint]; // change the level index
	}
	[self updateDataForCurrentPosition];
}

- (void)goUpALevel
{
	if([self canGoUpLevel]) // check that we can go up first
	{	
		currentNavPoint = [currentNavPoint parent];
		bookData.currentLevel = [self levelOfNode:currentNavPoint]; // decrement the level index
	}
	[self updateDataForCurrentPosition];
}

#pragma mark -
#pragma mark ========  Navigation Query =======

- (BOOL)canGoNext
{
	// return YES if we can go forward in the navmap
	return ([self navPointIndexOnCurrentLevel] < ([self navPointsOnCurrentLevel] - 1)) ? YES : NO; 
}

- (BOOL)canGoPrev
{
	// return YES if we can go backwards in the navMap
	return ([self navPointIndexOnCurrentLevel] > 0) ? YES : NO;
}

- (BOOL)canGoUpLevel
{
	// return Yes if we are at a lower level
	return (bookData.currentLevel > 1) ? YES : NO;
}

- (BOOL)canGoDownLevel
{
	// return YES if there are navPoint Nodes below this level
	return ([[currentNavPoint nodesForXPath:@"navPoint" error:nil] count] > 0) ? YES : NO;
}

- (BOOL)nextSegmentIsAvailable
{
	// return YES if there is a segment that will be available after the current one
	// used in evaluation of continuous chapter logic
	
	BOOL segAvail = NO; // set the default
	
	if(YES == [self canGoDownLevel]) // first check if we can go down a level
	{	
		segAvail = YES;
	}
	else if(YES == [self canGoNext]) // we then check if there is another navPoint at the same level
		segAvail = YES;
	else if(YES == [self canGoUpLevel]) // we have reached the end of the current level so go up
	{
		if(nil != [[currentNavPoint parent] nextSibling]) // check that there is something after the parent to play
		{	
			segAvail = YES;
		}
	}
	
	return segAvail;
}

- (BOOL)PreviousSegmentIsAvailable
{
	// return YES if there is a segment that will be available before the current one
	// used in evaluation of continuous chapter logic
	
	BOOL segAvail = NO; // set the default
	
	if(bookData.currentLevel > 1)
		segAvail = YES;
	else if([self canGoPrev])
		segAvail = YES;
	
	return segAvail;
}

/*
- (NSString *)currentSegmentFilename
{
	NSString *audioFilename = nil;
	// get the filename from the segment attributes
	NSString *filename = [self filenameFromID:[segmentAttributes valueForKeyPath:@"content.src"]];
	if(nil != filename) // check that we got something back
	{
		// check if the file is a smil file. which most of the time it will be	
		if(YES == [[[filename pathExtension] lowercaseString] isEqualToString:@"smil"])
		{
			[self openSmilFile:filename];			
			audioFilename = [NSString stringWithString:[parentFolderPath stringByAppendingPathComponent:[segmentAttributes valueForKeyPath:@"navLabel.audio.src"]]];		
		}
	}
	else  
	{
		// create the full path to the file
		audioFilename = [NSString stringWithString:[parentFolderPath stringByAppendingPathComponent:filename]];
	}
	
	return audioFilename;
}
*/


#pragma mark -
#pragma mark Private Methods

- (NSUInteger)navPointsOnCurrentLevel
{
	return [[[currentNavPoint parent] nodesForXPath:@"navPoint" error:nil] count]; 
}

- (NSUInteger)navPointIndexOnCurrentLevel
{
	// returns an index of the current navPoint relative to the other navPoints on the same level
	return [[[currentNavPoint parent] nodesForXPath:@"navPoint" error:nil] indexOfObject:currentNavPoint];
}

- (NSInteger)levelOfNode:(NSXMLNode *)aNode
{
	// we set this so that if the node does not contain level information we return the same level
	NSInteger thislevel = bookData.currentLevel;
	//NSXMLElement *nodeAsElement = (NSXMLElement *)aNode;
	//NSString *attribContent = [[nodeAsElement attributeForName:@"class"] stringValue];
	NSString *attribContent = [self stringForXquery:@"data(/@class)" ofNode:aNode];
	
	if(nil != attribContent) // check that we have something to evaluate
	{
		// get the ascii code of the characters at index 0 and 1
		unichar prefixChar = [attribContent characterAtIndex:0];
		unichar levelChar =  [attribContent characterAtIndex:1];
		
		if(('h' == prefixChar) && (YES == isdigit(levelChar)))
		{
			thislevel = levelChar - 48;
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



#pragma mark -
#pragma mark Dynamic Accessors

- (NSString *)currentPositionID
{
	return [currentNavPoint XPath];
}

//- (void)setCurrentPositionID:(NSString *)anID
//{
//	// we trim the root path off the passed in path
//	//NSRange rootEndPos = [anID rangeOfString:@"/"];
//	//if(rootEndPos.location > 0)
//	//{
//	//	NSString *newPath = [anID substringFromIndex:(rootEndPos.location + 1)]; 
//		//NSXMLNode *rootAsNode = (NSXMLNode *)ncxDoc;
//		NSArray *nodesFromQuery = [xmlControlDoc nodesForXPath:anID error:nil];
//		
//		if([nodesFromQuery count] > 0)
//		{	
//			currentNavPoint = [nodesFromQuery objectAtIndex:0];
//			bookData.currentLevel = [self levelOfNode:currentNavPoint];
//		}
//	//}
//}


#pragma mark -
#pragma mark Synthesized ivars

@synthesize navListNode;
@synthesize navTargets; 

@end
