//
//  DTB202BookPlugin.m
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


#import "DTB202BookPlugin.h"
#import "TBNCCDocument.h"
#import "TBNavigationController.h"

@interface DTB202BookPlugin (Private)

- (BOOL)canOpenBook:(NSURL *)bookURL;

@end

@implementation DTB202BookPlugin

- (void)setupPluginSpecifics
{

}

+ (DTB202BookPlugin *)bookType
{
	DTB202BookPlugin *instance = [[[self alloc] init] autorelease];
	if (instance)
	{	
		[instance setupPluginSpecifics];
		return instance;
	}
	
	return nil;
}

- (void) dealloc
{
	[super dealloc];
}

- (BOOL)openBook:(NSURL *)bookURL
{
	
	BOOL nccLoaded = NO;
	BOOL navConDidLoad = NO;
	NSURL *controlFileURL = nil;
	TBControlDoc *controlDoc = nil;

	

	// do a sanity check first to see that we can attempt to open the URL. 
	if([self canOpenBook:bookURL])
	{
		// first check if we were passed a folder
		if ([fileUtils URLisDirectory:bookURL])
		{	
			//self.bookData.baseFolderPath = bookURL;
			NSArray *htmlFiles = [fileUtils fileURLsFromFolder:[bookURL path] WithExtension:@"html"];
			if([htmlFiles count])
			{
				for(NSURL *fileURL in htmlFiles)
				{
					if([[[[fileURL path] lastPathComponent] lowercaseString] isEqualToString:@"ncc.html"])
					{	
						controlFileURL = [[[NSURL alloc] initFileURLWithPath:[fileURL path]] autorelease];
						break;
					}
				}
			}
		}
		else
		{
			// valid file url passed in 
			// check for an ncc.html file
			if(YES == [[[[bookURL path] lastPathComponent] lowercaseString] isEqualToString:@"ncc.html"])
			{
				controlFileURL = [[[NSURL alloc] initFileURLWithPath:[bookURL path]] autorelease];
			}
			else 
			{
				// passed a file that was not an ncc.html so check for an ncc.html file in the folder 
				NSArray *htmlFiles = [fileUtils fileURLsFromFolder:[[bookURL path] stringByDeletingLastPathComponent] WithExtension:@"html"];
				if([htmlFiles count])
				{
					for(NSURL *fileURL in htmlFiles)
					{
						if([[[[fileURL path] lastPathComponent] lowercaseString] isEqualToString:@"ncc.html"])
						{	
							controlFileURL = [[fileURL copy] autorelease];
							break;
						}
					}
				}
			}
		}
		
		
		if (controlFileURL)
		{
			// attempt to load the ncc.html file
			if(!controlDoc)
				controlDoc = [[TBNCCDocument alloc] init];
			
			if([controlDoc openWithContentsOfURL:controlFileURL])
			{
				// check if the folder path has already been set
				if (!bookData.baseFolderPath)
					self.bookData.baseFolderPath = [NSURL fileURLWithPath:[[controlFileURL path] stringByDeletingLastPathComponent]];
				// the control file opened correctly
				// get the dc:Format node string
				NSString *bookFormatString = [controlDoc stringForXquery:@"/html/head/meta[ends-with(@name,'format')] /data(@content)" ofNode:nil];
				if(YES == [bookFormatString hasSuffix:@"2.02"])
				{
					
					[controlDoc processData];
					nccLoaded = YES;
				}
				else 
				{
					controlDoc = nil;
					
				}
				
			}
			else 
			{
	
				controlDoc = nil;
				
			}
		}
		
		if(nccLoaded)
		{
			TalkingBookMediaFormat mediaFormat = [self mediaFormatFromString:[controlDoc mediaFormatString]];
			navConDidLoad = [self loadCorrectNavControllerForBookFormat:mediaFormat];
			
			if (navConDidLoad)
			{
				
				self.navCon.bookMediaFormat = mediaFormat;
				self.navCon.controlDocument = controlDoc;
				controlDoc = nil;
				
				//[navCon moveControlPoint:nil withTime:nil];
				
				[navCon prepareForPlayback];
				
				self.currentPlugin = self;
				
			}
		}
	}
	else
		if(navCon)
			[navCon resetController];
	
	
	// return YES if NCC.html Control Document loaded correctly
	return (nccLoaded && navConDidLoad);
}

- (NSXMLNode *)infoMetadataNode
{
	if(navCon.controlDocument)
		return [[navCon controlDocument] metadataNode];

	return nil;
}

- (NSURL *)loadedURL
{
	if(navCon.controlDocument)
		return [[navCon controlDocument] fileURL];
	
	return nil;
}

#pragma mark -
#pragma mark Navigation

- (NSString *)FormatDescription
{
	return LocalizedStringInTBStdPluginBundle(@"This Book has been authored with the Daisy 2.02 standard",@"Daisy 2.02 Standard description");
}

@end

@implementation DTB202BookPlugin (Private)

- (BOOL)canOpenBook:(NSURL *)bookURL
{
	NSURL *fileURL = nil;
	// first check if we were passed a folder
	if ([fileUtils URLisDirectory:bookURL])
	{	
		// we were so first check for an ncc.html file in the passed folder 
		fileURL = [NSURL URLWithString:@"ncc.html" relativeToURL:bookURL];
	}
	else
	{
		// check the path is an ncc.html file
		if([[[[bookURL path] lastPathComponent] lowercaseString] isEqualToString:@"ncc.html"])
			fileURL = bookURL;
			
	}
	
	if (fileURL)
		return YES;	
	
	// did not find a valid file for opening
	return NO;
}

@end

