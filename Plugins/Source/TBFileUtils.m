//
//  TBFileUtils.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 20/05/09.
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

#import "TBFileUtils.h"

@interface TBFileUtils()

@property (readwrite,retain) NSFileManager *fileManager;

@end


@implementation TBFileUtils

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		fileManager = [NSFileManager defaultManager];
	}
	return self;
}

- (void) dealloc
{
	[fileManager release];
	[super dealloc];
}


- (BOOL)URL:(NSURL *)aURL hasExtension:(NSArray *)validExtensions
{
	BOOL urlIsValid = NO;
	BOOL isDir;
	// check if the file path is valid for this plugin 
	NSString *filePath = [[NSString stringWithString:[aURL path]] lowercaseString];
	// check that we have a valid file and that it is not a folder
	if ((filePath != nil) && (([fileManager fileExistsAtPath:filePath isDirectory:&isDir]) && !isDir))
		urlIsValid = [validExtensions containsObject:[filePath pathExtension]];
	
	// return NO as a default
	return urlIsValid;
	
}

- (NSURL *)fileURLFromFolder:(NSString *)aPath WithExtension:(NSString *)anExtension
{
	BOOL isDir;
	NSArray *folderContents = nil;
	NSString *folderPath = nil;
	NSURL *newURL = nil; 
	// check if the passed in path is not a folder
	if(([fileManager fileExistsAtPath:aPath isDirectory:&isDir]) && !isDir)
	{
		folderPath = [NSString stringWithString:[aPath stringByDeletingLastPathComponent]];
		folderContents = [fileManager directoryContentsAtPath:folderPath];
	}
	else
	{	
		folderContents = [fileManager directoryContentsAtPath:aPath];
		folderPath = aPath;
	}
	
	// iterate through the folder contents to see if there is a file with the wanted extension.
	for(NSString *anItem in folderContents)
	{
		if([[[anItem pathExtension] lowercaseString] isEqualToString:anExtension])
		{	
			//NSString *fullPath = ;
			newURL = [[[NSURL alloc] initFileURLWithPath:[folderPath stringByAppendingPathComponent:anItem]] autorelease];
			break;
		}
			
		
	}
	
	// we didnt find a file with wanted extension
	return newURL;
	
}

- (NSArray *)fileURLsFromFolder:(NSString *)aPath WithExtension:(NSString *)anExtension
{
	BOOL isDir;
	NSString *folderPath = nil;
	NSDirectoryEnumerator *dirEnum = nil;
	//NSDirectoryEnumerator *dirEnum = [[[NSDirectoryEnumerator alloc] init] autorelease];
	NSMutableArray *foundPaths = [[[NSMutableArray alloc] init] autorelease];
	
	// check if the passed in path is not a folder
	if(([fileManager fileExistsAtPath:aPath isDirectory:&isDir]) && !isDir)
		folderPath = [[aPath stringByDeletingLastPathComponent] copy];
	else
		folderPath = [aPath copy];
	
	dirEnum = [fileManager enumeratorAtPath:folderPath];
	
	// iterate through the folder contents to see if there is any files with the wanted extension.
	for(NSString *anItem in dirEnum)
	{
		if([[[anItem pathExtension] lowercaseString] isEqualToString:anExtension])
		{	
			NSURL *theURL = [[[NSURL alloc] initFileURLWithPath:[folderPath stringByAppendingPathComponent:anItem]] autorelease];
			[foundPaths addObject:theURL];
		}
	}
	[folderPath release];
	
	return foundPaths;
}

- (BOOL)URLisDirectory:(NSURL *)aPath
{
	BOOL isDir;
	return (([fileManager fileExistsAtPath:[aPath path] isDirectory:&isDir]) && isDir);
}

@synthesize fileManager;


@end
