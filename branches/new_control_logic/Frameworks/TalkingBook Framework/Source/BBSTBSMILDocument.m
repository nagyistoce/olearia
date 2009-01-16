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

//#import <Cocoa/Cocoa.h>
#import "BBSTBSMILDocument.h"
#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>
#import "NSString-BBSAdditions.h"

#import "BBSTalkingBookTypes.h"
#import "NSXMLElement-BBSExtensions.h"
#import "BBSTBAudioSegment.h"
#import "BBSTBCommonDocClass.h"


@interface BBSTBSMILDocument ()

@property (readwrite, retain)   NSXMLNode		*_currentNode;
@property (readwrite, retain)	NSMutableArray	*_idChapterMarkers;
@property (readwrite, copy)		NSString		*_relativeAudioFilePath;

@property (readwrite, retain)	NSArray			*_parNodes;
@property (readwrite, retain)	NSDictionary	*_parNodeIndexes;

@property (readwrite, retain)	NSXMLDocument		*_xmlSmilDoc;
@property (readwrite, retain)   BBSTBAudioSegment	*_currentAudioFile;
@property (readwrite, copy)		NSURL				*_currentFileURL;


- (void)audioFileDidEnd:(NSNotification *)notification;

- (void)makeIdChapterMarkersForCurrentAudio;
- (NSString *)extractXmlContentFilename:(NSString *)contentString;
//- (NSArray *)processData:(NSXMLDocument *)aDoc;
- (NSDictionary *)createParNodeIndex:(NSArray *)someParNodes;
- (NSString *)idTagFromSrcString:(NSString *)anIdString;
- (BOOL)updateAudioFile:(NSString *)pathToFile;

@end




@implementation BBSTBSMILDocument


- (id) init
{
	if (!(self=[super init])) return nil;
	
	_currentFileURL = [[NSURL alloc] init];
	
	_parNodes = [[NSArray alloc] init]; 
	_parNodeIndexes = [[ NSDictionary alloc] init];
	
	_idChapterMarkers = nil;
	_relativeAudioFilePath = @"";
	
	commonInstance = [BBSTBCommonDocClass sharedInstance];
	
	// watch for load state changes
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loadStateDidChange:)
												 name:QTMovieLoadStateDidChangeNotification
											   object:_currentAudioFile];
	
	// start watching for notifications for reaching the end of the audio file
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(audioFileDidEnd:) 
												 name:QTMovieDidEndNotification 
											   object:_currentAudioFile];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(updateForChapterChange:) 
												 name:QTMovieChapterDidChangeNotification 
											   object:_currentAudioFile];
	
	[commonInstance addObserver:self
					 forKeyPath:@"playbackRate" 
						options:NSKeyValueObservingOptionNew
						context:NULL]; 
	
	[commonInstance addObserver:self
					 forKeyPath:@"playbackVolume" 
						options:NSKeyValueObservingOptionNew
						context:NULL]; 
	
	[commonInstance addObserver:self
					 forKeyPath:@"isPlaying"
						options:NSKeyValueObservingOptionNew
						context:NULL];
	
	
	
	return self;
}

- (void) dealloc
{
	[_parNodes release];
	[_parNodeIndexes release];
	
	[_currentFileURL release];
	
	if(_xmlSmilDoc)
		[_xmlSmilDoc release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[commonInstance removeObserver:self forKeyPath:@"playbackRate"];
	[commonInstance removeObserver:self forKeyPath:@"playbackVolume"];
	[commonInstance removeObserver:self forKeyPath:@"isPlaying"];
	
	if(_currentAudioFile)
		[_currentAudioFile release];
	
	[super dealloc];
}


- (BOOL)openWithContentsOfURL:(NSURL *)aURL 
{
	NSError *theError;
	BOOL openedOk = NO;
	
	// check that we are opening a new file
	if(![aURL isEqualTo:_currentFileURL])
	{
		_currentFileURL = aURL;
		// open the URL
		if(_xmlSmilDoc)
			[_xmlSmilDoc release];
		
		_xmlSmilDoc = [[NSXMLDocument alloc] initWithContentsOfURL:aURL options:NSXMLDocumentTidyXML error:&theError];
		
		if(_xmlSmilDoc != nil)
		{
			// get the all the <par> nodes from the main seq node. Some may be inside nested <seq> tags but these will be ignored
			//_parNodes = [_xmlSmilDoc objectsForXQuery:@"/smil/body/seq/par" error:nil];
			//_parNodeIndexes = [self createParNodeIndex:_parNodes];
			
			// get the first node
			NSArray *nodes = nil;
			nodes = [_xmlSmilDoc nodesForXPath:@"/smil/body/seq/par[1]" error:nil];
			if([nodes count] == 0)
				nodes = [_xmlSmilDoc nodesForXPath:@"/smil/body/seq[1]" error:nil];
			
			if([nodes count] > 0)
			{_currentNode = [nodes objectAtIndex:0];
				_relativeAudioFilePath = [[_currentNode objectsForXQuery:@"//audio/data(@src)" error:nil] objectAtIndex:0];
				NSString *fullAudioFilePath = [[[_currentFileURL path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:_relativeAudioFilePath];
				[self updateAudioFile:fullAudioFilePath];
				openedOk = YES;
				
			}
		}
		
	}
	else // we passed in a URL that is already open. 
		// this will happen if multiple control document id tags point to the same smil file
		// or there is only a single smil file for the whole book
		openedOk = YES;
	
	return openedOk;
}

- (NSString *)audioFilenameForId:(NSString *)anId
{
	// get the index of the  id from the index dict
	NSInteger idIndex = [[_parNodeIndexes valueForKey:anId] integerValue];
	// we get an array here because some par node have multiple time listings for the same file
	NSArray *filenamesArray = [[_parNodes objectAtIndex:idIndex] objectsForXQuery:@".//audio/data(@src)" error:nil];
	if(!filenamesArray)
		return nil;
	
	// we got some filenames so return the first filename string as they will all be the same for a given par node.
	return [filenamesArray objectAtIndex:0];
}


- (NSArray *)chapterMarkersFromId:(NSString *)startId toId:(NSString *)endId
{
	/*
	NSMutableArray *markersArray = [[NSMutableArray alloc] init];
	NSInteger startIndex = [[parNodeIndexes valueForKey:startId] integerValue];
	NSInteger endIndex = (nil != endId) ? [[parNodeIndexes valueForKey:endId] integerValue] : (NSInteger)[parNodes count]-1;
	int i;
	if(nil != endId) // in separate smil this will be nil as we want all the chapters for the entire smil file
	{
		for( i=startIndex ; i <endIndex ; i++)
		{
			
				NSMutableDictionary *dictWithID = [[NSMutableDictionary alloc] init];
				
				[dictWithID setObject:[NSString stringWithFormat:@"%d",;
				NSString *clipStartString = [[NSString alloc] qtTimeStringFromSmilTimeString:[aMarkerDict valueForKeyPath:@"audio.clipBegin"]];
				[dictWithID setObject:clipStartString forKey:BBSTBClipBeginKey];
				[markersArray addObject:dictWithID];
				
			//}
		}
		
	}
		
	
	if([markersArray count] == 0)
	{	
		return nil;
	}
	
	return markersArray;
	*/
	NSLog(@"method chapterMarkersFromId: in SMILDocument called but not yet implimented");
	
	return nil;
}

/*
- (void)playAudio
{
	[_currentAudioFile play];
	_isPlaying = YES;
}

- (void)pauseAudio
{
	[_currentAudioFile stop];
	_isPlaying = NO;
}
 */
//
//- (BOOL)hasNextChapter
//{
//	return [_currentAudioFile nextChapterIsAvail];
//}

- (void)nextChapter
{
	[_currentAudioFile jumpToNextChapter];
}
//
//- (BOOL)hasPreviousChapter
//{
//	return [_currentAudioFile prevChapterIsAvail];
//}

- (void)previousChapter
{
	[_currentAudioFile jumpToPrevChapter];
}

#pragma mark -
#pragma mark ========= Accessors =========

- (NSString *)currentTimeString
{
	return QTStringFromTime([_currentAudioFile currentTime]);
}

- (void)setCurrentTimeString:(NSString *)aTimeString
{
	[_currentAudioFile setCurrentTime:QTTimeFromString(aTimeString)];
}

#pragma mark -
#pragma mark ========= Private Methods =========



- (NSDictionary *)createParNodeIndex:(NSArray *)someParNodes
{
	NSMutableDictionary *tempNodeIndex = [[NSMutableDictionary alloc] init];
	NSMutableString *idTagString = [[NSMutableString alloc] init];
	NSInteger parIndex = 0;
	

	for(NSXMLElement *ParElement in _parNodes)
	{
		[idTagString setString:@""];
		
		// first get the id tag we will use as a reference in the dictionary
		NSXMLNode *idAttrib = [ParElement attributeForName:@"id"];
		if (idAttrib)
		{	
			[idTagString setString:[idAttrib stringValue]];
		}
		else 
		{	
			// there was no id attribute in the par element so check the text element for an id attribute
			idAttrib = [[[ParElement elementsForName:@"text"] objectAtIndex:0] attributeForName:@"id"];
			if(idAttrib)
			{	
				[idTagString setString:[idAttrib stringValue]];
			}
			else
			{
				// no id attribute in the text element so extract the id tag from the src string
				idAttrib  = [[[ParElement elementsForName:@"text"] objectAtIndex:0] attributeForName:@"src"];
				[idTagString setString:[self idTagFromSrcString:[idAttrib stringValue]]];
			}
		}
		
		if(![idTagString isEqualToString:@""])
		{
			[tempNodeIndex setValue:[NSNumber numberWithInteger:parIndex] forKey:idTagString];
			parIndex++;
		}
		
	}
		
	if([tempNodeIndex count] == 0)
		return nil;
	
	return tempNodeIndex;
	
}


			
			
			

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

- (NSString *)extractXmlContentFilename:(NSString *)contentString
{
	// get the position of the # symbol in the string which is the delimiter between filename and ID tag
	NSInteger position = [contentString rangeOfString:@"#"].location;
	return ((position > 0) ? [contentString substringToIndex:position] : nil); 
}

- (NSString *)idTagFromSrcString:(NSString *)anIdString
{
	NSAssert(anIdString != nil, @"anIdString is nil");
	// get the position of the # symbol in the string which is the delimiter between filename and ID tag
	NSInteger markerPos = [anIdString rangeOfString:@"#"].location;
	return (markerPos > 0) ? [anIdString substringFromIndex:(markerPos+1)] : nil;
}

- (void)setPreferredAudioAttributes
{
	[_currentAudioFile setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieRateChangesPreservePitchAttribute];
	[_currentAudioFile setAttribute:[NSNumber numberWithFloat:commonInstance.playbackVolume] forKey:QTMoviePreferredVolumeAttribute];
	[_currentAudioFile setVolume:commonInstance.playbackVolume];
	if(!commonInstance.isPlaying)
	{	
		[_currentAudioFile setAttribute:[NSNumber numberWithFloat:commonInstance.playbackRate] forKey:QTMoviePreferredRateAttribute];
		[_currentAudioFile stop];
	}
	else
	{	
		[_currentAudioFile setAttribute:[NSNumber numberWithFloat:commonInstance.playbackRate] forKey:QTMoviePreferredRateAttribute];
		[_currentAudioFile setRate:commonInstance.playbackRate];
	}
	
	[_currentAudioFile setDelegate:self];
}

- (BOOL)updateAudioFile:(NSString *)pathToFile
{
	NSError *theError = nil;
	BOOL loadedOK = NO;
	
	// check that we have not passed in a nil string
	if(pathToFile != nil)
	{
		[_currentAudioFile stop]; // pause the playback if there is any currently playing
		_currentAudioFile = nil;
		_currentAudioFile = [[BBSTBAudioSegment alloc] initWithFile:pathToFile error:&theError];
		
		if(_currentAudioFile != nil)
		{
			// make the file editable and set the timescale for it 
			[_currentAudioFile setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
			[self setPreferredAudioAttributes];
			// check the load state for complete which will not trigger a notification on small files
			if(([[_currentAudioFile attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete) && (NO == [_currentAudioFile hasChapters]))
			{	
				// no chapters and its loaded so post a notification to add chapters
				[[NSNotificationCenter defaultCenter] postNotificationName:QTMovieLoadStateDidChangeNotification object:_currentAudioFile];
			}
			loadedOK = YES;
		}
	}
	
	
	if((nil == _currentAudioFile) || (loadedOK == NO))
	{	
		NSAlert *theAlert = [NSAlert alertWithError:theError];
		[theAlert setMessageText:NSLocalizedString(@"Error Opening Audio File", @"audio error alert short msg")];
		[theAlert setInformativeText:NSLocalizedString(@"There was a problem loading an audio file.\n Please check the book format for problems.\nOlearia will now reset as this book will not play", @"audio error alert short msg")];
		[theAlert setAlertStyle:NSWarningAlertStyle];
		[theAlert setIcon:[NSImage imageNamed:@"olearia.icns"]];		
		[theAlert beginSheetModalForWindow:[NSApp keyWindow] modalDelegate:self didEndSelector:@selector(errorDialogDidEnd) contextInfo:nil];
		
		return NO;
	}
	
	return YES;
}

- (void)makeIdChapterMarkersForCurrentAudio
{
	NSString *queryStr = [NSString stringWithFormat:@"/smil/body/seq/(.//par[.//audio[1][@src='%@']]|.//audio[1][@src='%@'])/data(@id)",_relativeAudioFilePath];
	NSArray *parNodes = [_xmlSmilDoc nodesForXPath:queryStr error:nil];
	long audioTimescale = [_currentAudioFile duration].timeScale;
	
	for(NSXMLNode *theNode in parNodes)
	{
		NSString *xPathStr = [theNode XPath];
		// text/data(@src) -- get the textual reference id from the text node given the current node
		NSArray *nameItems = [theNode objectsForXQuery:@".//text/data(@src)" error:nil];
		NSString *chapName = ([nameItems count] > 0) ? [self idTagFromSrcString:[nameItems objectAtIndex:0]] : nil;
		NSArray *clipBeginItems = [theNode objectsForXQuery:@".//audio/data(@clip-begin|@clipBegin)" error:nil];
		NSString *timeStr = ([clipBeginItems count] > 0) ? [NSString QTStringFromSmilTimeString:[clipBeginItems objectAtIndex:0] withTimescale:audioTimescale] : nil ;  
		
		if(chapName && timeStr)
		{
			NSLog(@"chapname = %@  -- timestr = %@\n",chapName,timeStr);
			NSDictionary *thisChapter = [[NSDictionary alloc] initWithObjectsAndKeys:[NSValue valueWithQTTime:(QTTimeFromString(timeStr))],QTMovieChapterStartTime,
										 chapName,QTMovieChapterName,
										 xPathStr,@"XPath",
										 nil];
			[_idChapterMarkers addObject:thisChapter];
		}
	}
}

#pragma mark -
#pragma mark --------- Notifications ---------

- (void)audioFileDidEnd:(NSNotification *)notification
{
	NSLog(@"audio file did end");
	NSLog(@"current Time is %@",QTStringFromTime([_currentAudioFile currentTime]));
	NSArray *nodes = [_xmlSmilDoc nodesForXPath:[[_idChapterMarkers lastObject] valueForKey:@"XPath"] error:nil];
	
	if([nodes count] > 0)
	{
		NSLog(@"chapter name for node is %@",[[_idChapterMarkers lastObject] valueForKey:QTMovieChapterName]);
		if(nil != [[nodes objectAtIndex:0] nextSibling])
		{	
			NSLog(@"has next play item");
			// get the next node
			_currentNode = [[nodes objectAtIndex:0] nextSibling];
			_relativeAudioFilePath = [[_currentNode objectsForXQuery:@".//audio/data(@src)" error:nil] objectAtIndex:0];
			NSString *fullAudioFilePath = [[[_currentFileURL path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:_relativeAudioFilePath];
			if([self updateAudioFile:fullAudioFilePath] && commonInstance.isPlaying)
				[_currentAudioFile play];
			NSString *nodeId = [[[nodes objectAtIndex:0] attributeForName:@"id"] stringValue];
		}
		else if(![[[[nodes objectAtIndex:0] parent] XPath] isEqualToString:@"/smil[1]/body[1]/seq[1]"])
		{	
			//NSLog(@"xpath = %@",[[[nodes objectAtIndex:0] parent] XPath]);
			// get the next node
			_currentNode = [[[nodes objectAtIndex:0] parent] nextSibling];
			_relativeAudioFilePath = [[_currentNode objectsForXQuery:@".//audio/data(@src)" error:nil] objectAtIndex:0];
			NSString *fullAudioFilePath = [[[_currentFileURL path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:_relativeAudioFilePath];
			if([self updateAudioFile:fullAudioFilePath] && commonInstance.isPlaying)
				[_currentAudioFile play];
			
			NSLog(@"id = %@",[[(NSXMLElement *)[nodes objectAtIndex:0] attributeForName:@"id"] stringValue]);
		}
		else
		{
			NSLog(@"no more play items -- get next id from control doc" );
		}
	}
	else
	{
		
	}

}


- (void)loadStateDidChange:(NSNotification *)notification
{
	if([[[notification object] attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete)
	{
		// work out how to add the chapters
		if((AudioOnlyMediaFormat != commonInstance.mediaFormat) && (AudioNcxOrNccMediaFormat != commonInstance.mediaFormat))
		{
			if(!_idChapterMarkers)
				_idChapterMarkers = [[NSMutableArray alloc] init];
			
			[_idChapterMarkers removeAllObjects];
			
			// for books with text content we have to add chapters which mark where the text content changes
			[self makeIdChapterMarkersForCurrentAudio];
			NSError *theError = nil;
			// get the track the chapter will be associated with
			QTTrack *musicTrack = [[_currentAudioFile tracksOfMediaType:QTMediaTypeSound] objectAtIndex:0];
			NSDictionary *trackDict = [NSDictionary dictionaryWithObjectsAndKeys:musicTrack, QTMovieChapterTargetTrackAttribute,nil];
			// add the chapters
			[_currentAudioFile addChapters:_idChapterMarkers withAttributes:trackDict error:&theError];
			
		}
		else
		{
			// for audio only books we can just add chapters of the user set duration.
			// add chapters to the current audio file
			[_currentAudioFile addChaptersOfDuration:commonInstance.chapterSkipDuration];
			
		}
		NSLog(@"now has %d chapters",[_currentAudioFile chapterCount]);
		[self setPreferredAudioAttributes];
		
	}
	

}

- (void)updateForChapterChange:(NSNotification *)notification
{
	
	//self.commonInstance.hasNextChapter = ([_currentAudioFile chapterIndexForTime:[_currentAudioFile currentTime]] < [_currentAudioFile chapterCount]) ? YES : NO;
	//self.commonInstance.hasPreviousChapter = ([_currentAudioFile chapterIndexForTime:[_currentAudioFile currentTime]] > 0) ? YES : NO;

	// check the media type of the book so we can make a decision on how to update
	if((commonInstance.mediaFormat != AudioOnlyMediaFormat) && (commonInstance.mediaFormat != AudioNcxOrNccMediaFormat))
	{
		// send a notification that the text position has changed
		// get the text id of the new position
		NSString *idTag =  [_currentAudioFile currentChapterName];
		NSLog(@"new text tag is %@, current time is %@",idTag,QTStringFromTime([_currentAudioFile currentTime]));
		//[_currentAudioFile updateForChapterPosition];
	}
	else // audio only book 
	{	
		NSLog(@"chapter name = %@",[_currentAudioFile currentChapterName]);
		//[_currentAudioFile updateForChapterPosition];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([keyPath isEqualToString:@"isPlaying"])
		(commonInstance.isPlaying) ? [_currentAudioFile play] : [_currentAudioFile stop];
	else if([keyPath isEqualToString:@"playbackVolume"])
		[_currentAudioFile setVolume:commonInstance.playbackVolume];
	else if([keyPath isEqualToString:@"playbackRate"])
	{
		if(!commonInstance.isPlaying) 
		{	
			// this is a workaround for the current issue where setting the 
			// playback speed using setRate: automatically starts playback
			[_currentAudioFile setAttribute:[NSNumber numberWithFloat:commonInstance.playbackRate] forKey:QTMoviePreferredRateAttribute];
			[_currentAudioFile stop];
		}
		else
		{	
			[_currentAudioFile setAttribute:[NSNumber numberWithFloat:commonInstance.playbackRate] forKey:QTMoviePreferredRateAttribute];
			[_currentAudioFile setRate:commonInstance.playbackRate];
		}
	}
	else
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
}



@synthesize  _idChapterMarkers, idToStartFrom, idToFinishWith;
@synthesize _xmlSmilDoc, _currentAudioFile, _currentFileURL, _relativeAudioFilePath, _currentNode;
@synthesize _parNodes, _parNodeIndexes;
@synthesize includeSkippableContent, useSmilChapters;
@synthesize audioPlayRate, audioVolume;
@synthesize commonInstance;

@end
