//
//  TBControlDoc.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 14/08/08.
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

#import "TBControlDoc.h"

@interface TBControlDoc ()

@property (readwrite, copy)	NSURL	*fileURL;

@end




@implementation TBControlDoc

- (id) init
{
	if (!(self=[super init])) return nil;
	
	// get the shared instance which contains all our updatable data for the book
	bookData = [TBSharedBookData sharedInstance];
	
	return self;
}

- (void)finalize
{
	[super finalize];
}

- (void) dealloc
{
	bookData = nil;
	[super dealloc];
}


#pragma mark -
#pragma mark methods Overridden By Subclasses

- (BOOL)openWithContentsOfURL:(NSURL *)aURL
{
	BOOL loadedOk = NO;
	
	NSError *theError;
	
	xmlControlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:aURL options:NSXMLDocumentTidyXML error:&theError];
	
	if(xmlControlDoc)
	{
		fileURL = aURL;
		[self processData];
		
		
			// jump to the first node in the control file
			[self jumpToNodeWithId:@""];
			
			// get the root path for later use with smil and xmlcontent files
			parentFolderPath = [[aURL path] stringByDeletingLastPathComponent]; 
		
		

	}
	else // we got a nil return so display the error to the user
	{
		NSAlert *theAlert = [NSAlert alertWithError:theError];
		[theAlert setMessageText:NSLocalizedString(@"Error Opening Control File", @"control open fail alert short msg")];
		[theAlert setInformativeText:NSLocalizedString(@"Failed to open the control file.\n Please check book structure or try another book.", @"control open fail alert long msg")];
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
	// this super class method will only be used for querying ncc.html control docs 
	// as the NCX files do not hold as much info as the OPF ones
	// will be subclassed as neccessary 
	NSArray *metaNodes = [xmlControlDoc objectsForXQuery:@"//head" error:nil];
	return ([metaNodes count] > 0) ? [metaNodes objectAtIndex:0] : nil;
}

- (void)jumpToNodeWithId:(NSString *)fullPathToNode
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)moveToNextSegment
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)moveToPreviousSegment
{
	[self doesNotRecognizeSelector:_cmd];
}

- (NSString *)filenameFromID:(NSString *)anIdString
{
	NSAssert(anIdString != nil, @"anIdString is nil");
	int markerPos = [anIdString rangeOfString:@"#"].location;
	return (markerPos > 0) ? [anIdString substringToIndex:markerPos] : anIdString;
	
}


- (NSString *)audioFilenameFromCurrentNode
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}

- (void)updateDataForCurrentPosition
{
	[self doesNotRecognizeSelector:_cmd];
}

- (BOOL)canGoNext
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}
- (BOOL)canGoPrev;
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (BOOL)canGoUpLevel;
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (BOOL)canGoDownLevel;
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (void)goUpALevel;
{
	[self doesNotRecognizeSelector:_cmd];
	
}

- (void)goDownALevel;
{
	[self doesNotRecognizeSelector:_cmd];
	
}

- (BOOL)nextSegmentIsAvailable
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (BOOL)PreviousSegmentIsAvailable
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (NSString *)stringForXquery:(NSString *)aQuery ofNode:(NSXMLNode *)theNode
{
	NSArray *queryContents;
	if(!theNode)
	{
		queryContents = [[xmlControlDoc rootElement] objectsForXQuery:aQuery error:nil];
	}
	else
	{
		queryContents = [theNode objectsForXQuery:aQuery error:nil];	
	}
	
	return ([queryContents count] > 0) ? [queryContents objectAtIndex:0] : nil;
}

- (TalkingBookType)supportedType
{
	return UnknownBookType;
}

#pragma mark -
#pragma mark ===== Notification Methods =====

- (void)doPositionalUpdate:(NSNotification *)aNote
{
	NSLog(@"idtag = %@",(NSString*)[aNote object]);

}

@synthesize currentPositionID;
@synthesize navigateForChapters, stayOnCurrentLevel;
@synthesize metadataNode, currentNavPoint;
@synthesize bookData, fileURL;

@end
