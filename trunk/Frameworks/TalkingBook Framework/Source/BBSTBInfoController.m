//
//  InfoWindowController.m
//  Olearia
//
//  Created by Kieren Eaton on 30/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BBSTBInfoController.h"
#import "BBSTBInfoItem.h"
#import "RegexKitLite.h"

@interface BBSTBInfoController (Private)

- (NSString *)expandImpliedWhitespace:(NSString *)aStr;

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

- (void)awakeFromNib
{
	
}

- (void)displayInfoPanel
{
	[infoPanel orderFront:self];
	[infoTableView reloadData];
}

- (void)updateMetaInfoFromNode:(NSXMLNode *)metaNode
{
	if([metaInfo count] > 0)
		[metaInfo removeAllObjects];
	
	//NSRange matchedRange = NSMakeRange(NSNotFound, 0); // setup the range
	NSMutableString *optionTitle = [[NSMutableString alloc] init];
	NSMutableString *optionContent = [[NSMutableString alloc] init];
	
	//NSXMLElement *nodeAsElement = (NSXMLElement *)metaNode;
	NSArray *childNodes = [metaNode children];
	for(NSXMLElement *anElement in childNodes)
	{
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
			// strip off the namespace prefix if any from the title
			[optionTitle setString:[optionTitle stringByReplacingOccurrencesOfRegex:@".+:(.+)" withString:@"$1"]];
			
			// expand the words if required and capitalize the first letter
			[optionTitle setString:[self expandImpliedWhitespace:optionTitle]];
			
			
			
			BBSTBInfoItem *newItem = [[BBSTBInfoItem alloc] initWithTitle:[NSString stringWithString:optionTitle] 
															   andContent:[NSString stringWithString:optionContent]]; 
			
			// check for a duplicate item before adding it
			if(![metaInfo containsObject:newItem])
				[metaInfo addObject:newItem];
		}
				
	}

	[infoTableView reloadData];
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
