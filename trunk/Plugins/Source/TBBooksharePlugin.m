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
#import "TBNavigationController.h"

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
	
	// do a sanity check first to see that we can attempt to open the book. 
	if([self canOpenBook:bookURL])
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
						
						self.packageDoc = nil;
					}
				}
			}
		}
		
		if(packageFileUrl)
		{
			if(!packageDoc)
				self.packageDoc = [[TBOPFDocument alloc] initWithSharedData:bookData];
			
			if([packageDoc openWithContentsOfURL:packageFileUrl])
			{
				// the opf file opened correctly
				// get the dc:Format node string
				NSString *bookFormatString = [[packageDoc stringForXquery:@"dc-metadata/data(*:Format)" ofNode:[[navCon packageDocument] metadataNode]] uppercaseString];
				
				if(YES == [bookFormatString isEqualToString:@"ANSI/NISO Z39.86-2002"]) 
				{	
					NSString *schemeStr = [packageDoc stringForXquery:@"/package/metadata/dc-metadata/*:Identifier[@scheme='BKSH']/data(.)" ofNode:nil];
					if((schemeStr) && (YES == [[schemeStr lowercaseString] hasPrefix:@"bookshare"]))
					{
						// the opf file specifies that it is a 2002 format book and it has the bookshare scheme tag
						self.bookData.folderPath = [[NSURL alloc] initFileURLWithPath:[[packageFileUrl path] stringByDeletingLastPathComponent] isDirectory:YES];
						
						// get the ncx filename
						self.packageDoc.ncxFilename = [packageDoc stringForXquery:@"/package/manifest/item[@media-type='text/xml' ] [ends-with(@href,'.ncx')] /data(@href)" ofNode:nil];
	
						// get the text content filename
						self.packageDoc.textContentFilename = [packageDoc stringForXquery:@"/package/manifest/item[@media-type=\"application/x-dtbook+xml\"]/data(@href)" ofNode:nil];

						[packageDoc processData];
						
						bookData.mediaFormat = TextOnlyNcxOrNccMediaFormat;
						
						controlFileURL = [NSURL URLWithString:self.navCon.packageDocument.ncxFilename relativeToURL:bookData.folderPath];  
						
						opfLoaded = YES;
					}
					else 
						self.packageDoc = nil;
				}
				else 
					self.packageDoc = nil;
			}
			else 
				self.packageDoc = nil;
		}
		
		if (controlFileURL)
		{
			if(!controlDoc)
				self.controlDoc = [[TBNCXDocument alloc] initWithSharedData:bookData];
			
			// check if the folder path has already been set
			if (!bookData.folderPath)
				self.bookData.folderPath = [NSURL URLWithString:[[controlFileURL path] stringByDeletingLastPathComponent]];
			// attempt to load the ncx file
			
			bookData.mediaFormat = TextOnlyNcxOrNccMediaFormat;
			
		}
	}

	if(ncxLoaded || opfLoaded)
	{
		[super chooseCorrectNavControllerForBook];
		
		if(opfLoaded)
		{	
			self.navCon.packageDocument = packageDoc;
			self.packageDoc = nil;
			self.currentPlugin = self;
		}
		if(ncxLoaded)
		{	
			self.navCon.controlDocument = controlDoc;
			self.controlDoc = nil;
			self.currentPlugin = self;
		}
		
		[navCon moveControlPoint:nil withTime:nil];
		
		[navCon prepareForPlayback];
		
	}	
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
	return NSLocalizedString(@"This Book has been authored with the BookShare standard",@"BookShare Standard description");
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
