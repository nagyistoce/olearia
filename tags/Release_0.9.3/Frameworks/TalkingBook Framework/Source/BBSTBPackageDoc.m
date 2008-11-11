//
//  BBSTBPackageDoc.m
//  BBSTalkingBook
//
//  Created by Kieren Eaton on 25/08/08.
//  Copyright 2008 BrainBender Software. All rights reserved.
//

#import "BBSTBPackageDoc.h"

@implementation BBSTBPackageDoc


#pragma mark -
#pragma mark methods Overridden By Subclasses

- (BOOL)openPackageFileWithURL:(NSURL *)aURL
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
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

@synthesize bookTitle, bookSubject, bookTotalTime;
@synthesize bookMediaFormat, bookType;
@synthesize ncxFilename,xmlContentFilename;


@end
