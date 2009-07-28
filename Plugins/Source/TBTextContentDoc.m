//
//  TBTextContentDoc.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 13/07/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
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

#import "TBTextContentDoc.h"

@interface TBTextContentDoc ()

@property (readwrite, retain) NSXMLDocument	*_xmlTextDoc;
@property (readwrite, retain) NSXMLElement	*_xmlRoot;
@property (readwrite, retain) NSXMLNode		*_currentNode;

@end



@implementation TBTextContentDoc

- (id)initWithSharedData:(id)anInstance
{
	if (!(self=[super init])) return nil;
	
	if([[anInstance class] respondsToSelector:@selector(sharedBookData)])
		bookData = [[anInstance class] sharedBookData];
	
	return self;
}




- (BOOL)openWithContentsOfURL:(NSURL *)aURL
{
	BOOL loadedOk = NO;
	NSError *theError = nil;
	
	_xmlTextDoc = [[NSXMLDocument alloc] initWithContentsOfURL:aURL options:NSXMLDocumentTidyXML error:&theError];
	
	if(_xmlTextDoc)
	{
		loadedOk = YES;
		
	}
	else // we got a nil return so display the error to the user
	{
		NSAlert *theAlert = [NSAlert alertWithError:theError];
		[theAlert setMessageText:NSLocalizedString(@"Error Opening Text Content", @"text content open fail alert short msg")];
		[theAlert setInformativeText:NSLocalizedString(@"There was a problem opening the textual content file (.xml).\n This book may still play if it has audio content.", @"text content open fail alert long msg")];
		[theAlert beginSheetModalForWindow:[NSApp keyWindow] 
									modalDelegate:nil 
								  didEndSelector:nil 
									  contextInfo:nil];
	}
	
	return loadedOk;
}

- (void)processData
{
	
	// get the root element of the tree
	NSXMLElement *_xmlRoot = [_xmlTextDoc rootElement];
	_currentNode = nil;
	_currentNode = [[_xmlTextDoc nodesForXPath:@"/dtbook[1]/book[1]" error:nil] objectAtIndex:0];
	
}

- (void)jumpToNodeWithIdTag:(NSString *)aTag
{
	if(aTag)
	{	
		NSString *queryStr = [NSString stringWithFormat:@"/dtbook[1]/book[1]//*[@id='%@']",aTag];
		NSArray *tagNodes = nil;
		tagNodes = [_xmlTextDoc nodesForXPath:queryStr error:nil];
		
		_currentNode = ([tagNodes count]) ? [tagNodes objectAtIndex:0] : _currentNode;
	}
}

- (NSString *)currentIdTag
{
	
	NSArray *idTags = nil;
	idTags = [_currentNode objectsForXQuery:@"./data(@id)" error:nil];
	
	return ([idTags count]) ? [idTags objectAtIndex:0] : nil;
}

@synthesize bookData;
@synthesize _xmlTextDoc, _xmlRoot, _currentNode;

@end
