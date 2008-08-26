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

#import <Cocoa/Cocoa.h>
#import <QTKit/QTTime.h>
#import "NSString-BBSAdditions.h"
#import "BBSTBSMILDocument.h"
#import "BBSTalkingBookTypes.h"
#import "NSXMLElement-BBSExtensions.h"


@interface BBSTBSMILDocument ()

//@property (readwrite, retain) NSDictionary *smilContent;
@property (readwrite, retain) NSArray *smilContent;
@property (readwrite, retain) NSString *xmlContentFilename;
@property (readwrite, retain) NSDictionary *smilChapterData;
@property (readwrite, retain) NSString *filename;



- (NSString *)extractXmlContentFilename:(NSString *)contentString;
- (NSString *)extractIdString:(NSString *)contentString;
- (NSArray *)processData:(NSXMLDocument *)aDoc;

@end




@implementation BBSTBSMILDocument

@synthesize smilContent, smilChapterData;
@synthesize xmlContentFilename, filename;

- (id) init
{
	if (!(self=[super init])) return nil;
	
	return self;
}


- (id)initWithURL:(NSURL *)aURL 
{
	self = [super init];
	if (self != nil) 
	{
		NSError *theError;
		
		// open the validated opf URL
		NSXMLDocument	*xmlSmilDoc = [[NSXMLDocument alloc] initWithContentsOfURL:aURL options:NSXMLDocumentTidyXML error:&theError];
		
		if(xmlSmilDoc != nil)
		{
			self.smilContent = [self processData:xmlSmilDoc];
		}
		else // there was an error of some sort opening the smil file.
			return nil;
			
	}
	
	return self;
}


- (NSArray *)chapterMarkers
{
	NSMutableArray *markersArray = [[NSMutableArray alloc] init];
	
	
	for(NSDictionary *aMarkerDict in smilContent)
	{
		if(([aMarkerDict valueForKeyPath:@"text.src"] != nil) && ([aMarkerDict valueForKeyPath:@"audio.clipBegin"] != nil))
		{
			NSMutableDictionary *dictWithID = [[NSMutableDictionary alloc] init];
			
			[dictWithID setObject:[self extractIdString:[aMarkerDict valueForKeyPath:@"text.src"]] forKey:@"id"];
			NSString *clipStartString = [[NSString alloc] qtTimeStringFromSmilTimeString:[aMarkerDict valueForKeyPath:@"audio.clipBegin"]];
			[dictWithID setObject:clipStartString forKey:BBSTBClipBeginKey];
			[markersArray addObject:dictWithID];
			
		}
	}
	
	if([markersArray count] == 0)
	{	
		return nil;
	}
	
	return markersArray;
		
}

#pragma mark -
#pragma mark Private Methods


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
