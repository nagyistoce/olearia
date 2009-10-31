//
//  TBNIMASPlugin.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 20/05/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
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

#import "TBNIMASPlugin.h"
#import "TBOPFNimasDocument.h"
#import "TBNavigationController.h"

@interface TBNIMASPlugin (Private)

- (BOOL)canOpenBook:(NSURL *)bookURL;

@end

@implementation TBNIMASPlugin

+ (TBNIMASPlugin *)bookType
{
	TBNIMASPlugin *instance = [[[self alloc] init] autorelease];
	if (instance)
	{	
		[instance setupPluginSpecifics];
		return instance;
	}

	return nil;
}

- (BOOL)openBook:(NSURL *)bookURL
{
	BOOL opfLoaded = NO;
	
	NSURL *packageFileUrl = nil;
	
	// do a sanity check first to see that we can attempt to open the book. 
	if([self canOpenBook:bookURL])
	{
		// first check if we were passed a folder
		if ([fileUtils URLisDirectory:bookURL])
		{	
			bookData.baseFolderPath = bookURL;
			// passed a folder so first check for an OPF file 
			packageFileUrl = [fileUtils fileURLFromFolder:[bookURL path] WithExtension:@"opf"];
		}
		else
		{
			// file url passed in
			NSString *filename = [bookURL path];
			// check for an opf extension
			if(YES == [[[filename pathExtension] lowercaseString] isEqualToString:@"opf"])
			{
				packageFileUrl = bookURL;
			}
		}
		
		if(packageFileUrl)
		{
			if(!packageDoc)
				packageDoc = [[TBOPFNimasDocument alloc] init];
			
			if([packageDoc openWithContentsOfURL:packageFileUrl])
			{
				// the opf file opened correctly
				// get the dc:Format node string
				NSString *bookFormatString = [[packageDoc stringForXquery:@"dc-metadata/data(*:Format)" ofNode:[packageDoc metadataNode]] uppercaseString];
				if(YES == [bookFormatString hasPrefix:@"NIMAS 1."])
				{
					// the opf file specifies that it is a NIMAS format book
					
					// set the folder path if required
					if(!bookData.baseFolderPath)
						bookData.baseFolderPath = [NSURL URLWithString:[[packageFileUrl path] stringByDeletingLastPathComponent]];
					
					// get the text content filename
					packageDoc.textContentFilename = [packageDoc stringForXquery:@"/package/manifest/item[@media-type='text/xml' ] [ends-with(@href,'.xml')] /data(@href)" ofNode:nil];
					
					[packageDoc processData];
					
					bookData.mediaFormat = TextOnlyNcxOrNccMediaFormat;
					
					opfLoaded = YES;
				}
				else 
					packageDoc = nil;
			}
			else
				packageDoc = nil;
		}
		
		
		if(opfLoaded)
		{
			//[super loadCorrectNavControllerForBookFormat];
			
			// load nimas specific nav controller here
			
			navCon.packageDocument = packageDoc;
			packageDoc = nil;
			currentPlugin = self;
			
			//[navCon moveControlPoint:nil withTime:nil];
			
			[navCon prepareForPlayback];
			
		}
		
	}
	else
		if(navCon)
			[navCon resetController];

	
	// return YES if the Package document and/or Control Document loaded correctly
	// as we can do limited control and playback functions from the opf file this is a valid scenario.
	return (opfLoaded);
	
}


- (void)startPlayback
{
	[super startPlayback];
}

- (void)stopPlayback
{
	[super stopPlayback];
}

- (NSString *)FormatDescription
{
	return LocalizedStringInTBStdPluginBundle(@"This Book has been authored with the NIMAS standard",@"NIMAS Standard description");
}

- (NSURL *)loadedURL
{
	return [super loadedURL];
}

- (BOOL)isVariant
{
	return YES;
}

- (NSXMLNode *)infoMetadataNode
{
	return [super infoMetadataNode];
}

- (NSString *)currentPlaybackTime
{
	return [super currentPlaybackTime];
}

- (NSString *)currentControlPoint
{
	return [super currentControlPoint];
}

- (void)jumpToControlPoint:(NSString *)aPoint andTime:(NSString *)aTime
{
	[super jumpToControlPoint:aPoint andTime:aTime];
}


#pragma mark -
#pragma mark Navigation

- (void)nextReadingElement;
{
	[super nextReadingElement];
}

- (void)previousReadingElement;
{
	[super previousReadingElement];
}

- (void)upLevel;
{
	[super upLevel];
}

- (void)downLevel
{
	[super downLevel];
}

#pragma mark -


- (void)setupPluginSpecifics
{
	
	validFileExtensions = [[NSArray alloc] initWithObjects:@"opf",nil];
	
}

- (void) dealloc
{
	[super dealloc];
}



@end

@implementation TBNIMASPlugin (Private)

// this method checks the url for a file with a valid extension
// if a directory URL is passed in the entire folder is scanned 
- (BOOL)canOpenBook:(NSURL *)bookURL;
{
	NSURL *fileURL = nil;
	// first check if we were passed a folder
	if ([fileUtils URLisDirectory:bookURL])
	{	// we were so check for an OPF file 
		fileURL = [fileUtils fileURLFromFolder:[bookURL path] WithExtension:@"opf"];
		// check if we found the OPF file
		if (fileURL)
			return YES;		
	}
	else
	{
		// check the path contains a file with a valid extension
		if([fileUtils URL:bookURL hasExtension:validFileExtensions])
			return YES;
	}
	
	// this did not find a valid extension that it could attempt to open
	return NO;
}


@end
