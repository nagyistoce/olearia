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

@interface TBNIMASPlugin ()


@end



@implementation TBNIMASPlugin

+ (BOOL)initializeClass:(NSBundle*)theBundle 
{
	// Dummy Method never gets called
	return NO;
}

+ (NSArray *)plugins
{
	// dummy method never gets called
	return nil;
}

+ (void)terminateClass
{
	// dummy method never gets called
}


- (id)textPlugin
{
	
	return nil;
}

- (id)smilPlugin
{
	// Text Only Book so no need for a SMIL plugin
	return nil;
}


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
	BOOL isValidUrl = [self canOpenBook:bookURL];
	
	if(isValidUrl)
	{
		// first check if we were passed a folder
		if ([fileUtils URLisDirectory:bookURL])
		{	
			self.bookData.folderPath = bookURL;
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
			
			packageDocument = [[TBOPFNimasDocument alloc] init];
			if([packageDocument openWithContentsOfURL:packageFileUrl])
			{
				// the opf file opened correctly
				// get the dc:Format node string
				NSString *bookFormatString = [[packageDocument stringForXquery:@"dc-metadata/data(*:Format)" ofNode:[packageDocument metadataNode]] uppercaseString];
				if(YES == [bookFormatString hasPrefix:@"NIMAS 1."])
				{
					// the opf file specifies that it is a NIMAS format book
					
					// set the folder path if required
					if(!bookData.folderPath)
						self.bookData.folderPath = [NSURL URLWithString:[[packageFileUrl path] stringByDeletingLastPathComponent]];
					
					// get the text content filename
					self.packageDocument.textContentFilename = [packageDocument stringForXquery:@"/package/manifest/item[@media-type='text/xml' ] [ends-with(@href,'.xml')] /data(@href)" ofNode:nil];
					[packageDocument processData];
					
					opfLoaded = YES;
				}
				else 
				{
					[packageDocument release];
					packageDocument = nil;
				}
				
			}
			else
			{
				[packageDocument release];
				packageDocument = nil;
			}
		}
	}
	
	// return YES if the Package document and/or Control Document loaded correctly
	// as we can do limited control and playback functions from the opf file this is a valid scenario.
	return (packageFileUrl && opfLoaded);
	
}

- (id)variantOfType
{
	// return the super classes id 
	return [self superclass];
}

- (NSXMLNode *)infoMetadataNode
{
	return [super infoMetadataNode];
}

- (NSURL *)loadedURL
{
	return [super loadedURL];
}

- (void)startPlayback
{
	// dummy method placeholder
}

- (void)stopPlayback
{
	// dummy method placeholder
}

- (NSString *)FormatDescription
{
	return NSLocalizedString(@"This Book has been authored with the NIMAS standard",@"NIMAS Standard description");
}



#pragma mark -

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

- (void)setupPluginSpecifics
{
	
	validFileExtensions = [NSArray arrayWithObject:@"opf"];
	
}

- (void) dealloc
{
	
	[super dealloc];
}

@synthesize validFileExtensions;

@end
