//
//  TBPackageDoc.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 25/08/08.
//  Copyright 2008 BrainBender Software. All rights reserved.
//
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

#import "TBPackageDoc.h"

@implementation TBPackageDoc

- (id) init
{
	if (!(self=[super init])) return nil;
	
	bookData = [TBSharedBookData sharedInstance];
	
	return self;
}

- (NSString *)stringForXquery:(NSString *)aQuery ofNode:(NSXMLNode *)theNode
{
	NSArray *queryContents = nil;
	// if we pass in nil for the node we use the root node as a default 
	if(!theNode)
		queryContents = [[xmlPackageDoc rootElement] objectsForXQuery:aQuery error:nil];
	else	
		queryContents = [theNode objectsForXQuery:aQuery error:nil];
	
	return ([queryContents count] > 0) ? [queryContents objectAtIndex:0] : nil;
}

#pragma mark -
#pragma mark methods Overridden By Subclasses

- (BOOL)openWithContentsOfURL:(NSURL *)aURL
{
	BOOL loadedOk = NO;
	
	NSError *theError;
	
	xmlPackageDoc = [[NSXMLDocument alloc] initWithContentsOfURL:aURL options:NSXMLDocumentTidyXML error:&theError];
	
	if(xmlPackageDoc)
	{
		loadedOk = YES;
	}
	else // we got a nil return so display the error to the user
	{
		NSAlert *theAlert = [NSAlert alertWithError:theError];
		[theAlert setMessageText:NSLocalizedString(@"Error Opening Package File", @"package open fail alert short msg")];
		[theAlert setInformativeText:NSLocalizedString(@"There was a problem opening the package file (.opf).\n Please try again or another book.", @"package open fail alert long msg")];
		[theAlert beginSheetModalForWindow:[NSApp keyWindow] 
							 modalDelegate:nil 
							didEndSelector:nil 
							   contextInfo:nil];
	}
	
	return loadedOk;
}

- (void)processData
{
	[self doesNotRecognizeSelector:_cmd];
}

- (NSXMLNode *)metadataNode
{
	NSArray *metaNodes = [xmlPackageDoc  objectsForXQuery:@"/package/metadata" error:nil];
	return ([metaNodes count] > 0) ? [metaNodes objectAtIndex:0] : nil;
}


- (NSString *)nextAudioSegmentFilename
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}
- (NSString *)prevAudioSegmentFilename
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@synthesize ncxFilename,textContentFilename;
@synthesize bookData;

@end
