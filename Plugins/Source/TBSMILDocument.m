//
//  BBSTBSMILDocument.m
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

#import "TBSMILDocument.h"
#import <QTKit/QTKit.h>
#import "NSString-TBAdditions.h"
//#import "TBAudioSegment.h"
//#import "TBSharedBookData.h"


@interface TBSMILDocument ()

@property (readwrite, retain)   NSXMLNode		*_currentNode;
//@property (readwrite, retain)	NSMutableArray	*_idChapterMarkers;
@property (readwrite, copy)		NSString		*relativeAudioFilePath;

//@property (readwrite, retain)	NSArray			*_parNodes;
//@property (readwrite, retain)	NSDictionary	*_parNodeIndexes;

@property (readwrite, retain)	NSXMLDocument		*_xmlSmilDoc;
//@property (readwrite, retain)   TBAudioSegment		*_currentAudioFile;
@property (readwrite, copy)		NSURL				*_currentFileURL;


- (NSString *)filenameFromCompoundString:(NSString *)aString;
//- (NSDictionary *)createParNodeIndex:(NSArray *)someParNodes;
- (NSString *)idTagFromSrcString:(NSString *)anIdString;
- (void)resetSmil;

@end




@implementation TBSMILDocument


- (id) init
{
	if (!(self=[super init])) return nil;
	
	self._currentFileURL = [[NSURL alloc] init];
	self._currentNode = [[NSXMLNode alloc] init];
	currentNodePath = [[NSString alloc] init];
	
	
	//_parNodes = [[NSArray alloc] init]; 
	//_parNodeIndexes = [[ NSDictionary alloc] init];
	
	//_idChapterMarkers = nil;
	
	
	//bookData = [TBSharedBookData sharedInstance];
	
	return self;
}

- (void) dealloc
{
	//[_parNodes release];
	//[_parNodeIndexes release];
	
	[_currentFileURL release];
	
	[_xmlSmilDoc release];
	_xmlSmilDoc = nil;
	
	_currentNode = nil;
	currentNodePath = nil;
	relativeAudioFilePath = nil;
		
	[super dealloc];
}

- (void)resetSmil;
{
	relativeAudioFilePath = nil;
	_currentNode = nil;
}

- (BOOL)openWithContentsOfURL:(NSURL *)aURL 
{
	NSError *theError;
	BOOL openedOk = NO;
	
	// check that we are opening a new file
	if(![aURL isEqualTo:_currentFileURL])
	{
		[self resetSmil];
		_currentFileURL = [aURL copy];
		// open the URL
		if(_xmlSmilDoc)
			[_xmlSmilDoc release];
		
		_xmlSmilDoc = [[NSXMLDocument alloc] initWithContentsOfURL:_currentFileURL options:NSXMLDocumentTidyXML error:&theError];
		
		if(_xmlSmilDoc != nil)
		{
			// get the first par node
			NSArray *nodes = nil;
			nodes = [_xmlSmilDoc nodesForXPath:@"/smil/body//par[1]" error:nil];
			_currentNode = ([nodes count]) ? [nodes objectAtIndex:0] : nil;
			if(_currentNode)
				openedOk = YES;
		}
		
	}
	else // we passed in a URL that is already open. 
		// this will happen if multiple control document id tags point to the same smil file
		// or there is only a single smil file for the whole book
		openedOk = YES;
	
	return openedOk;
}

//- (NSString *)audioFilenameForId:(NSString *)anId
//{
//	// get the index of the  id from the index dict
//	NSInteger idIndex = [[_parNodeIndexes valueForKey:anId] integerValue];
//	// we get an array here because some par node have multiple time listings for the same file
//	NSArray *filenamesArray = [[_parNodes objectAtIndex:idIndex] objectsForXQuery:@".//audio/data(@src)" error:nil];
//	if(!filenamesArray)
//		return nil;
//	
//	// we got some filenames so return the first filename string as they will all be the same for a given par node.
//	return [filenamesArray objectAtIndex:0];
//}


//- (NSArray *)chapterMarkersFromId:(NSString *)startId toId:(NSString *)endId
//{
//	/*
//	NSMutableArray *markersArray = [[NSMutableArray alloc] init];
//	NSInteger startIndex = [[parNodeIndexes valueForKey:startId] integerValue];
//	NSInteger endIndex = (nil != endId) ? [[parNodeIndexes valueForKey:endId] integerValue] : (NSInteger)[parNodes count]-1;
//	int i;
//	if(nil != endId) // in separate smil this will be nil as we want all the chapters for the entire smil file
//	{
//		for( i=startIndex ; i <endIndex ; i++)
//		{
//			
//				NSMutableDictionary *dictWithID = [[NSMutableDictionary alloc] init];
//				
//				[dictWithID setObject:[NSString stringWithFormat:@"%d",;
//				NSString *clipStartString = [[NSString alloc] qtTimeStringFromSmilTimeString:[aMarkerDict valueForKeyPath:@"audio.clipBegin"]];
//				[dictWithID setObject:clipStartString forKey:BBSTBClipBeginKey];
//				[markersArray addObject:dictWithID];
//				
//			//}
//		}
//		
//	}
//		
//	
//	if([markersArray count] == 0)
//	{	
//		return nil;
//	}
//	
//	return markersArray;
//	*/
//	NSLog(@"method chapterMarkersFromId: in SMILDocument called but not yet implimented");
//	
//	return nil;
//}


//- (void)nextChapter
//{
//	[_currentAudioFile jumpToNextChapter];
//}
//
//- (void)previousChapter
//{
//	[_currentAudioFile jumpToPrevChapter];
//}

// return an array of dictionarys each containing a chapter marker for the filename
// the name of the chapter is the id tag and we also add the full path of the node that the 
// id tag is in.
- (NSArray *)audioChapterMarkersForFilename:(NSString *)aFile WithTimescale:(long)aScale
{
	NSMutableArray *chapMarkers = [[NSMutableArray alloc] init];
	//NSString *queryStr = [NSString stringWithFormat:@"/smil/body/seq/(.//par[.//audio[1][@src='%@']]|.//audio[1][@src='%@'])",relativeAudioFilePath,relativeAudioFilePath];
	NSString *queryStr = [NSString stringWithFormat:@"/smil[1]/body[1]/seq[1]/(.//par[audio[@src='%@']])",aFile];
	NSArray *parNodes = [NSArray arrayWithArray:[[_xmlSmilDoc rootElement] nodesForXPath:queryStr error:nil]];
	
	for(NSXMLNode *theNode in parNodes)
	{
		NSMutableArray *items = [[NSMutableArray alloc] init];
		NSString *chapName = nil;
		NSString *xPathStr = [theNode XPath];
		//get the textual reference id from the par node if that doesnt work extract it from the text node
		[items addObjectsFromArray:[theNode objectsForXQuery:@"./data(@id)" error:nil]];
		if([items count])
			chapName = [[items objectAtIndex:0] copy];
		else
		{	
			[items addObjectsFromArray:[theNode objectsForXQuery:@".//text/data(@src)" error:nil]];
			chapName = ([items count]) ? [[self idTagFromSrcString:[items objectAtIndex:0]] copy] : nil;
		}
		[items removeAllObjects];
		[items addObjectsFromArray:[theNode objectsForXQuery:@".//audio/data(@clip-begin|@clipBegin)" error:nil]];
		NSString *timeStr = ([items count]) ? [NSString QTStringFromSmilTimeString:[items objectAtIndex:0] withTimescale:aScale] : nil ;  
		
		if(chapName && timeStr)
		{
			NSDictionary *thisChapter = [[NSDictionary alloc] initWithObjectsAndKeys:[NSValue valueWithQTTime:(QTTimeFromString(timeStr))],QTMovieChapterStartTime,
										 chapName,QTMovieChapterName,
										 xPathStr,@"XPath",
										 nil];
			[chapMarkers addObject:thisChapter];
		}
		
	}
	
	return ([chapMarkers count]) ? chapMarkers : nil;
}



- (BOOL)audioAfterCurrentPosition
{
	NSXMLNode *nextNode = nil;
	NSXMLNode *theNode = [[_xmlSmilDoc nodesForXPath:currentNodePath error:nil] objectAtIndex:0];
	
	nextNode = [theNode nextSibling];
	if(!nextNode) 
	{
		nextNode = [[theNode parent] nextSibling];
		if(nextNode)
		{	
			if([[nextNode name] isEqualToString:@"seq"])
				if(([[nextNode XPath] isEqualToString:@"/smil[1]/body[1]/seq[1]"]))
					return NO;
				else
					nextNode = [nextNode childAtIndex:0];
		}
		else 
			return NO;
	}

	if(([[nextNode name] isEqualToString:@"par"]) || ([[nextNode name] isEqualToString:@"seq"]))
	{
		NSArray *newAudioNodes = nil;
		newAudioNodes = [nextNode nodesForXPath:@".//audio[@clip-Begin|@clipBegin]" error:nil];
		// check we found some audio content 
		if(newAudioNodes) 
			if([newAudioNodes count])
			{   
				NSXMLNode *tempnode = [[newAudioNodes objectAtIndex:0] parent];
				_currentNode = tempnode;
				self.currentNodePath = [_currentNode XPath];
				return YES;
			}
	}
	
	return NO;
	 
}

         

- (void)setCurrentNodeWithPath:(NSString *)aNodePath
{
	NSError *theError;
	if(aNodePath)
		self._currentNode = [[_xmlSmilDoc nodesForXPath:aNodePath error:&theError] objectAtIndex:0];
}

#pragma mark -
#pragma mark ========= Accessors =========

- (NSString *)relativeAudioFilePath
{
	NSArray *audioPathNodes = [_currentNode objectsForXQuery:@".//audio/data(@src)" error:nil];
	return ([audioPathNodes count]) ? [audioPathNodes objectAtIndex:0] : nil;
}

//- (NSString *)currentTimeAsString
//{
//	return QTStringFromTime([_currentAudioFile currentTime]);
//}
//
//- (void)setCurrentTimeFromString:(NSString *)aTimeString
//{
//	[_currentAudioFile setCurrentTime:QTTimeFromString(aTimeString)];
//}

#pragma mark -
#pragma mark ========= Private Methods =========



//- (NSDictionary *)createParNodeIndex:(NSArray *)someParNodes
//{
//	NSMutableDictionary *tempNodeIndex = [[NSMutableDictionary alloc] init];
//	NSMutableString *idTagString = [[NSMutableString alloc] init];
//	NSInteger parIndex = 0;
//	
//
//	for(NSXMLElement *ParElement in _parNodes)
//	{
//		[idTagString setString:@""];
//		
//		// first get the id tag we will use as a reference in the dictionary
//		NSXMLNode *idAttrib = [ParElement attributeForName:@"id"];
//		if (idAttrib)
//		{	
//			[idTagString setString:[idAttrib stringValue]];
//		}
//		else 
//		{	
//			// there was no id attribute in the par element so check the text element for an id attribute
//			idAttrib = [[[ParElement elementsForName:@"text"] objectAtIndex:0] attributeForName:@"id"];
//			if(idAttrib)
//			{	
//				[idTagString setString:[idAttrib stringValue]];
//			}
//			else
//			{
//				// no id attribute in the text element so extract the id tag from the src string
//				idAttrib  = [[[ParElement elementsForName:@"text"] objectAtIndex:0] attributeForName:@"src"];
//				[idTagString setString:[self idTagFromSrcString:[idAttrib stringValue]]];
//			}
//		}
//		
//		if(![idTagString isEqualToString:@""])
//		{
//			[tempNodeIndex setValue:[NSNumber numberWithInteger:parIndex] forKey:idTagString];
//			parIndex++;
//		}
//		
//	}
//		
//	if([tempNodeIndex count] == 0)
//		return nil;
//	
//	return tempNodeIndex;
//	
//}


			
			
			

/*
- (NSArray *)processData:(NSXMLDocument *)aDoc
{
	NSMutableArray *tempSmilData = [[NSMutableArray alloc] init];
	//NSMutableString *idTagString = [[NSMutableString alloc] init];
	
	// get the body node there will be only one
	NSXMLNode *aNode = [[NSArray arrayWithArray:[[aDoc rootElement] elementsForName:@"body"]] objectAtIndex:0]; 
	
	while((aNode = [aNode nextNode]))
	{
		NSXMLElement *aNodeAsElement = (NSXMLElement *)aNode;
		if(([[aNode name] isEqualToString:@"par"]) && ([[aNodeAsElement attributeForName:@"id"] stringValue] != nil))
		{
			//[tempSmilData setObject:[aNodeAsElement dictionaryFromElement] forKey:[[aNodeAsElement attributeForName:@"id"] stringValue]];
			[tempSmilData addObject:[aNodeAsElement dictionaryFromElement]];
			//NSLog(@" smil data : %@", tempSmilData);
			
		}
		//NSLog(@"smil node name %@",[aNode name]);
		
		
	}
	
	if([tempSmilData count] == 0)
		return nil;
	
	return tempSmilData;

}
*/

- (NSString *)filenameFromCompoundString:(NSString *)aString
{
	// get the position of the # symbol in the string which is the delimiter between filename and ID tag
	NSInteger position = [aString rangeOfString:@"#"].location;
	return ((position > 0) ? [aString substringToIndex:position] : nil); 
}

- (NSString *)idTagFromSrcString:(NSString *)anIdString
{
	NSAssert(anIdString != nil, @"anIdString is nil");
	// get the position of the # symbol in the string which is the delimiter between filename and ID tag
	NSInteger markerPos = [anIdString rangeOfString:@"#"].location;
	return (markerPos > 0) ? [anIdString substringFromIndex:(markerPos+1)] : nil;
}



//#pragma mark -
//#pragma mark --------- Notifications ---------
//
//- (void)audioFileDidEnd:(NSNotification *)notification
//{
//	NSLog(@"audio file did end");
//	NSLog(@"current Time is %@",QTStringFromTime([_currentAudioFile currentTime]));
//	NSArray *nodes = [_xmlSmilDoc nodesForXPath:[[_idChapterMarkers lastObject] valueForKey:@"XPath"] error:nil];
//	
//	if([nodes count] > 0)
//	{
//		NSLog(@"chapter name for node is %@",[[_idChapterMarkers lastObject] valueForKey:QTMovieChapterName]);
//		if(nil != [[nodes objectAtIndex:0] nextSibling])
//		{	
//			NSLog(@"has next play item");
//			// get the next node
//			_currentNode = [[nodes objectAtIndex:0] nextSibling];
//			_relativeAudioFilePath = [[_currentNode objectsForXQuery:@".//audio/data(@src)" error:nil] objectAtIndex:0];
//			NSString *fullAudioFilePath = [[[_currentFileURL path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:_relativeAudioFilePath];
//			if([self updateAudioFile:fullAudioFilePath] && bookData.isPlaying)
//				[_currentAudioFile play];
//			NSString *nodeId = [[[nodes objectAtIndex:0] attributeForName:@"id"] stringValue];
//		}
//		else if(![[[[nodes objectAtIndex:0] parent] XPath] isEqualToString:@"/smil[1]/body[1]/seq[1]"])
//		{	
//			//NSLog(@"xpath = %@",[[[nodes objectAtIndex:0] parent] XPath]);
//			// get the next node
//			_currentNode = [[[nodes objectAtIndex:0] parent] nextSibling];
//			_relativeAudioFilePath = [[_currentNode objectsForXQuery:@".//audio/data(@src)" error:nil] objectAtIndex:0];
//			NSString *fullAudioFilePath = [[[_currentFileURL path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:_relativeAudioFilePath];
//			if([self updateAudioFile:fullAudioFilePath] && bookData.isPlaying)
//				[_currentAudioFile play];
//			
//			NSLog(@"id = %@",[[(NSXMLElement *)[nodes objectAtIndex:0] attributeForName:@"id"] stringValue]);
//		}
//		else
//		{
//			NSLog(@"no more play items -- get next id from control doc" );
//		}
//	}
//	else
//	{
//		
//	}
//
//}
//
//
//- (void)loadStateDidChange:(NSNotification *)notification
//{
//	if([[[notification object] attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete)
//	{
//		// work out how to add the chapters
//		if((AudioOnlyMediaFormat != bookData.mediaFormat) && (AudioNcxOrNccMediaFormat != bookData.mediaFormat))
//		{
//			if(!_idChapterMarkers)
//				_idChapterMarkers = [[NSMutableArray alloc] init];
//			
//			[_idChapterMarkers removeAllObjects];
//			
//			// for books with text content we have to add chapters which mark where the text content changes
//			[self makeIdChapterMarkersForCurrentAudio];
//			NSError *theError = nil;
//			// get the track the chapter will be associated with
//			QTTrack *musicTrack = [[_currentAudioFile tracksOfMediaType:QTMediaTypeSound] objectAtIndex:0];
//			NSDictionary *trackDict = [NSDictionary dictionaryWithObjectsAndKeys:musicTrack, QTMovieChapterTargetTrackAttribute,nil];
//			// add the chapters
//			[_currentAudioFile addChapters:_idChapterMarkers withAttributes:trackDict error:&theError];
//			
//		}
//		else
//		{
//			// for audio only books we can just add chapters of the user set duration.
//			// add chapters to the current audio file
//			[_currentAudioFile addChaptersOfDuration:bookData.chapterSkipDuration];
//			
//		}
//		NSLog(@"now has %d chapters",[_currentAudioFile chapterCount]);
//		[self setPreferredAudioAttributes];
//		
//	}
//	
//
//}
//
//- (void)updateForChapterChange:(NSNotification *)notification
//{
//	
//	//self.bookData.hasNextChapter = ([_currentAudioFile chapterIndexForTime:[_currentAudioFile currentTime]] < [_currentAudioFile chapterCount]) ? YES : NO;
//	//self.bookData.hasPreviousChapter = ([_currentAudioFile chapterIndexForTime:[_currentAudioFile currentTime]] > 0) ? YES : NO;
//
//	// check the media type of the book so we can make a decision on how to update
//	if((bookData.mediaFormat != AudioOnlyMediaFormat) && (bookData.mediaFormat != AudioNcxOrNccMediaFormat))
//	{
//		// send a notification that the text position has changed
//		// get the text id of the new position
//		NSString *idTag =  [_currentAudioFile currentChapterName];
//		NSLog(@"new text tag is %@, current time is %@",idTag,QTStringFromTime([_currentAudioFile currentTime]));
//		//[_currentAudioFile updateForChapterPosition];
//	}
//	else // audio only book 
//	{	
//		NSLog(@"chapter name = %@",[_currentAudioFile currentChapterName]);
//		//[_currentAudioFile updateForChapterPosition];
//	}
//}




//@synthesize  _idChapterMarkers;
@synthesize _xmlSmilDoc, _currentFileURL, relativeAudioFilePath, _currentNode, currentNodePath;
//@synthesize _parNodes, _parNodeIndexes;
//@synthesize bookData;

@end
