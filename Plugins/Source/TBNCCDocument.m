//
//  TBNCCDocument.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 11/09/08.
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


#import "TBNCCDocument.h"
#import "TBControlDoc.h"




@interface TBNCCDocument ()

@property (readwrite, retain) NSArray		*_bodyNodes;

- (NSString *)filenameFromID:(NSString *)anIdString;
- (NSString *)currentSegmentFilename;

- (NSUInteger)levelOfNodeAtIndex:(NSUInteger)anIndex;
- (NSUInteger)indexOfNextNodeAtLevel:(NSUInteger)aLevel;
- (NSUInteger)indexOfPreviousNodeAtLevel:(NSUInteger)aLevel;
- (BOOL)isLevelNode:(NSUInteger)anIndex;


@end



@implementation TBNCCDocument

- (id) init
{
	if (!(self=[super init])) return nil;
	
	loadFromCurrentLevel = NO;
	bookData.currentLevel = 1;
	_currentNodeIndex = 0;
	_totalBodyNodes = 0;

	return self;
}


- (void)processData
{
	NSXMLNode *rootNode = [xmlControlDoc rootElement];
	NSMutableString *tempString = [[NSMutableString alloc] init];
	
	// check the default node for a title
	[tempString  setString:[self stringForXquery:@"/html/head/data(title)" ofNode:nil]]; 
	if(!tempString) // check the alternative location
		[tempString setString:[self stringForXquery:@"/html/head/meta[@name][ends-with(@name,'title')]/data(@content)" ofNode:nil]];
	bookData.bookTitle = (tempString) ? tempString : LocalizedStringInTBStdPluginBundle(@"No Title", @"no title string");
	
	
	// check for total page count
	[tempString setString:[self stringForXquery:@"/html/head/meta[@name][contains(@name,'page')][ends-with(@name,'Normal')]/data(@content)" ofNode:nil]];
	// check if we found a page count
	bookData.totalPages = (tempString) ? [tempString intValue] : 0; 
	
	
	// get the media type of the book
	[tempString setString:[self stringForXquery:@"/html/head/meta[@name][ends-with(@name,'multimediaType')]/data(@content)" ofNode:nil]];
	
	[tempString setString:(tempString) ? [tempString lowercaseString] : nil];	
	if(tempString)
		[bookData setMediaFormatFromString:tempString];	

	// get all the child nodes of the body node
	_bodyNodes = [[[rootNode nodesForXPath:@"/html[1]/body[1]" error:nil] objectAtIndex:0] children];
	_totalBodyNodes = [_bodyNodes count];
	
	bookData.currentLevel = (_totalBodyNodes > 0) ? 1 : -1;
	
}




#pragma mark -
#pragma mark Public Methods

- (NSXMLNode *)metadataNode
{
	NSArray *metaNodes = [xmlControlDoc nodesForXPath:@"/html/head" error:nil];
	return ([metaNodes count] > 0) ? [metaNodes objectAtIndex:0] : nil;
}

- (void)moveToNextSegment
{
	_currentNodeIndex++;
	
	[self updateDataForCurrentPosition];	
}

- (void)moveToNextSegmentAtSameLevel
{
	_currentNodeIndex = [self indexOfNextNodeAtLevel:bookData.currentLevel];
	[self updateDataForCurrentPosition];
}

- (void)moveToPreviousSegment
{
	_currentNodeIndex--;
	
	[self updateDataForCurrentPosition];
}

- (void)goDownALevel
{
	// if we fail to find a level down (which is unlikely as we should only get here if the canGoDownLevel returns YES)
	// we will stay at the current node position
	
	// set the level we want to 1 below the current one
	NSUInteger wantedLevel = [self levelOfNodeAtIndex:_currentNodeIndex] + 1;
	BOOL levelFound = NO;
	NSUInteger testIndex = _currentNodeIndex+1; // do an initial increment of the node index so we are not checking the current node 
	
	// check that we are not beyond the array bounds and that we havent foud a valid node yet
	while((_totalBodyNodes > testIndex) && (NO == levelFound))
	{
		if([self levelOfNodeAtIndex:testIndex] == wantedLevel) // check if we found a valid level
		{
			levelFound = YES;
			_currentNodeIndex = testIndex;
		}
		else
			testIndex++;
	}
	
	[self updateDataForCurrentPosition];
	
}

- (void)goUpALevel
{
	// set the level we want to 1 above the current one
	NSUInteger wantedLevel = bookData.currentLevel - 1;
	NSUInteger testIndex = _currentNodeIndex - 1;
	BOOL levelFound = NO;
	
	while((0 < testIndex) && (NO == levelFound))
	{
		if(wantedLevel == [self levelOfNodeAtIndex:testIndex])
		{	
			levelFound = YES;
			_currentNodeIndex = testIndex;
		}
		else
			testIndex--;
	}
		
	[self updateDataForCurrentPosition];
	
}

- (BOOL)canGoNext
{
	BOOL nodeAvail = NO;  // set the default to assume that there is no node available
	if(!(_currentNodeIndex == ([_bodyNodes count]-1)))
		if([self indexOfNextNodeAtLevel:bookData.currentLevel] != _currentNodeIndex) // set the index to the next node in the array
			nodeAvail = YES;

	return nodeAvail;
}

- (BOOL)canGoPrev
{
	BOOL nodeAvail = NO;  // set the default to assume that there is no node available
	
	if(_currentNodeIndex)
		if([self indexOfPreviousNodeAtLevel:bookData.currentLevel] != _currentNodeIndex) // set the index to the next node in the array
			nodeAvail = YES;
	
	return nodeAvail;
		
}

- (BOOL)canGoUpLevel
{
	// return Yes if we are at a lower level
	return (bookData.currentLevel > 1) ? YES : NO;
}

- (BOOL)canGoDownLevel
{
	BOOL levelDownAvail = NO; // assume we have no levels below this
	NSUInteger newIndex = _currentNodeIndex + 1; // get the index of the next node in the array
	
	// check we are not at the bounds of the array and that the next node IS NOT a level header node
	while((_totalBodyNodes > newIndex) && (NO == [self isLevelNode:newIndex]))
	{
		newIndex++;  // increment the index
	}
	
	// check that we are not at the last node of the array AND that it is a level node
	if((_totalBodyNodes > newIndex) && (YES == [self isLevelNode:newIndex]))
	{
		// check if the node has a level greater than the current one
		// this denotes a level down 
		if ([self levelOfNodeAtIndex:newIndex] > (NSUInteger)bookData.currentLevel)
		{
			bookData.hasLevelDown = YES;
			levelDownAvail = YES;
		}
	}
	
	return levelDownAvail;
}

- (BOOL)nextSegmentIsAvailable
{
	return ([self canGoNext] || [self canGoDownLevel]);
}

- (BOOL)PreviousSegmentIsAvailable
{
	return ([self canGoPrev] || [self canGoUpLevel] );
}

- (void)updateDataForCurrentPosition
{
	
	// check if its a span node which will indicate a new page number
	if ([[[[_bodyNodes objectAtIndex:_currentNodeIndex] name] lowercaseString] isEqualToString:@"span"])
	{
		bookData.currentPageNumber = [[[_bodyNodes objectAtIndex:_currentNodeIndex] stringValue] intValue];
	}
	else
	{
		bookData.sectionTitle = [self stringForXquery:@"./data(a)" ofNode:[_bodyNodes objectAtIndex:_currentNodeIndex]];
		bookData.currentLevel = (NSInteger)[self levelOfNodeAtIndex:_currentNodeIndex];
	}

	bookData.hasLevelUp = [self canGoUpLevel];
	bookData.hasLevelDown = [self canGoDownLevel];
	bookData.hasPreviousSegment = [self canGoPrev];
	bookData.hasNextSegment = [self canGoNext];
	
}

- (NSString *)currentSmilFilename
{
	return nil;
}

- (NSString *)contentFilenameFromCurrentNode
{
	return [self currentSegmentFilename];
}

- (NSString *)currentIdTag
{
	NSString *tag = nil;
	tag = [[[_bodyNodes objectAtIndex:_currentNodeIndex] attributeForName:@"id"] stringValue];
	return (tag) ? tag : nil;
}

- (void)jumpToNodeWithPath:(NSString *)fullPathToNode
{
	// check if we were given a node to jump to
	if(![fullPathToNode isEqualToString:@""])
		// set the current point to the saved one
		_currentNodeIndex = [fullPathToNode intValue];
	else
		// the first node in the body nodes
		_currentNodeIndex = 0;
	
	[self updateDataForCurrentPosition];
}

- (void)jumpToNodeWithIdTag:(NSString *)anIdTag
{
	if(anIdTag)
	{	
		NSString *queryStr = [NSString stringWithFormat:@"/html[1]/body[1]//a[ends-with(@href,'%@')]",anIdTag];
		NSArray *tagNodes = nil;
		tagNodes = [xmlControlDoc nodesForXPath:queryStr error:nil];
		_currentNodeIndex = ([tagNodes count]) ? [_bodyNodes indexOfObject:[[tagNodes objectAtIndex:0] parent]] : _currentNodeIndex;
	}
	[self updateDataForCurrentPosition];
}

#pragma mark -
#pragma mark Private Methods

- (NSUInteger)levelOfNodeAtIndex:(NSUInteger)anIndex
{
	NSUInteger thislevel = -1;
	
	if(_totalBodyNodes > anIndex) // check that we are not beyond our node arrays limit
	{
		// get the name of the node and convert it to lowercase
		NSString *nodeName = [NSString stringWithString:[[[_bodyNodes objectAtIndex:anIndex] name] lowercaseString]];
		// get the ascii code of the characters at index 1 & 0  
		unichar levelChar =  [nodeName characterAtIndex:1];
		unichar prefixChar = [nodeName characterAtIndex:0];
		
		if(('h' == prefixChar) && (YES == isdigit(levelChar)))
		{
			thislevel = levelChar - 48;
		}
	}

	return thislevel;
}

- (NSUInteger)indexOfNextNodeAtLevel:(NSUInteger)aLevel
{
	BOOL nodeAvail = NO;  // set the default to assume that there is no node available
	NSUInteger testIndex = _currentNodeIndex + 1; // set the index to the next node in the array
	while((_totalBodyNodes > testIndex) && (NO == nodeAvail)) 
	{
		if ([self isLevelNode:testIndex]) // check if the node has a level header as its name 
		{
			NSUInteger testLevel = [self levelOfNodeAtIndex:testIndex]; // get the level of the node
			if(testLevel == aLevel) // check if its the same as the current level
				nodeAvail = YES; // its the same so we can go forward
			else if(testLevel < aLevel)
				testIndex = _totalBodyNodes; // set the break condition as we have found a node that is above the level of this one;
			else
				testIndex++; // the level was below the current one so skip over it by incrementing the index;
		}
		else
			testIndex++; // the node did not have a level header so skip over it
	}
	
	// return the current index if we could not find a valid next node
	return (nodeAvail) ? testIndex : _currentNodeIndex; 
}

- (NSUInteger)indexOfPreviousNodeAtLevel:(NSUInteger)aLevel
{
	BOOL nodeAvail = NO;  // set the default to assume that there is no node available
	NSUInteger testIndex = _currentNodeIndex - 1; // set the index to the previous node in the array
	
	// check that we are not at the beginning of the array and that we have not found a node yet
	while((0 < testIndex) && (NO == nodeAvail))   
	{
		if ([self isLevelNode:testIndex]) // check if the node has a level header as its name 
		{
			NSUInteger testLevel = [self levelOfNodeAtIndex:testIndex]; // get the level of the node
			if(testLevel == aLevel) // check if its the same as the current level
				nodeAvail = YES; // its the same so we can go back
			else if(testLevel < (NSUInteger)bookData.currentLevel)
				testIndex = 0; // set the break condition as we have found a node that is above the level of this one;
			else
				testIndex--; // the level was below the current one so skip over it by decrementing the index;
		}
		else
			testIndex--; // the node did not have a level header so skip over it
	}
	
	// return the current index if we could not find a valid previous node
	return (nodeAvail) ? testIndex : _currentNodeIndex;
	
}

- (BOOL)isLevelNode:(NSUInteger)anIndex
{
	NSString *nodeName = [NSString stringWithString:[[_bodyNodes objectAtIndex:anIndex] name]];
	unichar checkChar =  [nodeName characterAtIndex:0];
	unichar levelChar =  [nodeName characterAtIndex:1];
	
	// check if we have a 'h' as the first character which denotes a level header AND the second character is a digit
	return (('h' == checkChar) && (isdigit(levelChar))) ? YES : NO; 
}


// return the index of the node that is a level below the current one
- (NSUInteger)nextLevelNodeIndex
{
	NSUInteger currentIndex = _currentNodeIndex + 1; // increment the index
	NSUInteger destinationLevel = [self levelOfNodeAtIndex:_currentNodeIndex] + 1;
	
	while((currentIndex < _totalBodyNodes) && (destinationLevel != [self levelOfNodeAtIndex:currentIndex]))
	{
		currentIndex++;
	}
	
	// check we are still within the array bounds
	return (currentIndex < _totalBodyNodes) ? currentIndex : (NSUInteger)-1 ;
}


- (NSString *)filenameFromID:(NSString *)anIdString
{
	NSAssert(anIdString != nil, @"anIdString is nil");
	NSInteger markerPos = [anIdString rangeOfString:@"#"].location;
	return (markerPos > 0) ? [anIdString substringToIndex:markerPos] : anIdString;
	
}

- (NSString *)currentSegmentFilename
{
	
	NSString *filename = nil;
	// get the filename from the segment attributes
	filename = [self filenameFromID:[self stringForXquery:@"./a/data(@href)" ofNode:[_bodyNodes objectAtIndex:_currentNodeIndex]]];
	
	return (filename) ? filename : nil;
		// check if the current file is the same as the new file
		// smil files have multiple references to audio content within them
		// so there is no point reloading the smil
//		if(NO == [filename isEqualToString:_currentSmilFilename])
//		{
			//_currentSmilFilename = filename;
			// check if the file is a smil file. which most of the time it will be	
//			if(YES == [[filename pathExtension] isEqualToString:@"smil"])
//			{
//				//[self openSmilFile:filename];	
//				//NSString *idStr = [self stringForXquery:@"./data(@id)" ofNode:[_bodyNodes objectAtIndex:_currentNodeIndex]];
//				
//				//audioFilename = [NSString stringWithString:[parentFolderPath stringByAppendingPathComponent:[smilDoc audioFilenameForId:idStr]]];		
//				
//			}
//			else  
//			{
//				// create the full path to the file
//				audioFilename = [NSString stringWithString:[[[bookData folderPath] path] stringByAppendingPathComponent:filename]];
//			}
////		}
////		else
////		{
////			//audioFilename = [parentFolderPath stringByAppendingPathComponent:[smilDoc audioFilenameForId:[self stringForXquery:@"./data(@id)" ofNode:[_bodyNodes objectAtIndex:_currentNodeIndex]]]];
////			
////		}
//	}
	

	
}

#pragma mark -
#pragma mark Accessor Methods

- (NSString *)currentPositionID
{
	return [NSString stringWithFormat:@"%d",_currentNodeIndex];
}

#pragma mark -
#pragma mark Synthesized ivars

@synthesize loadFromCurrentLevel;

@synthesize _bodyNodes;

@end
