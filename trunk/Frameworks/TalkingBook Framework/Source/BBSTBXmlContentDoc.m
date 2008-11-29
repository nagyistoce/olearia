//
//  BBSTBXmlContentDoc.m
//  BBSTalkingBook
//
//  Created by Kieren Eaton on 31/08/08.
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

#import "BBSTBXmlContentDoc.h"


@implementation BBSTBXmlContentDoc

- (id) init
{
	if (!(self=[super init])) return nil;
		
	return self;
}

- (BOOL)openWithContentsOfURL:(NSURL *)fileURL
{
	BOOL loadedOk = NO;
	
	NSError *theError;
	
	// open the validated URL
	xmlContentDoc = [[NSXMLDocument alloc] initWithContentsOfURL:fileURL options:NSXMLDocumentTidyXML error:&theError];
	
	if(xmlDoc)
	{
		loadedOk = YES;
	}
	
	return loadedOk;
}

- (NSString *)stringForXquery:(NSString *)aQuery ofNode:(NSXMLNode *)theNode
{
	return [[theNode objectsForXQuery:aQuery error:nil] objectAtIndex:0];
}

#pragma mark -
#pragma mark Subclass Overridden Methods

- (BOOL)processMetadata
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}


@end
