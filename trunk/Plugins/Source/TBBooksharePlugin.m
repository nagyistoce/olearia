//
//  TBBooksharePlugin.m
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

#import "TBBooksharePlugin.h"
#import "TBOPFDocument.h"
#import "TBNCXDocument.h"

@interface TBBooksharePlugin ()



@end


@implementation TBBooksharePlugin

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

+ (TBBooksharePlugin *)bookType
{
	TBBooksharePlugin *instance = [[[self alloc] init] autorelease];
	if (instance)
	{	
		[instance setupPluginSpecifics];
		return instance;
	}
	
	return nil;
}

- (id)variantOfType
{
	// return nil as a default because not all plugins will be variants
	return [self superclass];
}

- (id)textPlugin
{
	
	return nil;
}

- (id)smilPlugin
{
	// Text Only Book so no need for a SMIL plugin
	// we return nil here as a courtesy for complete code introspection
	// as it is already nil in the supers superclass
	return nil;
}

- (void)setupPluginSpecifics
{
	validFileExtensions = [NSArray arrayWithObjects:@"opf",@"ncx",nil];

}

- (BOOL)openBook:(NSURL *)bookURL
{
	BOOL opfLoaded = NO;
	BOOL ncxLoaded = NO;
	NSURL *controlFileURL = nil;
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
			packageFileUrl = [fileUtils fileURLFromFolder:[bookData.folderPath path] WithExtension:@"opf"];
			// check if we found the OPF file
			if (!packageFileUrl)
				// no opf file found so check for the NCX file
				controlFileURL = [fileUtils fileURLFromFolder:[bookData.folderPath path] WithExtension:@"ncx"];
		}
		else
		{
			// file url
			// check the path contains a file with a valid extension
			if([fileUtils URL:bookURL hasExtension:validFileExtensions])
			{	
				NSString *filename = [bookURL path];
				// check for an opf extension
				if(YES == [[[filename pathExtension] lowercaseString] isEqualToString:@"opf"])
				{
					packageFileUrl = bookURL;
				}
				else if(YES == [[[filename pathExtension] lowercaseString] isEqualToString:@"ncx"])
				{
					// check if there is an OPF file to use instead
					packageFileUrl = [fileUtils fileURLFromFolder:[bookURL path] WithExtension:@"opf"];
					// check if we found the OPF file
					if (!packageFileUrl)
					{
						// no OPF file found fall back to the ncx one instead
						// this should not happen that often but might occasionally 
						// with badly authored books.
						controlFileURL = bookURL;  
						
						self.packageDocument = nil;
					}
				}
			}
		}
		
		if(packageFileUrl)
		{
			packageDocument = [[TBOPFDocument alloc] init];
			if([packageDocument openWithContentsOfURL:packageFileUrl])
			{
				// the opf file opened correctly
				// get the dc:Format node string
				NSString *bookFormatString = [[packageDocument stringForXquery:@"dc-metadata/data(*:Format)" ofNode:[packageDocument metadataNode]] uppercaseString];
				
				if(YES == [bookFormatString isEqualToString:@"ANSI/NISO Z39.86-2002"]) 
				{	
					NSString *schemeStr = [packageDocument stringForXquery:@"/package/metadata/dc-metadata/*:Identifier[@scheme='BKSH']/data(.)" ofNode:nil];
					if((schemeStr) && (YES == [[schemeStr lowercaseString] hasPrefix:@"bookshare"]))
					{
						// the opf file specifies that it is a 2002 format book and it has the bookshare scheme tag
						self.bookData.folderPath = [[NSURL alloc] initFileURLWithPath:[[packageFileUrl path] stringByDeletingLastPathComponent] isDirectory:YES];
						
						// get the ncx filename
						packageDocument.ncxFilename = [packageDocument stringForXquery:@"/package/manifest/item[@media-type='text/xml' ] [ends-with(@href,'.ncx')] /data(@href)" ofNode:nil];
						// get the text content filename
						packageDocument.textContentFilename = [packageDocument stringForXquery:@"/package/manifest/item[@media-type='text/xml' ] [ends-with(@href,'.xml')] /data(@href)" ofNode:nil];
						[packageDocument processData];
						controlFileURL = [NSURL URLWithString:[packageDocument ncxFilename] relativeToURL:bookData.folderPath];  
						
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
			else 
			{
				[packageDocument release];
				packageDocument = nil;
			}
		}
		
		if (controlFileURL)
		{
			controlDocument = [[TBNCXDocument alloc] init];
			// check if the folder path has already been set
			if (!bookData.folderPath)
				self.bookData.folderPath = [NSURL URLWithString:[[controlFileURL path] stringByDeletingLastPathComponent]];
			// attempt to load the ncx file
			
		}
	}
	
	// return YES if the Package document and/or Control Document loaded correctly
	// as we can do limited control and playback functions from the opf file this is a valid scenario.
	return (((nil != packageFileUrl) && opfLoaded) || ((nil != controlFileURL) && ncxLoaded));
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
	return NSLocalizedString(@"This Book has been authored with the BookShare standard",@"BookShare Standard description");
}

- (NSURL *)loadedURL
{
	return [super loadedURL];
}

- (NSXMLNode *)infoMetadataNode
{
	return [super infoMetadataNode];
}


#pragma mark -

- (void) dealloc
{
	
	[super dealloc];
}

#pragma mark -
#pragma mark Private Methods



@end
