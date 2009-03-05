//
//  BBSTBPackageDoc.m
//  TalkingBook Framework
//
//  Created by Kieren Eaton on 25/08/08.
//  Copyright 2008 BrainBender Software. All rights reserved.
//

#import "BBSTBPackageDoc.h"

@implementation BBSTBPackageDoc

- (id) init
{
	if (!(self=[super init])) return nil;
	
	bookData = [BBSTBSharedBookData sharedInstance];
	
	return self;
}

- (NSString *)stringForXquery:(NSString *)aQuery ofNode:(NSXMLNode *)theNode
{
	NSArray *queryContents = [theNode objectsForXQuery:aQuery error:nil];
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
		loadedOk = [self processMetadata];
	}
	else // we got a nil return so display the error to the user
	{
		NSAlert *theAlert = [NSAlert alertWithError:theError];
		[theAlert setMessageText:NSLocalizedString(@"Error Opening Package File", @"package open fail alert short msg")];
		[theAlert setInformativeText:NSLocalizedString(@"Failed to open package file.\n Please check book structure or try another book.", @"package open fail alert long msg")];
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

@synthesize ncxFilename,xmlContentFilename;
@synthesize bookData;

@end
