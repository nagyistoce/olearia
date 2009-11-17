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
#import "TBBookshareNavigationController.h"

@interface TBBooksharePlugin (Private)

- (BOOL)canOpenBook:(NSURL *)bookURL;

@end


@implementation TBBooksharePlugin

- (BOOL)openBook:(NSURL *)bookURL
{
	BOOL opfLoaded = NO;
	BOOL ncxLoaded = NO;
	NSURL *controlFileURL = nil;
	NSURL *packageFileUrl = nil;
	_mediaFormat = UnknownMediaFormat;
	
	// do a sanity check first to see that we can attempt to open the book. 
	if([self canOpenBook:bookURL])
	{
		// first check if we were passed a folder
		if ([fileUtils URLisDirectory:bookURL])
		{	
			bookData.baseFolderPath = bookURL;
			// passed a folder so first check for an OPF file 
			packageFileUrl = [fileUtils fileURLFromFolder:[bookData.baseFolderPath path] WithExtension:@"opf"];
			// check if we found the OPF file
			if (!packageFileUrl)
				// no opf file found so check for the NCX file
				controlFileURL = [fileUtils fileURLFromFolder:[bookData.baseFolderPath path] WithExtension:@"ncx"];
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
						
						packageDoc = nil;
					}
				}
			}
		}
		
		if(packageFileUrl)
		{
			if(!packageDoc)
				packageDoc = [[[TBOPFDocument alloc] init] autorelease];
						
			if([packageDoc openWithContentsOfURL:packageFileUrl])
			{
				// the opf file opened correctly
				// get the dc:Format node string
				NSString *bookFormatString = [[packageDoc stringForXquery:@"/package[1]/metadata[1]/dc-metadata[1]/data(*:Format)" ofNode:nil] uppercaseString];
				
				if(YES == (([bookFormatString isEqualToString:@"ANSI/NISO Z39.86-2002"]) || ([bookFormatString isEqualToString:@"ANSI/NISO Z39.86-2005"]))) 
				{	
					NSString *schemeStr = [packageDoc stringForXquery:@"/package[1]/metadata[1]/dc-metadata[1]/*:Identifier[@scheme='BKSH']/data(.)" ofNode:nil];
					if((nil != schemeStr) && (YES == [[schemeStr lowercaseString] hasPrefix:@"bookshare"]))
					{
						// the opf file specifies that it is a 2002/2005 format book and it has the bookshare scheme tag
						bookData.baseFolderPath = [NSURL fileURLWithPath:[[packageFileUrl path] stringByDeletingLastPathComponent] isDirectory:YES];
						
						// get the ncx filename
						packageDoc.ncxFilename = [packageDoc stringForXquery:@"/package[1]/manifest[1]/item[@id='ncx']/data(@href)" ofNode:nil];

						// get the text content filename
						packageDoc.textContentFilename = [packageDoc stringForXquery:@"(/package[1]/manifest[1]/item[@id='xml']|/package[1]/manifest[1]/item[@id='text'])/data(@href)" ofNode:nil];

						[packageDoc processData];
						
						// we set the format here to override the unknown format found in the processData Method
						_mediaFormat = TextWithControlMediaFormat;
						
						controlFileURL = [NSURL URLWithString:packageDoc.ncxFilename relativeToURL:bookData.baseFolderPath];  
						
						opfLoaded = YES;
					}
					else 
						packageDoc = nil;
				}
				else 
					packageDoc = nil;
			}
			else 
				packageDoc = nil;
		}
		
		if (controlFileURL)
		{
			if(!controlDoc)
				controlDoc = [[[TBNCXDocument alloc] init] autorelease];
				
			// check if the folder path has already been set
			if (!bookData.baseFolderPath)
				bookData.baseFolderPath = [NSURL URLWithString:[[controlFileURL path] stringByDeletingLastPathComponent]];
			// attempt to load the ncx file
			
			if([controlDoc openWithContentsOfURL:controlFileURL])
			{	
				[controlDoc processData];
				ncxLoaded = YES;
			}
			
			_mediaFormat = TextWithControlMediaFormat;
			
		}
		
		if(ncxLoaded || opfLoaded)
		{
			
			if(!navCon)
				navCon = [[TBBookshareNavigationController alloc] init];
			
			_mediaFormat = TextWithControlMediaFormat;
			navCon.bookMediaFormat = _mediaFormat;
			
			if(opfLoaded)
			{	
				
				navCon.packageDocument = packageDoc;
				packageDoc = nil;
				currentPlugin = self;
			}
			
			if(ncxLoaded)
			{	
				navCon.controlDocument = controlDoc;
				controlDoc = nil;
				currentPlugin = self;
			}
			
			[navCon prepareForPlayback];
			
		}	
		
	}
	else
		if(navCon)
			[navCon resetController];


	// return YES if the Package document and/or Control Document loaded correctly
	return ((opfLoaded) || (ncxLoaded));
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

- (NSString *)FormatDescription
{
	return LocalizedStringInTBStdPluginBundle(@"This Book has been authored with the BookShare standard",@"BookShare Standard description");
}

- (BOOL)isVariant
{
	return YES;
}

- (void)setupPluginSpecifics
{
	validFileExtensions = [[NSArray alloc] initWithObjects:@"opf",@"ncx",nil];
}


- (NSURL *)loadedURL
{
	return [super loadedURL];
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

//- (void)jumpToControlPoint:(NSString *)aPoint andTime:(NSString *)aTime
//{
//	[super jumpToControlPoint:aPoint andTime:aTime];
//}


#pragma mark -
#pragma mark Navigation

#pragma mark -

- (void) dealloc
{
	[super dealloc];
}


@end
@implementation TBBooksharePlugin (Private)

- (BOOL)canOpenBook:(NSURL *)bookURL
{
	NSURL *fileURL = nil;
	// first check if we were passed a folder
	if ([fileUtils URLisDirectory:bookURL])
	{	// we were so first check for an OPF file 
		fileURL = [fileUtils fileURLFromFolder:[bookURL path] WithExtension:@"opf"];
		// check if we found the OPF file
		if (!fileURL)
			// check for the NCX file
			fileURL = [fileUtils fileURLFromFolder:[bookURL path] WithExtension:@"ncx"];
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
