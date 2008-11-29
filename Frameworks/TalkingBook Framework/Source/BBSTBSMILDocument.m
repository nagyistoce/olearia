//
//  BBSTBSMILDocument.m
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

//#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <QTKit/QTTime.h>
#import "NSString-BBSAdditions.h"
#import "BBSTBSMILDocument.h"
#import "BBSTalkingBookTypes.h"
#import "NSXMLElement-BBSExtensions.h"


@interface BBSTBSMILDocument ()

//@property (readwrite, retain) NSDictionary *smilContent;
@property (readwrite, retain) NSArray *parNodes;
@property (readwrite, retain) NSDictionary *parNodeIndexes;
//@property (readwrite, retain) NSArray *smilContent;
@property (readwrite, retain) NSString *xmlContentFilename;
@property (readwrite, retain) NSDictionary *smilChapterData;
//@property (readwrite, retain) NSString *filename;



- (NSString *)extractXmlContentFilename:(NSString *)contentString;
- (NSString *)extractIdString:(NSString *)contentString;
//- (NSArray *)processData:(NSXMLDocument *)aDoc;
- (NSDictionary *)createParNodeIndex:(NSArray *)someParNodes;
- (NSString *)idTagFromSrcString:(NSString *)anIdString;

@end




@implementation BBSTBSMILDocument

@synthesize  smilChapterData;
@synthesize xmlContentFilename;
@synthesize parNodes, parNodeIndexes;

- (id) init
{
	if (!(self=[super init])) return nil;
	
	parNodes = [[NSArray alloc] init]; 
	parNodeIndexes = [[ NSDictionary alloc] init];
	
	return self;
}


- (BOOL)openWithContentsOfURL:(NSURL *)aURL 
{
	NSError *theError;
	
	// open the validated opf URL
	NSXMLDocument	*xmlSmilDoc = [[NSXMLDocument alloc] initWithContentsOfURL:aURL options:NSXMLDocumentTidyXML error:&theError];
	
	if(xmlSmilDoc != nil)
	{
		// get the all the <par> nodes from the main seq node. Some may be inside nested <seq> tags but these will be ignored
		parNodes = [[xmlSmilDoc rootElement] objectsForXQuery:@"/smil/body/seq//par" error:nil];
		parNodeIndexes = [self createParNodeIndex:parNodes];
	}
	else // there was an error of some sort opening the smil file.
		return NO;
			
	return YES;
}

- (NSString *)audioFilenameForId:(NSString *)anId
{
	// get the index of the  id from the index dict
	NSInteger idIndex = [[parNodeIndexes valueForKey:anId] integerValue];
	// we get an array here because some par node have multiple time listings for the same file
	NSArray *filenamesArray = [[parNodes objectAtIndex:idIndex] objectsForXQuery:@".//audio/data(@src)" error:nil];
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

#pragma mark -
#pragma mark Private Methods

- (NSDictionary *)createParNodeIndex:(NSArray *)someParNodes
{
	NSMutableDictionary *tempNodeIndex = [[NSMutableDictionary alloc] init];
	NSMutableString *idTagString = [[NSMutableString alloc] init];
	NSInteger parIndex = 0;
	

	for(NSXMLElement *ParElement in parNodes)
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



@end
