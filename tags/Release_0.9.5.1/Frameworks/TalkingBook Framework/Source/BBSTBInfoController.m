//
//  InfoWindowController.m
//  BBSTalkingBook
//
//  Created by Kieren Eaton on 30/11/08.
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


#import "BBSTBInfoController.h"
#import "BBSTBInfoItem.h"
#import "RegexKitLite.h"

@interface BBSTBInfoController (Private)

- (NSString *)expandImpliedWhitespace:(NSString *)aStr;
- (BBSTBInfoItem *)infoItemFromMetaElement:(NSXMLElement *)anElement;
- (NSString *)extraIdentifierNamesForElement:(NSXMLElement *)anElement;

@end



@implementation BBSTBInfoController

- (id) init
{
	if (!(self=[super init])) return nil;
	
	if (![NSBundle loadNibNamed:@"BookInfo" owner:self]) return nil;
	
	metaInfo = [[NSMutableArray alloc] init];
	
	

	return self;
}

- (id)initWithMetadataNode:(NSXMLNode *)aNode
{
	if(!(self=[self init])) return nil;
	
	[self updateMetaInfoFromNode:aNode];
	
	return self;
}




- (void)displayInfoPanel
{
	[infoPanel orderFront:self];
	[[infoTableView tableColumnWithIdentifier:@"content"] setWidth:_maxStrLen];
	[infoTableView reloadData];
}

- (void)updateMetaInfoFromNode:(NSXMLNode *)metaNode
{
	if([metaInfo count] > 0)
	{	
		[metaInfo removeAllObjects];
		_maxStrLen = 0.0;
	}

	NSArray *childNodes = [metaNode children];
	
	for(NSXMLElement *anElement in childNodes)
	{
		if([[[anElement name] lowercaseString] isEqualToString:@"dc-metadata"] || [[[anElement name] lowercaseString] isEqualToString:@"x-metadata"])
		{
			NSArray *subChildNodes = [anElement children];
			for(NSXMLElement *subElement in subChildNodes)
			{
				BBSTBInfoItem *newItem = [self infoItemFromMetaElement:subElement];
				
				// check for a duplicate item before adding it
				if(newItem && ![metaInfo containsObject:newItem])
					[metaInfo addObject:newItem];
			}
		}
		else
		{
			BBSTBInfoItem *newItem = [self infoItemFromMetaElement:anElement];
			// check for a duplicate item before adding it
			if(newItem && ![metaInfo containsObject:newItem])
				[metaInfo addObject:newItem];
		}
		
	}
	
	[[infoTableView tableColumnWithIdentifier:@"content"] setWidth:_maxStrLen];
	[infoTableView reloadData];

	
}
- (BBSTBInfoItem *)infoItemFromMetaElement:(NSXMLElement *)anElement
{
	NSMutableString *optionTitle = [[NSMutableString alloc] init];
	NSMutableString *optionContent = [[NSMutableString alloc] init];
	BBSTBInfoItem	*newItem = nil;
	
	// check if it has a name "meta"
	if([[anElement name] isEqualToString:@"meta"])
	{
		// check we have a name attribute this allows us to ignore all other extraneous meta nodes 
		if([anElement attributeForName:@"name"])
		{
			[optionTitle setString:[[anElement attributeForName:@"name"] stringValue]];
			[optionContent setString:[[anElement attributeForName:@"content"] stringValue]];
		}
	}
	else
	{
		// just a regular node with content
		[optionTitle setString:[anElement name]];
		[optionContent setString:[anElement stringValue]];
	}
	
	if(![optionTitle isEqualToString:@""])
	{
		// append any extra identifiers to the title
		[optionTitle appendString:[self extraIdentifierNamesForElement:anElement]];
		
		// strip off the namespace prefix if any from the title
		[optionTitle setString:[optionTitle stringByReplacingOccurrencesOfRegex:@"\\w*:(.*)" withString:@"$1"]];
		
		// expand the words if required and capitalize the first letter of the first word
		[optionTitle setString:[self expandImpliedWhitespace:optionTitle]];
		
		// set the max length of the string so we can use it to set the table column width
		_maxStrLen = ([optionContent sizeWithAttributes:nil].width > _maxStrLen) ? [optionContent sizeWithAttributes:nil].width : _maxStrLen;
		
		 newItem = [[BBSTBInfoItem alloc] initWithTitle:[NSString stringWithString:optionTitle] 
											 andContent:[NSString stringWithString:optionContent]]; 
	}
		
	return newItem;

}

- (NSString *)extraIdentifierNamesForElement:(NSXMLElement *)anElement
{
	// extract any attributes that will identify the name of the element further
	NSArray *attributes = [[NSArray alloc] initWithArray:[anElement attributes]];
	NSMutableString *addNames = [[NSMutableString alloc] init];
	
	// check if we have more than just the name and content attributes
	if([attributes count] > 0)
	{
		for(NSXMLNode *anAttribute in attributes)
		{
			if(![[[anAttribute name] lowercaseString] isEqualToString:@"name"] && ![[[anAttribute name] lowercaseString] isEqualToString:@"content"])
			{	
				[addNames appendFormat:@" %@",[anAttribute XMLString]];
				
				// uppercase the first character of the word
				[addNames replaceOccurrencesOfRegex:@"( [[:lowercase:]])" 
										 withString:[[addNames stringByMatching:@"( [[:lowercase:]])" capture:1] uppercaseString]];
			}
		}
	}
	
	return addNames;
	
}
- (NSString *)expandImpliedWhitespace:(NSString *)aStr
{
	NSMutableString *toExpand = [[NSMutableString alloc] initWithString:aStr];

	
	// word divisions are denoted by a lowercase char followed directly by an uppercase char
	NSString *regexstr = @"(.+[[:lower:]])([[:upper:]].+)";
	
	// init the ranges
	NSRange firstRange = NSMakeRange(NSNotFound, 0); 
	NSRange secondRange = NSMakeRange(NSNotFound, 0);	
	
	// get the division positions
	firstRange = [toExpand rangeOfRegex:regexstr capture:1];
	secondRange = [toExpand rangeOfRegex:regexstr capture:2];
	
	// check that we have a division to expand
	while((firstRange.location != NSNotFound) || (secondRange.location != NSNotFound) )
	{
		// put a space between the implied words
		[toExpand replaceOccurrencesOfRegex:regexstr withString:@"$1 $2"];
		
		// check for another division 
		firstRange = [toExpand rangeOfRegex:regexstr capture:1];
		secondRange = [toExpand rangeOfRegex:regexstr capture:2];
		
	}
	
	// uppercase the first character
	NSString *firstChar = [[toExpand stringByMatching:@"([[:alpha:]])" capture:1] uppercaseString];
	firstRange = NSMakeRange(0, 1);
	[toExpand replaceOccurrencesOfRegex:@"([[:alpha:]])" withString:firstChar range:firstRange];
	
	return toExpand;
}

#pragma mark -
#pragma mark =========  TableView Delegate Methods =========

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [metaInfo count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if([[aTableColumn identifier] isEqualToString:@"title"])
		return [[metaInfo objectAtIndex:rowIndex] title];
	else
		return [[metaInfo objectAtIndex:rowIndex] content];
}

@synthesize metaInfo;

@end
