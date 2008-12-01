//
//  BBSTBControlDoc.m
//  BBSTalkingBook
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


#import "BBSTBControlDoc.h"
#import "BBSTBNCXDocument.h"

@implementation BBSTBControlDoc

- (id) init
{
	if (!(self=[super init])) return nil;
	
	segmentTitle = @"";
	bookTitle = @"";
	totalPages = 0;
	totalTargetPages = 0;
	currentLevel = 0;
	documentUID = @"";
	bookMediaFormat = unknownMediaFormat;
	currentAudioFilename = @"";
	
	return self;
}

- (void)finalize
{
	[super finalize];
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
		loadedOk = [self processMetadata];
		if(loadedOk)
		{
			// get the root path for later use with smil and xmlcontent files
			parentFolderPath = [[aURL path] stringByDeletingLastPathComponent]; 
		}
		

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

- (BOOL)processMetadata
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (NSXMLNode *)metadataNode
{
	NSArray *metaNodes = [xmlControlDoc objectsForXQuery:@"//head" error:nil];
	return ([metaNodes count] > 0) ? [metaNodes objectAtIndex:0] : nil;
}

- (void)moveToNextSegment
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)moveToPreviousSegment
{
	[self doesNotRecognizeSelector:_cmd];
}

- (NSString *)currentSegmentFilename
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (void)updateAttributesForCurrentPosition
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
	return [[theNode objectsForXQuery:aQuery error:nil] objectAtIndex:0];
}


@synthesize levelNavChapterIncrement;
@synthesize currentLevel, currentPageNumber, totalPages, totalTargetPages;
@synthesize bookMediaFormat;
@synthesize segmentTitle, bookTitle, documentUID;
@synthesize currentAudioFilename, currentPositionID;
@synthesize navigateForChapters;
@synthesize metadataNode;


@end
