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
#import <QTKit/QTTime.h>
#import "NSString-BBSAdditions.h"

#import "BBSTalkingBookTypes.h"
#import "NSXMLElement-BBSExtensions.h"
#import "BBSTBAudioSegment.h"
#import "BBSTBCommonDocClass.h"


@interface BBSTBSMILDocument ()

//@property (readwrite, retain) NSDictionary *smilContent;
@property (readwrite, retain) NSArray *_parNodes;
@property (readwrite, retain) NSDictionary *_parNodeIndexes;
//@property (readwrite, retain) NSArray *smilContent;
//@property (readwrite, retain) NSString *xmlContentFilename;
@property (readwrite, retain) NSDictionary *smilChapterData;
//@property (readwrite, retain) NSString *filename;

@property (readwrite, retain)	NSXMLDocument		*_xmlSmilDoc;
@property (readwrite, retain)   BBSTBAudioSegment	*_currentAudioFile;

- (void)audioFileDidEnd:(NSNotification *)notification;
//- (void)loadStateDidChange:(NSNotification *)notification;

- (NSString *)extractXmlContentFilename:(NSString *)contentString;
- (NSString *)extractIdString:(NSString *)contentString;
//- (NSArray *)processData:(NSXMLDocument *)aDoc;
- (NSDictionary *)createParNodeIndex:(NSArray *)someParNodes;
- (NSString *)idTagFromSrcString:(NSString *)anIdString;

@end




@implementation BBSTBSMILDocument


- (id) init
{
	if (!(self=[super init])) return nil;
	
	_currentFilePath = [[NSURL alloc] init];
	
	_parNodes = [[NSArray alloc] init]; 
	_parNodeIndexes = [[ NSDictionary alloc] init];
	
	_isPlaying = NO;
	
	commonInstance = [BBSTBCommonDocClass sharedInstance];
	
//	// watch for load state changes
//	[[NSNotificationCenter defaultCenter] addObserver:self
//											 selector:@selector(loadStateDidChange:)
//												 name:QTMovieLoadStateDidChangeNotification
//											   object:_currentAudioFile];
	
	// start watching for notifications for reaching the end of the audio file
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(audioFileDidEnd:) 
												 name:QTMovieDidEndNotification 
											   object:_currentAudioFile];
	
	return self;
}

- (void) dealloc
{
	[_parNodes release];
	[_parNodeIndexes release];
	
	[_currentFilePath release];
	
	if(_xmlSmilDoc)
		[_xmlSmilDoc release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if(_currentAudioFile)
		[_currentAudioFile release];
	
	[super dealloc];
}


- (BOOL)openWithContentsOfURL:(NSURL *)aURL 
{
	NSError *theError;
	BOOL openedOk = NO;
	
	// check that we are opening a new file
	if(![aURL isEqualTo:_currentFilePath])
	{
		_currentFilePath = aURL;
		// open the URL
		if(_xmlSmilDoc)
			[_xmlSmilDoc release];
		
		_xmlSmilDoc = [[NSXMLDocument alloc] initWithContentsOfURL:aURL options:NSXMLDocumentTidyXML error:&theError];
		
		if(_xmlSmilDoc != nil)
		{
			// get the all the <par> nodes from the main seq node. Some may be inside nested <seq> tags but these will be ignored
			_parNodes = [[_xmlSmilDoc rootElement] objectsForXQuery:@"/smil/body/seq//par" error:nil];
			_parNodeIndexes = [self createParNodeIndex:_parNodes];
			openedOk = YES;
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

- (float)audioPlayRate
{
	return [_currentAudioFile rate];
}

- (void)setAudioPlayRate:(float)aRate
{
	if(!_isPlaying) 
	{	
		// this is a workaround for the current issue where setting the 
		// playback speed using setRate: automatically starts playback
		[_currentAudioFile stop];
		[_currentAudioFile setAttribute:[NSNumber numberWithFloat:aRate] forKey:QTMoviePreferredRateAttribute];
	}
	else
	{
		[_currentAudioFile setRate:aRate];
	}
	
}

- (float)audioVolume
{
	return [_currentAudioFile volume];
}
	
- (void)setAudioVolume:(float)aVolume
{
	[_currentAudioFile setVolume:aVolume];
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

- (NSString *)idTagFromSrcString:(NSString *)anIdString
{
	NSAssert(anIdString != nil, @"anIdString is nil");
	int markerPos = [anIdString rangeOfString:@"#"].location;
	return (markerPos > 0) ? [anIdString substringFromIndex:(markerPos+1)] : nil;
	
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

- (NSString *)extractIdString:(NSString *)contentString
{
	// get the position of the # symbol in the string which is the delimiter between filename and ID tag
	NSInteger position = [contentString rangeOfString:@"#"].location;
	return ((position > 0) ? [contentString substringFromIndex:(position+1)] : nil); 
}




- (void)setPreferredAudioAttributes
{
//	[_currentAudioFile setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieRateChangesPreservePitchAttribute];
//	[_currentAudioFile setAttribute:[NSNumber numberWithFloat:[audioAttributes valueForKey:@"]] forKey:QTMoviePreferredVolumeAttribute];
//	[currentAudioFile setVolume:self.playbackVolume];
//	[currentAudioFile setAttribute:[NSNumber numberWithFloat:self.playbackRate] forKey:QTMoviePreferredRateAttribute];
//	[currentAudioFile setDelegate:self];
}

- (BOOL)updateAudioFile:(NSString *)pathToFile
{
//	NSError *theError = nil;
//	BOOL loadedOK = NO;
//	
//	// check that we have not passed in a nil string
//	if(pathToFile != nil)
//	{
//		// check if we have the same file path as we used for the previous segment
//		if(NO == [_currentSegmentFilename isEqualToString:pathToFile])
//		{
//			_currentSegmentFilename = pathToFile;
//			
//			[_currentAudioFile stop]; // pause the playback if there is any currently playing
//			
//			_currentAudioFile = nil;
//			_currentAudioFile = [QTMovie movieWithFile:pathToFile error:&theError];
//			
//			
//			if(_currentAudioFile != nil)
//			{
//				// make the file editable and set the timescale for it 
//				[_currentAudioFile setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
//				[self setPreferredAudioAttributes];
//				if(([[_currentAudioFile attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete) && (NO == [_currentAudioFile hasChapters]))
//				{
//					[TalkingBookNotificationCenter postNotificationName:QTMovieLoadStateDidChangeNotification object:_currentAudioFile];
//				}
//				//[self updateForPosInBook];
//				loadedOK = YES;
//			}
//		}
//		else
//		{
//			loadedOK = YES;
//			
//			//shouldJumpToTime = YES;
//			//audioSegmentTimePosition = [_curr];
//		}
//	}
//	
//	if(shouldJumpToTime) //
//	{
//		shouldJumpToTime = NO; // reset the flag
//		[_currentAudioFile setCurrentTime:QTTimeFromString(audioSegmentTimePosition)];
//	}
//	
//	[self updateForPosInBook];
//	
//	if((nil == _currentAudioFile) || (loadedOK == NO))
//	{	
//		NSAlert *theAlert = [NSAlert alertWithError:theError];
//		[theAlert setMessageText:NSLocalizedString(@"Error Opening Audio File", @"audio error alert short msg")];
//		[theAlert setInformativeText:NSLocalizedString(@"There was a problem loading an audio file.\n Please check the book format for problems.\nOlearia will now reset as this book will not play", @"audio error alert short msg")];
//		[theAlert setAlertStyle:NSWarningAlertStyle];
//		[theAlert setIcon:[NSImage imageNamed:@"olearia.icns"]];		
//		[theAlert beginSheetModalForWindow:[NSApp keyWindow] modalDelegate:self didEndSelector:@selector(errorDialogDidEnd) contextInfo:nil];
//		
//		return NO;
//	}
	
	return YES;
}



#pragma mark -
#pragma mark --------- Notifications ---------

- (void)audioFileDidEnd:(NSNotification *)notification
{
	
}


//- (void)loadStateDidChange:(NSNotification *)notification
//{
//	
//	if([[[notification object] attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete)
//	{
//	
//		// add chapters to the current audio file
//		[_currentAudioFile addChaptersOfDuration:chapterSkipDuration];
//		
//	
//	}
//	
//
//}


@synthesize  smilChapterData;
@synthesize _xmlSmilDoc, _currentAudioFile;
@synthesize _parNodes, _parNodeIndexes;
@synthesize includeSkippableContent, useSmilChapters;
@synthesize  chapterSkipDuration, audioPlayRate, audioVolume;

@end
