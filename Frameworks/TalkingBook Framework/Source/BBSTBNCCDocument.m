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
@property (readwrite, retain) NSString *_currentAudioFilename;

@property (readwrite, retain) NSString *bookTitle;
@property (readwrite, retain) NSString *documentUID;
@property (readwrite, retain) NSString *segmentTitle;
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
- (NSInteger)levelOfNextNode;
- (NSInteger)levelOfCurrentNode;
- (NSString *)attributeValueForXquery:(NSString *)aQuery;

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
	_currentAudioFilename = @"";
	
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
		//[nccRootElement detach];
		
		[self processMetadata:nccRootElement]; 
		
		//totalTargetPages = [[metaData valueForKey:@"dtb:totalPageCount"] intValue];
		//totalPages = [[metaData valueForKey:@"dtb:maxPageNumber"] intValue];
		
		//self.documentTitleDict = [self processDocTitle];
		//self.documentAuthorDict = [self processDocAuthor];
/*		
		maxNavPointsAtThisLevel = [[ncxRootElement nodesForXPath:@"navMap/navPoint" error:nil] count];
		if(maxNavPointsAtThisLevel > 0)
		{
			shouldUseNavmap = YES;
			self.currentNavPoint = [[ncxRootElement nodesForXPath:@"navMap/navPoint" error:nil] objectAtIndex:0];
		}
*/		
		self.currentLevel = 1;
		isOK = YES;
		//nccDoc = nil;
	}
	else  
	{	
		// there was a problem opening the NCC document
		NSAlert *theAlert = [NSAlert alertWithError:theError];
		[theAlert runModal]; // ignore return value
	}
	
	return isOK;
 
 
}


#pragma mark -
#pragma mark Public Methods

- (NSString *)nextSegmentAudioFilePath
{
	
	[self nextSegment];
	NSMutableString *filename = [[NSMutableString alloc] initWithString:[self currentSegmentFilename]];
	while(YES == [filename isEqualToString:_currentAudioFilename])
	{
		[self nextSegment];
		[filename setString:[self currentSegmentFilename]];
	}
	_currentAudioFilename = filename;
	return filename;
}

- (NSString *)previousSegmentAudioFilePath
{
	[self previousSegment];
	NSMutableString *filename = [[NSMutableString alloc] initWithString:[self currentSegmentFilename]];
	while(YES == [filename isEqualToString:_currentAudioFilename])
	{
		[self previousSegment];
		[filename setString:[self currentSegmentFilename]];
	}
	_currentAudioFilename = filename;
	return filename;
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


- (NSString *)goDownALevel
{
	/*
	NSString *audioFilename = nil;
	
	if([self canGoDownLevel]) // first check if we can go down a level
	{	self.currentLevel++; // increment the level index
		self.currentNavPoint = [[currentNavPoint nodesForXPath:@"navPoint" error:nil] objectAtIndex:0]; // get the first navpoint on the next level down
		// set the segment attributes for the current navPoint
		NSXMLElement *navpPointAsElement = (NSXMLElement *)currentNavPoint;
		self.segmentAttributes = [navpPointAsElement dictionaryFromElement];
		self.segmentTitle = [segmentAttributes valueForKeyPath:@"navLabel.text"];
		
		audioFilename = [self currentSegmentFilename];
	}
	
	return audioFilename;
	 
	*/ 
	return nil;
}

- (NSString *)goUpALevel
{
	
	/*
	 
	NSString *audioFilename = nil;
	
	if([self canGoUpLevel]) // check that we can go up first
	{	
		self.currentLevel--; // decrement the level index
		self.currentNavPoint = [currentNavPoint parent];
		// set the segment attributes for the current navPoint
		NSXMLElement *navpPointAsElement = (NSXMLElement *)currentNavPoint;
		self.segmentAttributes = [navpPointAsElement dictionaryFromElement];
		self.segmentTitle = [segmentAttributes valueForKeyPath:@"navLabel.text"];
		
		audioFilename = [self currentSegmentFilename];
	}
	
	return audioFilename;
	 
	*/ 
	return nil;
}

- (BOOL)canGoNext
{
	
	// return YES if we can go forward in the navmap
	return (_currentNodeIndex < _totalBodyNodes) ? YES : NO; 
	 
	
}

- (BOOL)canGoPrev
{
	
	// return YES if we can go backwards in the navMap
	return (_currentNodeIndex > 0) ? YES : NO;

	//return NO; 
}

- (BOOL)canGoUpLevel
{
	// return Yes if we are at a lower level
	return (currentLevel > 1) ? YES : NO;
}

- (BOOL)canGoDownLevel
{
	// return YES if there are navPoint Nodes below this level
	return ( [self levelOfNextNode] > currentLevel) ? YES : NO;
}



#pragma mark -
#pragma mark Private Methods


- (void)processMetadata:(NSXMLElement *)rootElement
 {
	 NSError *theError = nil;
	 NSXMLNode *rootNode = (NSXMLNode *)rootElement;
	 NSMutableArray *extractedContent = [[NSMutableArray alloc] init];
	 [extractedContent addObjectsFromArray:[rootNode objectsForXQuery:@"//head/data(title)" error:&theError]];
	 if (0 == [extractedContent count])
	 {
		[extractedContent addObjectsFromArray:[rootNode objectsForXQuery:@"(//head/meta[@name=\"dc:title\"]/data(@content))" error:nil]];
	 }
	 self.bookTitle = ( 1 == [extractedContent count]) ? [extractedContent objectAtIndex:0] : @"No Title";
	 
	 // check for totoal page count
	 [extractedContent removeAllObjects];
	 [extractedContent addObjectsFromArray:[rootNode objectsForXQuery:@"//head/meta[@name=\"ncc:pageNormal\"]/data(@content)" error:nil]];
	 self.totalPages = (1 == [extractedContent count]) ? [[extractedContent objectAtIndex:0] intValue] : 0;
	 if(0 == totalPages)
	 {
		 [extractedContent removeAllObjects];
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
		 if([mediaTypeStr isEqualToString:@"audioFullText"] == YES)
			 self.bookMediaFormat = AudioFullTextMediaFormat;
		 else if([mediaTypeStr isEqualToString:@"audioPartText"] == YES)
			 self.bookMediaFormat = AudioPartialTextMediaFormat;
		 else if([mediaTypeStr isEqualToString:@"audioOnly"] == YES)
			 self.bookMediaFormat = AudioOnlyMediaFormat;
		 else if([mediaTypeStr isEqualToString:@"audioNcc"] == YES)
			 self.bookMediaFormat = AudioNcxOrNccMediaFormat;
		 else if([mediaTypeStr isEqualToString:@"textPartAudio"] == YES)
			 self.bookMediaFormat = TextPartialAudioMediaFormat;
		 else if([mediaTypeStr isEqualToString:@"textNcc"] == YES)
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

- (NSInteger)levelOfNextNode
{
	NSInteger newlevel = 0;
	// increment the temp
	NSInteger tempIndex = _currentNodeIndex + 1;

	NSMutableString *nodeName = [NSMutableString stringWithString:[[_bodyNodes objectAtIndex:tempIndex] name]];
	unichar checkChar =  [nodeName characterAtIndex:1];

	while((tempIndex < _totalBodyNodes) && ((NO == [nodeName hasPrefix:@"h"]) && (NO == isdigit(checkChar))))
	{
		tempIndex++;
		if(tempIndex < _totalBodyNodes)
		{	
			[nodeName setString:[[_bodyNodes objectAtIndex:tempIndex] name]];
			checkChar =  [nodeName characterAtIndex:1];
		}
	}
		
	if((YES == [nodeName hasPrefix:@"h"]) && (YES == isdigit(checkChar)))
	{
		newlevel = checkChar - 48;
	}
	
	return newlevel;
}

- (NSInteger)levelOfCurrentNode
{
	NSInteger thislevel = 0;
	
	NSString *nodeName = [NSString stringWithString:[[[_bodyNodes objectAtIndex:_currentNodeIndex] name] lowercaseString]];
	unichar checkChar =  [nodeName characterAtIndex:1];
	
	if((YES == [nodeName hasPrefix:@"h"]) && (YES == isdigit(checkChar)))
	{
		thislevel = checkChar - 48;
	}
	
	return thislevel;
}

- (NSInteger)nextNodeIndex
{
	
	
	NSString *nodeName = [NSString stringWithString:[[[_bodyNodes objectAtIndex:_currentNodeIndex] name] lowercaseString]];
	unichar checkChar =  [nodeName characterAtIndex:1];
	
	if((YES == [nodeName hasPrefix:@"h"]) && (YES == isdigit(checkChar)))
		return 0;
	
	return (checkChar - 48);
}

- (void)nextSegment
{
	if(_isFirstRun == NO)
	{
		
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
		self.currentLevel = [self levelOfCurrentNode];
	}
}

- (void)previousSegment
{
	
	if([self canGoPrev])
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
		self.currentLevel = [self levelOfCurrentNode];
	}
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
			if(NSOrderedSame == [[filename pathExtension] compare:@"smil"])
			{
				[self openSmilFile:filename];			
				audioFilename = [NSString stringWithString:[_parentFolderPath stringByAppendingPathComponent:[smilDoc audioFilenameForId:[self attributeValueForXquery:@"./data(@id)"]]]];		
				
			}
			else  
			{
				// create the full path to the file
				//audioFilename = [NSString stringWithString:[parentFolderPath stringByAppendingPathComponent:filename]];
			}
		}
		else
		{
			audioFilename = [NSString stringWithString:[_parentFolderPath stringByAppendingPathComponent:[smilDoc audioFilenameForId:[self attributeValueForXquery:@"./data(@id)"]]]];
			
		}
	}
	
	
	return audioFilename;
	 
}

- (NSString *)filenameFromID:(NSString *)anIdString
{
	NSAssert(anIdString != nil, @"anIdString is nil");
	int markerPos = [anIdString rangeOfString:@"#"].location;
	return (markerPos > 0) ? [anIdString substringToIndex:markerPos] : anIdString;
	
}

- (NSString *)attributeValueForXquery:(NSString *)aQuery
{
	return [[[_bodyNodes objectAtIndex:_currentNodeIndex] objectsForXQuery:aQuery error:nil] objectAtIndex:0];
}

#pragma mark -
#pragma mark Synthesized ivars

@synthesize currentLevel, totalPages, totalTargetPages, currentPageNumber;
@synthesize loadFromCurrentLevel;
@synthesize segmentAttributes, _currentSmilFilename, _currentAudioFilename;
@synthesize nccRootElement, currentNavPoint;
@synthesize _parentFolderPath, documentUID, segmentTitle, bookTitle;
@synthesize smilDoc;
@synthesize _bodyNodes;
@synthesize bookMediaFormat;

@end
