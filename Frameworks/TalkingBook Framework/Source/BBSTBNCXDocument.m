//
//  BBSTBNCXDocument.m
//  BBSTalkingBook
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

#import <Foundation/Foundation.h>
#import "BBSTBControlDoc.h"
#import "BBSTBNCXDocument.h"
#import "BBSTBSMILDocument.h"
#import "BBSTalkingBookTypes.h"
#import "NSXMLElement-BBSExtensions.h"
#import <QTKit/QTKit.h>

@interface BBSTBNCXDocument ()

@property (readwrite, retain) BBSTBSMILDocument *smilDoc;
@property (readwrite, retain) NSString *parentFolderPath;
@property (readwrite, retain) NSDictionary *smilCustomTest;
@property (readwrite, retain) NSDictionary *documentTitleDict;
@property (readwrite, retain) NSDictionary *documentAuthorDict;
@property (readwrite, retain) NSDictionary *segmentAttributes;
@property (readwrite, retain) NSString *bookTitle;

@property (readwrite, retain) NSString *documentUID;
@property (readwrite, retain) NSString *segmentTitle;
@property (readwrite) NSInteger totalPages;
@property (readwrite) NSInteger totalTargetPages;
@property (readwrite) NSInteger currentLevel;

@property (readwrite, retain) NSXMLElement	*ncxRootElement;
@property (readwrite, retain) NSXMLNode		*currentNavPoint;
@property (readwrite, retain) NSXMLNode		*navListNode;
@property (readwrite, retain) NSArray		*navTargets;

@property (readwrite, retain) NSString *versionString;
@property (readwrite, retain) NSXMLDocument	*ncxDoc;
@property (readwrite, retain) NSDictionary *metaData;

- (NSDictionary *)processMetadata;
- (NSDictionary *)processDocTitle;
- (NSDictionary *)processDocAuthor;
- (NSArray *)processNavMap; 
- (void)processSmilFile:(NSString *)smilFilename;
- (NSUInteger)navPointsOnCurrentLevel;
- (NSUInteger)navPointIndexOnCurrentLevel;

- (NSInteger)documentVersion;
- (NSString *)filenameFromID:(NSString *)anIdString;
- (NSString *)nextSegmentFilename;
- (NSString *)previousSegmentFilename;

@end


@implementation BBSTBNCXDocument

@synthesize smilDoc, parentFolderPath;
@synthesize loadFromCurrentLevel;
@synthesize ncxDoc, ncxRootElement, navListNode;
@synthesize currentLevel;
@synthesize metaData, smilCustomTest, documentTitleDict, documentAuthorDict;
@synthesize segmentAttributes;
@synthesize versionString;
@synthesize navTargets; 
@synthesize currentNavPoint;
@synthesize segmentTitle;
@synthesize bookTitle;

@synthesize totalPages, totalTargetPages,documentUID;

- (id) init
{
	if (!(self=[super init])) return nil;
	
	shouldUseNavmap = NO;
	self.loadFromCurrentLevel = NO;
	isFirstRun = YES;
	
	return self;
}

- (BOOL)openFileWithURL:(NSURL *)aURL
{
	BOOL isOK = NO;
	
		NSError *theError;
	
		self.ncxDoc = [[NSXMLDocument alloc] initWithContentsOfURL:aURL options:NSXMLDocumentTidyXML error:&theError];
				
		if(ncxDoc != nil)
		{
			
			
			
			// get the root path for later use with smil and xmlcontent files
			self.parentFolderPath = [[aURL path] stringByDeletingLastPathComponent]; 
			// these all may be nil depending on the type of book we are reading
			self.ncxRootElement = [ncxDoc rootElement];
			[ncxRootElement detach];
			self.ncxDoc = nil;
			self.metaData = [self processMetadata]; 
			
			totalTargetPages = [[metaData valueForKey:@"dtb:totalPageCount"] intValue];
			totalPages = [[metaData valueForKey:@"dtb:maxPageNumber"] intValue];
			
			self.documentTitleDict = [self processDocTitle];
			self.documentAuthorDict = [self processDocAuthor];

			maxNavPointsAtThisLevel = [[ncxRootElement nodesForXPath:@"navMap/navPoint" error:nil] count];
			if(maxNavPointsAtThisLevel > 0)
			{
				shouldUseNavmap = YES;
				self.currentNavPoint = [[ncxRootElement nodesForXPath:@"navMap/navPoint" error:nil] objectAtIndex:0];
			}
			 
			self.currentLevel = 1;
			isOK = YES;
		}
		else  
		{	
			// there was a problem opening the NCX document
			NSAlert *theAlert = [NSAlert alertWithError:theError];
			[theAlert runModal]; // ignore return value
		}
	
	return isOK;
}

/*
- (void) dealloc
{
	// nice cleanup
	[ncxDoc release];
	[ncxRootElement release];
	[metaData release];
	[documentTitleDict release];
	[documentAuthorDict release];
	[versionString release];
	[smilCustomTest release];
	[documentUID release];
	
	[super dealloc];
}
*/

#pragma mark -
#pragma mark Public Methods

- (NSString *)nextSegmentAudioFilePath
{
	NSString *audioFilename;
	NSString *segmentFilename = [self nextSegmentFilename];
	if(nil != segmentFilename) // check that we got something back
	{
		// check if the file is a smil file. which most of the time it will be	
		if(NSOrderedSame == [[segmentFilename pathExtension] compare:@"smil" options:NSCaseInsensitiveSearch])
		{
			[self processSmilFile:segmentFilename];			
			audioFilename = [parentFolderPath stringByAppendingPathComponent:[segmentAttributes valueForKeyPath:@"navLabel.audio.src"]];		
		}
	}
	else // file is not smil so it is some other sort of audio
	{
		// create the full path to the file
		audioFilename = [parentFolderPath stringByAppendingPathComponent:segmentFilename];
	}
		
	return audioFilename;
}

- (NSString *)previousSegmentAudioFilePath
{
	NSString *audioFilename = nil;
	NSString *segmentFilename = [self previousSegmentFilename];
	if(nil != segmentFilename) // check that we got something back
	{
		// check if the file is a smil file. which most of the time it will be	
		if(YES == [[[segmentFilename pathExtension] lowercaseString] isEqualToString:@"smil"])
		{
			[self processSmilFile:segmentFilename];
			audioFilename = [parentFolderPath stringByAppendingPathComponent:[segmentAttributes valueForKeyPath:@"navLabel.audio.src"]];		
		}
	}
	else // file is not smil so it is some other sort of audio
	{
		// create the full path to the file
		audioFilename = [parentFolderPath stringByAppendingPathComponent:segmentFilename];
	}
	
	return audioFilename;
	
}

- (NSArray *)chaptersForSegment
{
	NSAssert(smilDoc != nil,@"smilDoc is nil");

#pragma mark remOVE Once we parse the xmlcontent properly	
	NSInteger inc = 0; // 
	
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
}

- (NSArray *)chaptersForSegmentWithTimescale:(long)aTimeScale
{
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
}


/*
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
	return (currentLevel > 1) ? YES : NO;
}

- (BOOL)canGoDownLevel
{
	// return YES if there are navPoint Nodes below this level
	return ([[currentNavPoint nodesForXPath:@"navPoint" error:nil] count] > 0) ? YES : NO;
}
*/

- (NSString *)goDownALevel
{
	NSString *audioFilename = nil;
	
	if([self canGoDownLevel]) // first check if we can go down a level
	{	self.currentLevel++; // increment the level index
		self.currentNavPoint = [[currentNavPoint nodesForXPath:@"navPoint" error:nil] objectAtIndex:0]; // get the first navpoint on the next level down
		// set the segment attributes for the current navPoint
		NSXMLElement *navpPointAsElement = (NSXMLElement *)currentNavPoint;
		self.segmentAttributes = [navpPointAsElement dictionaryFromElement];
		self.segmentTitle = [segmentAttributes valueForKeyPath:@"navLabel.text"];
		// get the filename from the segment attributes
		NSString *filename = [self filenameFromID:[segmentAttributes valueForKeyPath:@"content.src"]];
		if(nil != filename) // check that we got something back
		{
			// check if the file is a smil file. which most of the time it will be	
			if(NSOrderedSame == [[filename pathExtension] compare:@"smil" options:NSCaseInsensitiveSearch])
			{
				[self processSmilFile:filename];			
				audioFilename = [parentFolderPath stringByAppendingPathComponent:[segmentAttributes valueForKeyPath:@"navLabel.audio.src"]];		
			}
		}
		else  
		{
			// create the full path to the file
			audioFilename = [parentFolderPath stringByAppendingPathComponent:filename];
		}
	}

	return audioFilename;
}

- (NSString *)goUpALevel
{
	NSString *audioFilename = nil;
	
	if([self canGoUpLevel]) // check that we can go up first
	{	
		self.currentLevel--; // decrement the level index
		self.currentNavPoint = [currentNavPoint parent];
		// set the segment attributes for the current navPoint
		NSXMLElement *navpPointAsElement = (NSXMLElement *)currentNavPoint;
		self.segmentAttributes = [navpPointAsElement dictionaryFromElement];
		self.segmentTitle = [segmentAttributes valueForKeyPath:@"navLabel.text"];
		// get the filename from the segment attributes
		NSString *filename = [self filenameFromID:[segmentAttributes valueForKeyPath:@"content.src"]];
		if(nil != filename) // check that we got something back
		{
			// check if the file is a smil file. which most of the time it will be	
			if(NSOrderedSame == [[filename pathExtension] compare:@"smil" options:NSCaseInsensitiveSearch])
			{
				[self processSmilFile:filename];			
				audioFilename = [parentFolderPath stringByAppendingPathComponent:[segmentAttributes valueForKeyPath:@"navLabel.audio.src"]];		
			}
		}
		else // file is not smil so it is some other sort of audio
		{
			// create the full path to the file
			audioFilename = [parentFolderPath stringByAppendingPathComponent:filename];
		}
	}

	return audioFilename;
}

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
	return (currentLevel > 1) ? YES : NO;
}

- (BOOL)canGoDownLevel
{
	// return YES if there are navPoint Nodes below this level
	return ([[currentNavPoint nodesForXPath:@"navPoint" error:nil] count] > 0) ? YES : NO;
}

- (NSUInteger)navPointsOnCurrentLevel
{
	return [[[currentNavPoint parent] nodesForXPath:@"navPoint" error:nil] count]; 
}

- (NSUInteger)navPointIndexOnCurrentLevel
{
	// returns an index of the current navPoint relative to the other navPoints on the same level
	return [[[currentNavPoint parent] nodesForXPath:@"navPoint" error:nil] indexOfObject:currentNavPoint];
}


#pragma mark -
#pragma mark Private Methods

- (NSString *)nextSegmentFilename
{
	NSString *filename;
	
	if(isFirstRun == NO)
	{
		if(NO == self.loadFromCurrentLevel) // always NO in regular play through mode
		{
			if(YES == [self canGoDownLevel]) // first check if we can go down a level
			{	
				self.currentNavPoint = [[currentNavPoint nodesForXPath:@"navPoint" error:nil] objectAtIndex:0]; // get the first navpoint on the next level down
				self.currentLevel++; // increment the level index
			}
			else if(YES == [self canGoNext]) // we then check if there is another navPoint at the same level
				self.currentNavPoint = [currentNavPoint nextSibling];
			else if(YES == [self canGoUpLevel]) // we have reached the end of the current level so go up
			{
				if(nil != [[currentNavPoint parent] nextSibling]) // check that there is something after the parent to play
				{	
					// get the parent then its sibling as we have already played 
					// the parent before dropping into this level
					self.currentNavPoint = [[currentNavPoint parent] nextSibling];
					self.currentLevel--; // decrement the current level
				}
			}
		}
		else // self.useNextSibling == YES
		{
			// this only used when the user chooses to go to the next file on a given level
			self.currentNavPoint = [currentNavPoint nextSibling];
			self.loadFromCurrentLevel = NO; // reset the flag for auto play mode
		}
	}
	else // isFirstRun == YES
	{	
		// we set NO because after playing the first file 
		// because we have dealt with the skipping the first file problem
		isFirstRun = NO;
	}
	
	// set the segment attributes for the current navPoint
	NSXMLElement *navpPointAsElement = (NSXMLElement *)currentNavPoint;
	self.segmentAttributes = [navpPointAsElement dictionaryFromElement];
	self.segmentTitle = [segmentAttributes valueForKeyPath:@"navLabel.text"];
	//NSLog(@"segment atts %@",self.segmentAttributes);	
	
	// get the filename from the segment attributes
	filename = [self filenameFromID:[segmentAttributes valueForKeyPath:@"content.src"]];

	return filename;
}

- (NSString *)previousSegmentFilename
{
	NSString *filename = nil;
			
	if([self canGoPrev])
	{
		currentNavPoint = [currentNavPoint previousSibling];
	}
		
	// set the segment attributes for the current NavPoint
	NSXMLElement *navpPointAsElement = (NSXMLElement *)currentNavPoint;
	self.segmentAttributes = [navpPointAsElement dictionaryFromElement];
	self.segmentTitle = [segmentAttributes valueForKeyPath:@"navLabel.text"];
	// get the filename from the attributes
	filename = [self filenameFromID:[segmentAttributes valueForKeyPath:@"content.src"]];
	 
 return filename;
	
}

- (NSString *)filenameFromID:(NSString *)anIdString
{
	NSAssert(anIdString != nil, @"anIdString is nil");
	int markerPos = [anIdString rangeOfString:@"#"].location;
	return (markerPos > 0) ? [anIdString substringToIndex:markerPos] : anIdString;
		
}

- (NSDictionary *)processMetadata
{
	
	self.versionString = [[ncxRootElement attributeForName:@"version"] stringValue];
	
	// get the head element , there will only ever be one.
	NSXMLNode *headElement = [[NSArray arrayWithArray:[ncxRootElement elementsForName:@"head"]] objectAtIndex:0];
	NSArray *elements = [NSArray arrayWithArray:[headElement children]];
	NSMutableDictionary *tempData = [[NSMutableDictionary alloc] init];
	// we have a DAISY 3 Book
	for(NSXMLElement *anElement in elements)
	{
		if([[anElement name] isEqualToString:@"meta"])
		{
			NSString * nameString = [NSString stringWithString:[[anElement attributeForName:@"name"] stringValue]];
			[tempData setObject:[[anElement attributeForName:@"content"] stringValue] forKey:nameString];
		}
		else if([[anElement name] isEqualToString:@"smilCustomTest"])
		{
			NSMutableDictionary *tempSmilCustomTest = [[NSMutableDictionary alloc] init];
			NSArray *attribs = [NSArray arrayWithArray:[anElement attributes]];
			for(NSXMLNode *aNode in attribs)
			{
				[tempSmilCustomTest setObject:[aNode stringValue] forKey:[aNode name]];
				
			}
			// check if there was anyting put into the dict
			if([tempSmilCustomTest count] > 0)
				self.smilCustomTest = tempSmilCustomTest;
		}
	}
	
	if([tempData count] == 0)
		return nil;
	
	return tempData;
		
}

- (NSDictionary *)processDocTitle
{
	NSMutableDictionary *tempData = [[NSMutableDictionary alloc] init];
	// get the doctitle element , there will only ever be one.
	NSArray *titleElementArray = [ncxRootElement elementsForName:@"docTitle"];
	if([titleElementArray count]  > 0)
	{
		NSXMLNode *docTitleElement = [titleElementArray objectAtIndex:0];
		NSArray *elements = [NSArray arrayWithArray:[docTitleElement children]];
		
		for(NSXMLElement *anElement in elements)
		{
			if([[anElement name] isEqualToString:@"text"])
			{
				[tempData setObject:[anElement stringValue] forKey:@"text"];
				self.bookTitle = [anElement stringValue];
			}
			else if([[anElement name] isEqualToString:@"audio"])
			{
				NSArray *attribs = [NSArray arrayWithArray:[anElement attributes]];
				for(NSXMLNode *aNode in attribs)
				{
					[tempData setObject:[aNode stringValue] forKey:[aNode name]];
				}
			}
		}
		
	}
	
	// check if the dict is empty
	if([tempData count] == 0)
		return nil;
	
	return tempData;
	
}

- (NSDictionary *)processDocAuthor
{
	NSMutableDictionary *tempData = [[NSMutableDictionary alloc] init];
	// get the docAuthor element , there will only ever be one.
	NSArray *authElementsArray = [ncxRootElement elementsForName:@"docAuthor"];
	if([authElementsArray count] > 0)
	{
		NSXMLElement *DocAuthorElement = [authElementsArray objectAtIndex:0];
		
		NSArray *elements = [NSArray arrayWithArray:[DocAuthorElement children]];
		
		for(NSXMLElement *anElement in elements)
		{
			if([[anElement name] isEqualToString:@"text"])
			{
				[tempData setObject:[anElement stringValue] forKey:@"text"];
			}
			else if([[anElement name] isEqualToString:@"audio"])
			{
				NSArray *attribs = [NSArray arrayWithArray:[anElement attributes]];
				for(NSXMLNode *aNode in attribs)
				{
					[tempData setObject:[aNode stringValue] forKey:[aNode name]];
				}
			}
		}
		
	}
		// check if the dict is empty
	if([tempData count] == 0)
		return nil;

	return tempData;
}

- (void)processSmilFile:(NSString *)smilFilename
{
	// build the path to the smil file
	NSString *fullSmilFilePath = [parentFolderPath stringByAppendingPathComponent:smilFilename];
	// make a URL of it
	NSURL *smilURL = [[NSURL alloc] initFileURLWithPath:fullSmilFilePath];
	// open the smil document
	self.smilDoc = [[BBSTBSMILDocument alloc] initWithURL:smilURL];
}

- (NSInteger)documentVersion
{
	// check for an earlier than 2005 version string
	if([versionString hasPrefix:@"1.1."])
		return DTB2002Type;
	
	// return the default
	return DTB2005Type;
}

- (NSArray *)processNavMap
{
	NSMutableArray *tempNavMapPoints = [[NSMutableArray alloc] init];
	
	// get the navMap node
	NSXMLNode *navMapHeadNode = [[NSArray arrayWithArray:[ncxRootElement elementsForName:@"navMap"]] objectAtIndex:0];
	if([navMapHeadNode childCount] > 0)
		[tempNavMapPoints addObjectsFromArray:[navMapHeadNode children]];
		
	// check if we had no nav points
	if([tempNavMapPoints count] == 0)
		return nil;
	
	return tempNavMapPoints;
}
/*
- (NSUInteger)navPointsOnCurrentLevel
{
	return [[[currentNavPoint parent] nodesForXPath:@"navPoint" error:nil] count]; 
}

- (NSUInteger)navPointIndexOnCurrentLevel
{
	// returns an index of the current navPoint relative to the other navPoints on the same level
	return [[[currentNavPoint parent] nodesForXPath:@"navPoint" error:nil] indexOfObject:currentNavPoint];
}
*/

#pragma mark -
#pragma mark Dynamic Accessors

- (NSInteger)totalPages
{
	
	if([metaData count] > 0)
	{	
		// get the value of the 2005 spec attribute
		NSString *value = [metaData objectForKey:@"dtb:maxPageNumber"];
		if(value != nil) // if its nil we have a 2002 spec attribute
			return (NSInteger)[value intValue];
		else // return the 2002 spec attribute
			return [[metaData objectForKey:@"dtb:maxPageNormal"] intValue];
	}
		
	// there is no meta data so return 0
	return 0;
	
}

- (NSInteger)totalTargetPages
{
	if([metaData count] > 0)
		return [[metaData objectForKey:@"dtb:totalPageCount"] intValue];
	
	return 0;
	
}

- (NSString *)documentUID
{
	if([metaData count] > 0)
		return [metaData objectForKey:@"dtb:uid"] ;
	
	return nil;
	
}

@end
