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

@property (readwrite, retain) NSString *parentFolderPath;

@property (readwrite, retain) NSString *bookTitle;
@property (readwrite, retain) NSString *documentUID;
@property (readwrite, retain) NSString *segmentTitle;
@property (readwrite) NSInteger totalPages;
@property (readwrite) NSInteger totalTargetPages;
@property (readwrite) NSInteger currentLevel;

@property (readwrite, retain) NSXMLElement	*nccRootElement;

- (NSString *)filenameFromID:(NSString *)anIdString;
- (void)nextSegment;
- (void)previousSegment;
- (NSString *)currentSegmentFilename;

- (void)processMetadata:(NSXMLElement *)rootElement;

@end



@implementation BBSTBNCCDocument

- (id) init
{
	if (!(self=[super init])) return nil;
	
	
	
	
	return self;
}

- (BOOL)openFileWithURL:(NSURL *)aURL
{

	BOOL isOK = NO;
	
	NSError *theError = nil;
	
	NSXMLDocument *nccDoc = [[NSXMLDocument alloc] initWithContentsOfURL:aURL options:NSXMLDocumentTidyXML error:&theError];
	
	if((nccDoc != nil) && (nil == theError))
	{
		// get the root path for later use with smil and xmlcontent files
		parentFolderPath = [[aURL path] stringByDeletingLastPathComponent]; 
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
		nccDoc = nil;
	}
	else  
	{	
		// there was a problem opening the NCX document
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
	return [self currentSegmentFilename];
}

- (NSString *)previousSegmentAudioFilePath
{
	[self previousSegment];
	return [self currentSegmentFilename];
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
	/*
	// return YES if we can go forward in the navmap
	return ([self navPointIndexOnCurrentLevel] < ([self navPointsOnCurrentLevel] - 1)) ? YES : NO; 
	 */
	return NO;
}

- (BOOL)canGoPrev
{
	/*
	// return YES if we can go backwards in the navMap
	return ([self navPointIndexOnCurrentLevel] > 0) ? YES : NO;
*/
	return NO; 
}

- (BOOL)canGoUpLevel
{
	/*
	// return Yes if we are at a lower level
	return (currentLevel > 1) ? YES : NO;
	 
	 */
	return NO;
}

- (BOOL)canGoDownLevel
{
	
	/*
	// return YES if there are navPoint Nodes below this level
	return ([[currentNavPoint nodesForXPath:@"navPoint" error:nil] count] > 0) ? YES : NO;
	 */
	return NO;
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
	 
	 [extractedContent removeAllObjects];
	 [extractedContent addObjectsFromArray:[rootNode objectsForXQuery:@"//head/meta[@name=\"ncc:pageNormal\"]/data(@content)" error:nil]];
	 self.totalPages = (1 == [extractedContent count]) ? [[extractedContent objectAtIndex:0] intValue] : 0;
	 
	 [extractedContent removeAllObjects];
	 
	 
}

- (void)nextSegment
{
	/*
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
	*/
}

- (void)previousSegment
{
	/*
	if([self canGoPrev])
	{
		currentNavPoint = [currentNavPoint previousSibling];
	}
	
	// set the segment attributes for the current NavPoint
	NSXMLElement *navpPointAsElement = (NSXMLElement *)currentNavPoint;
	self.segmentAttributes = [navpPointAsElement dictionaryFromElement];
	self.segmentTitle = [segmentAttributes valueForKeyPath:@"navLabel.text"];
	*/
}

- (NSString *)currentSegmentFilename
{
	/*
	NSString *audioFilename = nil;
	// get the filename from the segment attributes
	NSString *filename = [self filenameFromID:[segmentAttributes valueForKeyPath:@"content.src"]];
	if(nil != filename) // check that we got something back
	{
		// check if the file is a smil file. which most of the time it will be	
		if(NSOrderedSame == [[filename pathExtension] compare:@"smil" options:NSCaseInsensitiveSearch])
		{
			[self processSmilFile:filename];			
			audioFilename = [NSString stringWithString:[parentFolderPath stringByAppendingPathComponent:[segmentAttributes valueForKeyPath:@"navLabel.audio.src"]]];		
		}
	}
	else  
	{
		// create the full path to the file
		audioFilename = [NSString stringWithString:[parentFolderPath stringByAppendingPathComponent:filename]];
	}
	
	return audioFilename;
	 */
	return nil;
}

- (NSString *)filenameFromID:(NSString *)anIdString
{
	NSAssert(anIdString != nil, @"anIdString is nil");
	int markerPos = [anIdString rangeOfString:@"#"].location;
	return (markerPos > 0) ? [anIdString substringToIndex:markerPos] : anIdString;
	
}



@synthesize currentLevel, totalPages, totalTargetPages;
@synthesize loadFromCurrentLevel;
@synthesize segmentAttributes, nccRootElement;
@synthesize parentFolderPath, documentUID, segmentTitle, bookTitle;
@synthesize smilDoc;

@end
