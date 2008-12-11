//
//  BBSTBNCCDocument.m
//  TalkingBook Framework
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

#import <Cocoa/Cocoa.h>
#import "BBSTBNCCDocument.h"
#import "BBSTBControlDoc.h"
#import "NSXMLElement-BBSExtensions.h"



@interface BBSTBNCCDocument ()

@property (readwrite, retain) NSArray		*_bodyNodes;

- (NSString *)filenameFromID:(NSString *)anIdString;
- (NSString *)currentSegmentFilename;

- (NSInteger)levelOfNodeAtIndex:(NSInteger)anIndex;
- (NSInteger)indexOfNextNodeAtLevel:(NSInteger)aLevel;
- (NSInteger)indexOfPreviousNodeAtLevel:(NSInteger)aLevel;
- (BOOL)isLevelNode:(NSInteger)anIndex;


@end



@implementation BBSTBNCCDocument

- (id) init
{
	if (!(self=[super init])) return nil;
	
	self.loadFromCurrentLevel = NO;
	commonInstance.currentLevel = 1;
	_currentNodeIndex = 0;
	_totalBodyNodes = 0;

	return self;
}

- (void)jumpToNodeWithId:(NSString *)fullPathToNode
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

- (BOOL)processMetadata
{
	BOOL isOK = NO;
	NSError *theError = nil;
	NSMutableArray *extractedContent = [[NSMutableArray alloc] init];
		
	NSXMLNode *rootNode = [xmlControlDoc rootElement];
				
	// these all may be nil depending on the type of book we are reading
	[extractedContent addObjectsFromArray:[rootNode objectsForXQuery:@"head/data(title)" error:&theError]];
	// check if we found a title
	if (0 == [extractedContent count])
		// check the alternative place for the title in the meta data
		[extractedContent addObjectsFromArray:[rootNode objectsForXQuery:@"head/meta[@name][ends-with(@name,'title')]/data(@content)" error:nil]];
	commonInstance.bookTitle = ( 1 == [extractedContent count]) ? [extractedContent objectAtIndex:0] : NSLocalizedString(@"No Title", @"no title string");
	
	[extractedContent removeAllObjects];
	// check for total page count
	[extractedContent addObjectsFromArray:[rootNode objectsForXQuery:@"head/meta[@name][contains(@name,'page')][ends-with(@name,'Normal')]/data(@content)" error:nil]];
	// check if we found a page count
	commonInstance.totalPages = (1 == [extractedContent count]) ? [[extractedContent objectAtIndex:0] intValue] : 0; 
	
	[extractedContent removeAllObjects];
	// get the media type of the book
	[extractedContent addObjectsFromArray:[rootNode objectsForXQuery:@"head/meta[@name][ends-with(@name,'multimediaType')]/data(@content)" error:nil]];
	// try to get the string and if it exists convert it to lowercase
	NSString *mediaTypeStr = (1 == [extractedContent count]) ? [[extractedContent objectAtIndex:0] lowercaseString] : nil;	
	if(mediaTypeStr != nil)
		[commonInstance setMediaFormatFromString:mediaTypeStr];	

	// get all the body nodes
	_bodyNodes = [[[rootNode nodesForXPath:@"/html/body" error:nil] objectAtIndex:0] children];
	_totalBodyNodes = [_bodyNodes count];
	
	if(_totalBodyNodes > 0)
	{
		commonInstance.currentLevel = 1;
		isOK = YES;
	}

	return isOK;
}


#pragma mark -
#pragma mark Public Methods

- (void)moveToNextSegment
{
		if(NO == loadFromCurrentLevel) // always NO in regular play through mode
		{
			_currentNodeIndex++;
			/*
			 if(YES == [self canGoDownLevel]) // first check if we can go down a level
			 {	
			 _currentNodeIndex++;
			 }
			 else if(YES == [self canGoNext]) // we then check if there is another navPoint at the same level
			 {	
			 _currentNodeIndex++;
			 }
			 else if(YES == [self canGoUpLevel]) // we have reached the end of the current level so go up
			 {
			 _currentNodeIndex++; // increment the index so we go to the next node
			 }
			 */
		}
		else // loadFromCurrentLevel == YES
		{
			_currentNodeIndex = [self indexOfNextNodeAtLevel:commonInstance.currentLevel];
			self.loadFromCurrentLevel = NO; // reset the flag for auto play mode
		}
	
	// check if its a span node which will indicate a new page number
	if ([[[[_bodyNodes objectAtIndex:_currentNodeIndex] name] lowercaseString] isEqualToString:@"span"])
	{
		commonInstance.currentPage = [[[_bodyNodes objectAtIndex:_currentNodeIndex] stringValue] integerValue];
	}
	else
	{
		commonInstance.sectionTitle = [self stringForXquery:@"./data(a)" ofNode:[_bodyNodes objectAtIndex:_currentNodeIndex]];
		commonInstance.currentLevel = [self levelOfNodeAtIndex:_currentNodeIndex];
	}
	
}

- (void)moveToPreviousSegment
{
	if([self canGoPrev])
	{
		_currentNodeIndex--;
	}
	else if([self canGoUpLevel])
	{
		_currentNodeIndex--;
	}
	
	// check if its a span node which will indicate a new page number
	if ([[[[_bodyNodes objectAtIndex:_currentNodeIndex] name] lowercaseString] isEqualToString:@"span"])
	{
		commonInstance.currentPage = [[[_bodyNodes objectAtIndex:_currentNodeIndex] stringValue] integerValue];
		[self moveToPreviousSegment];
	}
	else
	{
		commonInstance.sectionTitle = [self stringForXquery:@"./data(a)" ofNode:[_bodyNodes objectAtIndex:_currentNodeIndex]];
		commonInstance.currentLevel = [self levelOfNodeAtIndex:_currentNodeIndex];
	}
	
}




//- (NSArray *)chaptersForSegment
//{
	/*
	NSAssert(smilDoc != nil,@"smilDoc is nil");
	
#pragma mark remove Once we parse the xmlcontent properly	
	NSInteger inc = 0; // 
	
	// get the chapter list as ann array of QTTime Strings from the Smil file 
	NSArray *smilChapters = [smilDoc chapterMarkers];
	
	NSMutableArray *outputChapters = [[NSMutableArray alloc] init];
	for(NSDictionary *aChapter in smilChapters)
	{
		
		NSMutableDictionary *thisChapter = [[NSMutableDictionary alloc] init];
		//QTTime aTime = QTTimeFromString();
		// just pass back the string without the timescale
		[thisChapter setObject:[aChapter valueForKey:BBSTBClipBeginKey] forKey:QTMovieChapterStartTime];
		
		inc++;
		[thisChapter setObject:[[NSNumber numberWithInt:inc] stringValue] forKey:QTMovieChapterName];
		
		[outputChapters addObject:thisChapter]; 
		//NSLog(@"TBNCX chaptersForSegment - output chapters %@",outputChapters);
	}
	
	if([outputChapters count] == 0)
		return nil;
	
	return outputChapters;
	 
	*/
//	return nil;
//}

//- (NSArray *)chaptersForSegmentWithTimescale:(long)aTimeScale
//{
//	/*
//	
//	NSAssert(smilDoc != nil,@"smilDoc is nil");
//	
//	NSInteger inc = 0; // 
//	
//	NSArray *smilChapters = [smilDoc chapterMarkers];
//	NSMutableArray *outputChapters = [[NSMutableArray alloc] init];
//	for(NSDictionary *aChapter in smilChapters)
//	{
//		
//		NSMutableDictionary *thisChapter = [[NSMutableDictionary alloc] init];
//		NSString *clipBeginWthScale = [[aChapter valueForKey:BBSTBClipBeginKey] stringByAppendingFormat:@"/%ld",aTimeScale];
//		QTTime aTime = QTTimeFromString(clipBeginWthScale);
//		
//		[thisChapter setObject:[NSValue valueWithQTTime:aTime] forKey:QTMovieChapterStartTime];
//		
//		inc++;
//		[thisChapter setObject:[[NSNumber numberWithInt:inc] stringValue] forKey:QTMovieChapterName];
//		
//		[outputChapters addObject:thisChapter]; 
//		//NSLog(@"TBNCX chaptersForSegment - output chapters %@",outputChapters);
//	}
//	
//	if([outputChapters count] == 0)
//		return nil;
//	
//	return outputChapters;
//	 
//	*/ 
//	return nil;
//}


- (void)goDownALevel
{
	// if we fail to find a level down (which is unlikely as we should only get here if the canGoDownLevel returns YES)
	// we will stay ath the current node position
	
	// set the level we want to 1 below the current one
	NSInteger wantedLevel = [self levelOfNodeAtIndex:_currentNodeIndex] + 1;
	BOOL levelFound = NO;
	NSInteger testIndex = _currentNodeIndex+1; // do an initial increment of the node index so we are not checking the current node 
	
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
	NSInteger wantedLevel = commonInstance.currentLevel - 1;
	NSInteger testIndex = _currentNodeIndex - 1;
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
	
	if([self indexOfNextNodeAtLevel:commonInstance.currentLevel] != _currentNodeIndex) // set the index to the next node in the array
		nodeAvail = YES;
	/*
	while((_totalBodyNodes > testIndex) && (NO == nodeAvail)) 
	{
		if ([self isLevelNode:testIndex]) // check if the node has a level header as its name 
		{
			NSInteger testLevel = [self levelOfNodeAtIndex:testIndex]; // get the level of the node
			if(testLevel == self.currentLevel) // check if its the same as the current level
				nodeAvail = YES; // its the same so we can go forward
			else if(testLevel < self.currentLevel)
				testIndex = _totalBodyNodes; // set the break condition as we have found a node that is above the level of this one;
			else
				testIndex++; // the level was below the current one so skip over it by incrementing the index;
		}
		else
			testIndex++; // the node did not have a level header so skip over it
	}
	*/
	return nodeAvail;
}

- (BOOL)canGoPrev
{
	BOOL nodeAvail = NO;  // set the default to assume that there is no node available
	
	if([self indexOfPreviousNodeAtLevel:commonInstance.currentLevel] != _currentNodeIndex) // set the index to the next node in the array
		nodeAvail = YES;
	
	/*
	NSInteger testIndex = _currentNodeIndex - 1; // set the index to the previous node in the array
	
	// check that we are not at the beginning of the array and that we have not found a node yet
	while((0 < testIndex) && (NO == nodeAvail))   
	{
		if ([self isLevelNode:testIndex]) // check if the node has a level header as its name 
		{
			NSInteger testLevel = [self levelOfNodeAtIndex:testIndex]; // get the level of the node
			if(testLevel == self.currentLevel) // check if its the same as the current level
				nodeAvail = YES; // its the same so we can go back
			else if(testLevel < self.currentLevel)
				testIndex = 0; // set the break condition as we have found a node that is above the level of this one;
			else
				testIndex--; // the level was below the current one so skip over it by decrementing the index;
		}
		else
			testIndex--; // the node did not have a level header so skip over it
	}
	*/
	return nodeAvail;
		
}

- (BOOL)canGoUpLevel
{
	// return Yes if we are at a lower level
	return (commonInstance.currentLevel > 1) ? YES : NO;
}

- (BOOL)canGoDownLevel
{
	BOOL levelDownAvail = NO; // assume we have no levels below this
	NSInteger newIndex = _currentNodeIndex + 1; // get the index of the next node in the array
	
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
		if ([self levelOfNodeAtIndex:newIndex] > commonInstance.currentLevel)
		{
			commonInstance.hasLevelDown = YES;
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
	
//	// check that the format of the book supports audio files
//	if(bookMediaFormat < TextPartialAudioMediaFormat)
//	{
//		//self.currentAudioFilename = [self currentSegmentFilename];
//	}
//	else
//	{
//		// text only stuff here
//	}
	
	// check if its a span node which will indicate a new page number
	if ([[[[_bodyNodes objectAtIndex:_currentNodeIndex] name] lowercaseString] isEqualToString:@"span"])
	{
		self.commonInstance.currentPage = [[[_bodyNodes objectAtIndex:_currentNodeIndex] stringValue] integerValue];
	}
	else
	{
		self.commonInstance.sectionTitle = [self stringForXquery:@"./data(a)" ofNode:[_bodyNodes objectAtIndex:_currentNodeIndex]];
		self.commonInstance.currentLevel = [self levelOfNodeAtIndex:_currentNodeIndex];
	}

	self.commonInstance.hasLevelUp = [self canGoUpLevel];
	self.commonInstance.hasLevelDown = [self canGoDownLevel];
	self.commonInstance.hasPreviousSegment = [self canGoPrev];
	self.commonInstance.hasNextSegment = [self canGoNext];
	
}

- (NSString *)currentSmilFilename
{
	return nil;
}




#pragma mark -
#pragma mark Private Methods
/*
- (void)openSmilFile:(NSString *)smilFilename
{
	self.smilDoc = nil;
	// build the path to the smil file
	NSString *fullSmilFilePath = [parentFolderPath stringByAppendingPathComponent:smilFilename];
	// make a URL of it
	NSURL *smilURL = [[NSURL alloc] initFileURLWithPath:fullSmilFilePath];
	// open the smil document
	self.smilDoc = [[BBSTBSMILDocument alloc] init];
//	if(smilDoc)
//	{
//		[smilDoc openWithContentsOfURL:smilURL];
//	}

}
*/

- (NSInteger)levelOfNodeAtIndex:(NSInteger)anIndex
{
	NSInteger thislevel = -1;
	
	if(_totalBodyNodes > anIndex) // check that we are not beyond our node arrays limit
	{
		// get the name of the node and convert it to lowercase
		NSString *nodeName = [NSString stringWithString:[[[_bodyNodes objectAtIndex:anIndex] name] lowercaseString]];
		// get the ascii code of the character at index 1  
		unichar levelChar =  [nodeName characterAtIndex:1];
		unichar prefixChar = [nodeName characterAtIndex:0];
		
		if(('h' == prefixChar) && (YES == isdigit(levelChar)))
		{
			thislevel = levelChar - 48;
		}
	}

	return thislevel;
}

- (NSInteger)indexOfNextNodeAtLevel:(NSInteger)aLevel
{
	BOOL nodeAvail = NO;  // set the default to assume that there is no node available
	NSInteger testIndex = _currentNodeIndex + 1; // set the index to the next node in the array
	while((_totalBodyNodes > testIndex) && (NO == nodeAvail)) 
	{
		if ([self isLevelNode:testIndex]) // check if the node has a level header as its name 
		{
			NSInteger testLevel = [self levelOfNodeAtIndex:testIndex]; // get the level of the node
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

- (NSInteger)indexOfPreviousNodeAtLevel:(NSInteger)aLevel
{
	BOOL nodeAvail = NO;  // set the default to assume that there is no node available
	NSInteger testIndex = _currentNodeIndex - 1; // set the index to the previous node in the array
	
	// check that we are not at the beginning of the array and that we have not found a node yet
	while((0 < testIndex) && (NO == nodeAvail))   
	{
		if ([self isLevelNode:testIndex]) // check if the node has a level header as its name 
		{
			NSInteger testLevel = [self levelOfNodeAtIndex:testIndex]; // get the level of the node
			if(testLevel == aLevel) // check if its the same as the current level
				nodeAvail = YES; // its the same so we can go back
			else if(testLevel < commonInstance.currentLevel)
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

- (BOOL)isLevelNode:(NSInteger)anIndex
{
	NSString *nodeName = [NSString stringWithString:[[_bodyNodes objectAtIndex:anIndex] name]];
	unichar checkChar =  [nodeName characterAtIndex:0];
	unichar levelChar =  [nodeName characterAtIndex:1];
	
	// check if we have a 'h' as the first character which denotes a level header AND the second character is a digit
	return (('h' == checkChar) && (isdigit(levelChar))) ? YES : NO; 
}


// return the index of the node that is a level below the current one
- (NSInteger)nextLevelNodeIndex
{
	NSInteger currentIndex = _currentNodeIndex + 1; // increment the index
	NSInteger destinationLevel = [self levelOfNodeAtIndex:_currentNodeIndex] + 1;
	
	while((currentIndex < _totalBodyNodes) && (destinationLevel != [self levelOfNodeAtIndex:currentIndex]))
	{
		currentIndex++;
	}
	
	// check we are still within the array bounds
	return (currentIndex < _totalBodyNodes) ? currentIndex : -1 ;
}


- (NSString *)filenameFromID:(NSString *)anIdString
{
	NSAssert(anIdString != nil, @"anIdString is nil");
	int markerPos = [anIdString rangeOfString:@"#"].location;
	return (markerPos > 0) ? [anIdString substringToIndex:markerPos] : anIdString;
	
}

- (NSString *)currentSegmentFilename
{
	
	NSString *audioFilename = nil;
	// get the filename from the segment attributes
	NSString *filename = [self filenameFromID:[self stringForXquery:@"./a/data(@href)" ofNode:[_bodyNodes objectAtIndex:_currentNodeIndex]]];
	
	if(nil != filename) // check that we got something back
	{
		filename = [filename lowercaseString];
		
		// check if the current file is the same as the new file
		// smil files have multiple references to audio content within them
		// so there is no point reloading the smil
//		if(NO == [filename isEqualToString:_currentSmilFilename])
//		{
			//_currentSmilFilename = filename;
			// check if the file is a smil file. which most of the time it will be	
			if(YES == [[filename pathExtension] isEqualToString:@"smil"])
			{
				//[self openSmilFile:filename];	
				NSString *idStr = [self stringForXquery:@"./data(@id)" ofNode:[_bodyNodes objectAtIndex:_currentNodeIndex]];
				
				//audioFilename = [NSString stringWithString:[parentFolderPath stringByAppendingPathComponent:[smilDoc audioFilenameForId:idStr]]];		
				
			}
			else  
			{
				// create the full path to the file
				audioFilename = [NSString stringWithString:[parentFolderPath stringByAppendingPathComponent:filename]];
			}
//		}
//		else
//		{
//			//audioFilename = [parentFolderPath stringByAppendingPathComponent:[smilDoc audioFilenameForId:[self stringForXquery:@"./data(@id)" ofNode:[_bodyNodes objectAtIndex:_currentNodeIndex]]]];
//			
//		}
	}
	
	
	return audioFilename;
	
}

/*
- (NSString *)attributeValueForXquery:(NSString *)aQuery
{
	return [[[_bodyNodes objectAtIndex:_currentNodeIndex] objectsForXQuery:aQuery error:nil] objectAtIndex:0];
}
*/
#pragma mark -
#pragma mark Accessor Methods

- (NSString *)currentPositionID
{
	return [NSString stringWithFormat:@"%d",_currentNodeIndex];
}

//- (void)setCurrentPositionID:(NSString *)anID
//{
//	_currentNodeIndex = [anID intValue];
//}

#pragma mark -
#pragma mark Synthesized ivars

@synthesize loadFromCurrentLevel;

@synthesize _bodyNodes;

@end
