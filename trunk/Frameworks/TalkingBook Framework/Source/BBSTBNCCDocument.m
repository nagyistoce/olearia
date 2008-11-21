//
//  BBSTBNCCDocument.m
//  Olearia
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
#import "BBSTBSMILDocument.h"


#import "NSXMLElement-BBSExtensions.h"



@interface BBSTBNCCDocument ()

@property (readwrite, retain) BBSTBSMILDocument *smilDoc;

@property (readwrite, retain) NSString *_parentFolderPath;
@property (readwrite, retain) NSString *_currentSmilFilename;

@property (readwrite, retain) NSString *bookTitle;
@property (readwrite, retain) NSString *documentUID;
@property (readwrite, retain) NSString *segmentTitle;
@property (readwrite, retain) NSString *currentAudioFilename;
@property (readwrite) NSInteger totalPages;
@property (readwrite) NSInteger currentLevel;
@property (readwrite) NSInteger currentPageNumber;
@property (readwrite) TalkingBookMediaFormat bookMediaFormat; 
@property (readwrite, retain) NSDictionary *segmentAttributes;

@property (readwrite, retain) NSXMLElement	*nccRootElement;
@property (readwrite, retain) NSXMLNode *currentNavPoint;
@property (readwrite, retain) NSArray		*_bodyNodes;

- (NSString *)filenameFromID:(NSString *)anIdString;
- (void)nextSegment;
- (void)previousSegment;
- (NSString *)currentSegmentFilename;

- (NSInteger)levelOfNodeAtIndex:(NSInteger)anIndex;
- (NSInteger)indexOfNextNodeAtLevel:(NSInteger)aLevel;
- (NSInteger)indexOfPreviousNodeAtLevel:(NSInteger)aLevel;
- (BOOL)isLevelNode:(NSInteger)anIndex;
- (NSString *)attributeValueForXquery:(NSString *)aQuery;

- (void)updateAttributesForCurrentPosition;

- (void)processMetadata:(NSXMLElement *)rootElement;
- (void)openSmilFile:(NSString *)smilFilename;

@end



@implementation BBSTBNCCDocument

- (id) init
{
	if (!(self=[super init])) return nil;
	
	self.loadFromCurrentLevel = NO;
	_isFirstRun = YES;
	self.currentLevel = 1;
	_currentNodeIndex = 0;
	_totalBodyNodes = 0;
	_currentSmilFilename = @"";
	self.currentAudioFilename = @"";
	
	return self;
}

- (BOOL)openControlFileWithURL:(NSURL *)aURL
{
	BOOL isOK = NO;
	
	NSError *theError = nil;
	
	NSXMLDocument *nccDoc = [[NSXMLDocument alloc] initWithContentsOfURL:aURL options:NSXMLDocumentTidyXML error:&theError];
	
	if((nccDoc != nil) && (nil == theError))
	{
		// get the root path for later use with smil and xmlcontent files
		_parentFolderPath = [[aURL path] stringByDeletingLastPathComponent]; 
		// these all may be nil depending on the type of book we are reading
		nccRootElement = [nccDoc rootElement];
				
		[self processMetadata:nccRootElement]; 
		
		self.currentLevel = 1;
		isOK = YES;
		nccDoc = nil;
	}
	else  
	{	
		// there was a problem opening the NCC document
		NSAlert *theAlert = [NSAlert alertWithError:theError];
		[theAlert setMessageText:NSLocalizedString(@"Control File Error", @"control open fail alert short msg")];
		[theAlert setInformativeText:NSLocalizedString(@"Failed to open the ncc.html file.\nPlease check the book Structure or you may have removed the media that the book was on.", @"control ncc open fail alert long msg")]; 
		[theAlert beginSheetModalForWindow:[NSApp keyWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];

	}
	
	return isOK;
 
 
}


#pragma mark -
#pragma mark Public Methods

- (void)moveToNextSegment
{
	
	[self nextSegment];
	NSMutableString *filename = [[NSMutableString alloc] initWithString:[self currentSegmentFilename]];
	while([filename isEqualToString:currentAudioFilename])
	{
		[self nextSegment];
		[filename setString:[self currentSegmentFilename]];
	}

	[self updateAttributesForCurrentPosition];
}

- (void)moveToPreviousSegment
{
	[self previousSegment];
	NSMutableString *filename = [[NSMutableString alloc] initWithString:[self currentSegmentFilename]];
	while([filename isEqualToString:currentAudioFilename])
	{
		[self previousSegment];
		[filename setString:[self currentSegmentFilename]];
	}

	[self updateAttributesForCurrentPosition];
}




- (NSArray *)chaptersForSegment
{
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
	return nil;
}

- (NSArray *)chaptersForSegmentWithTimescale:(long)aTimeScale
{
	/*
	
	NSAssert(smilDoc != nil,@"smilDoc is nil");
	
	NSInteger inc = 0; // 
	
	NSArray *smilChapters = [smilDoc chapterMarkers];
	NSMutableArray *outputChapters = [[NSMutableArray alloc] init];
	for(NSDictionary *aChapter in smilChapters)
	{
		
		NSMutableDictionary *thisChapter = [[NSMutableDictionary alloc] init];
		NSString *clipBeginWthScale = [[aChapter valueForKey:BBSTBClipBeginKey] stringByAppendingFormat:@"/%ld",aTimeScale];
		QTTime aTime = QTTimeFromString(clipBeginWthScale);
		
		[thisChapter setObject:[NSValue valueWithQTTime:aTime] forKey:QTMovieChapterStartTime];
		
		inc++;
		[thisChapter setObject:[[NSNumber numberWithInt:inc] stringValue] forKey:QTMovieChapterName];
		
		[outputChapters addObject:thisChapter]; 
		//NSLog(@"TBNCX chaptersForSegment - output chapters %@",outputChapters);
	}
	
	if([outputChapters count] == 0)
		return nil;
	
	return outputChapters;
	 
	*/ 
	return nil;
}


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
	
	[self updateAttributesForCurrentPosition];
	
}

- (void)goUpALevel
{
	// set the level we want to 1 above the current one
	NSInteger wantedLevel = currentLevel - 1;
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
		
	[self updateAttributesForCurrentPosition];
	
}

- (BOOL)canGoNext
{
	BOOL nodeAvail = NO;  // set the default to assume that there is no node available
	
	if([self indexOfNextNodeAtLevel:currentLevel] != _currentNodeIndex) // set the index to the next node in the array
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
	
	if([self indexOfPreviousNodeAtLevel:currentLevel] != _currentNodeIndex) // set the index to the next node in the array
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
	return (currentLevel > 1) ? YES : NO;
}

- (BOOL)canGoDownLevel
{
	BOOL hasLevelDown = NO; // assume we have no levels below this
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
		if ([self levelOfNodeAtIndex:newIndex] > currentLevel)
		{
			hasLevelDown = YES;
		}
	}
	
	return hasLevelDown;
}

- (BOOL)nextSegmentIsAvailable
{
	return ([self canGoNext] || [self canGoDownLevel]);
}

- (void)updateAttributesForCurrentPosition
{
	
	// check that the format of the book supports audio files
	if(bookMediaFormat < TextPartialAudioMediaFormat)
	{
		self.currentAudioFilename = [self currentSegmentFilename];
	}
	else
	{
		// text only stuff here
	}
	
	// check if its a span node which will indicate a new page number
	if ([[[[_bodyNodes objectAtIndex:_currentNodeIndex] name] lowercaseString] isEqualToString:@"span"])
	{
		self.currentPageNumber = [[[_bodyNodes objectAtIndex:_currentNodeIndex] stringValue] integerValue];
	}
	else
	{
		self.segmentTitle = [self attributeValueForXquery:@"./data(a)"];
		self.currentLevel = [self levelOfNodeAtIndex:_currentNodeIndex];
	}

	
}


#pragma mark -
#pragma mark Private Methods


- (void)processMetadata:(NSXMLElement *)rootElement
 {
	 NSError *theError = nil;
	 NSXMLNode *rootNode = (NSXMLNode *)rootElement;
	 NSMutableArray *extractedContent = [[NSMutableArray alloc] init];
	 [extractedContent addObjectsFromArray:[rootNode objectsForXQuery:@"//head/data(title)" error:&theError]];
	 // check if we found a title
	 if (0 == [extractedContent count])
	 {
		 // check the alternative place for the title in the meta data
		[extractedContent addObjectsFromArray:[rootNode objectsForXQuery:@"(//head/meta[@name=\"dc:title\"]/data(@content))" error:nil]];
	 }
	 self.bookTitle = ( 1 == [extractedContent count]) ? [extractedContent objectAtIndex:0] : NSLocalizedString(@"No Title", @"no title string");
	 
	 // check for total page count
	 [extractedContent removeAllObjects];
	 [extractedContent addObjectsFromArray:[rootNode objectsForXQuery:@"//head/meta[@name=\"ncc:pageNormal\"]/data(@content)" error:nil]];
	 self.totalPages = (1 == [extractedContent count]) ? [[extractedContent objectAtIndex:0] intValue] : 0;
	 
	 // check if we found a page count
	 if(0 == totalPages)
	 {
		 [extractedContent removeAllObjects];
		 // check for the older alternative format
		 [extractedContent addObjectsFromArray:[rootNode objectsForXQuery:@"//head/meta[@name=\"ncc:page-Normal\"]/data(@content)" error:nil]];
		 self.totalPages = (1 == [extractedContent count]) ? [[extractedContent objectAtIndex:0] intValue] : 0; 
	 }
	 
	 // get the media type of the book
	 [extractedContent removeAllObjects];
	 [extractedContent addObjectsFromArray:[rootNode objectsForXQuery:@"//head/meta[@name=\"ncc:multimediaType\"]/data(@content)" error:nil]];
	 
	 // try to get the string and if it exists convert it to lowercase
	 NSString *mediaTypeStr = (1 == [extractedContent count]) ? [[extractedContent objectAtIndex:0] lowercaseString] : nil;	
	 if(mediaTypeStr != nil)
	 {
		 // set the mediaformat accordingly
		 if([mediaTypeStr isEqualToString:@"audiofulltext"] == YES)
			 self.bookMediaFormat = AudioFullTextMediaFormat;
		 else if([mediaTypeStr isEqualToString:@"audioparttext"] == YES)
			 self.bookMediaFormat = AudioPartialTextMediaFormat;
		 else if([mediaTypeStr isEqualToString:@"audioonly"] == YES)
			 self.bookMediaFormat = AudioOnlyMediaFormat;
		 else if([mediaTypeStr isEqualToString:@"audioncc"] == YES)
			 self.bookMediaFormat = AudioNcxOrNccMediaFormat;
		 else if([mediaTypeStr isEqualToString:@"textpartaudio"] == YES)
			 self.bookMediaFormat = TextPartialAudioMediaFormat;
		 else if([mediaTypeStr isEqualToString:@"textncc"] == YES)
			 self.bookMediaFormat = TextNcxOrNccMediaFormat;
		 else 
			 self.bookMediaFormat = unknownMediaFormat;
	 }
	 else
	 {
		 self.bookMediaFormat = unknownMediaFormat;
	 }
	 
	 // get all the body nodes
	 _bodyNodes = [[[rootElement nodesForXPath:@"/html/body" error:nil] objectAtIndex:0] children];
	 _totalBodyNodes = [_bodyNodes count];
}

- (void)openSmilFile:(NSString *)smilFilename
{
	self.smilDoc = nil;
	// build the path to the smil file
	NSString *fullSmilFilePath = [_parentFolderPath stringByAppendingPathComponent:smilFilename];
	// make a URL of it
	NSURL *smilURL = [[NSURL alloc] initFileURLWithPath:fullSmilFilePath];
	// open the smil document
	self.smilDoc = [[BBSTBSMILDocument alloc] init];
	if(smilDoc)
	{
		[smilDoc openSmilFileWithURL:smilURL];
	}

}


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
			else if(testLevel < self.currentLevel)
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

- (void)nextSegment
{
	if(_isFirstRun == NO)
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
			_currentNodeIndex = [self indexOfNextNodeAtLevel:currentLevel];
			self.loadFromCurrentLevel = NO; // reset the flag for auto play mode
		}
	}
	else // isFirstRun == YES
	{	
		// we set NO because after playing the first file 
		// because we have dealt with the skipping the first file problem
		_isFirstRun = NO;
	}
	
	// check if its a span node which will indicate a new page number
	if ([[[[_bodyNodes objectAtIndex:_currentNodeIndex] name] lowercaseString] isEqualToString:@"span"])
	{
		self.currentPageNumber = [[[_bodyNodes objectAtIndex:_currentNodeIndex] stringValue] integerValue];
	}
	else
	{
		self.segmentTitle = [self attributeValueForXquery:@"./data(a)"];
		self.currentLevel = [self levelOfNodeAtIndex:_currentNodeIndex];
	}
}

- (void)previousSegment
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
		self.currentPageNumber = [[[_bodyNodes objectAtIndex:_currentNodeIndex] stringValue] integerValue];
		[self previousSegment];
	}
	else
	{
		self.segmentTitle = [self attributeValueForXquery:@"./data(a)"];
		self.currentLevel = [self levelOfNodeAtIndex:_currentNodeIndex];
	}
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
	NSString *filename = [self filenameFromID:[self attributeValueForXquery:@"./a/data(@href)"]];
	
	if(nil != filename) // check that we got something back
	{
		filename = [filename lowercaseString];
		
		// check if the current file is the same as the new file
		// smil files have multiple references to audio content within them
		// so there is no point reloading the smil
		if(NO == [filename isEqualToString:_currentSmilFilename])
		{
			_currentSmilFilename = filename;
			// check if the file is a smil file. which most of the time it will be	
			if(YES == [[filename pathExtension] isEqualToString:@"smil"])
			{
				[self openSmilFile:filename];	
				NSString *idStr = [NSString stringWithString:[self attributeValueForXquery:@"./data(@id)"]];
				
				audioFilename = [NSString stringWithString:[_parentFolderPath stringByAppendingPathComponent:[smilDoc audioFilenameForId:idStr]]];		
				
			}
			else  
			{
				// create the full path to the file
				audioFilename = [NSString stringWithString:[_parentFolderPath stringByAppendingPathComponent:filename]];
			}
		}
		else
		{
			audioFilename = [NSString stringWithString:[_parentFolderPath stringByAppendingPathComponent:[smilDoc audioFilenameForId:[self attributeValueForXquery:@"./data(@id)"]]]];
			
		}
	}
	
	
	return audioFilename;
	
}


- (NSString *)attributeValueForXquery:(NSString *)aQuery
{
	return [[[_bodyNodes objectAtIndex:_currentNodeIndex] objectsForXQuery:aQuery error:nil] objectAtIndex:0];
}

#pragma mark -
#pragma mark Accessor Methods

- (NSString *)currentPositionID
{
	return [NSString stringWithFormat:@"%d",_currentNodeIndex];
}

- (void)setCurrentPositionID:(NSString *)anID
{
	_currentNodeIndex = [anID intValue];
}

#pragma mark -
#pragma mark Synthesized ivars

@synthesize currentLevel, totalPages, totalTargetPages, currentPageNumber;
@synthesize loadFromCurrentLevel;
@synthesize segmentAttributes, _currentSmilFilename, currentAudioFilename;
@synthesize nccRootElement, currentNavPoint;
@synthesize _parentFolderPath, documentUID, segmentTitle, bookTitle;
@synthesize smilDoc;
@synthesize _bodyNodes;
@synthesize bookMediaFormat;

@end
