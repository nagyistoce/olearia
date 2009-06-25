//
//  DTB2002BookPlugin.m
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


#import "DTB2002BookPlugin.h"
#import "TBOPFDocument.h"
#import "TBNCXDocument.h"
#import "TBNavigationController.h"

@interface DTB2002BookPlugin ()

- (BOOL)canOpenBook:(NSURL *)bookURL;

@end


@implementation DTB2002BookPlugin

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

- (void)setupPluginSpecifics
{
	validFileExtensions = [[NSArray  alloc] initWithObjects:@"opf",@"ncx",nil];
	navCon = nil;
}

+ (DTB2002BookPlugin *)bookType
{
	DTB2002BookPlugin *instance = [[[self alloc] init] autorelease];
	if (instance)
	{	
		[instance setupPluginSpecifics];
		return instance;
	}
	
	return nil;
}

- (NSView *)textView;
{
	return [super textView];
}

- (NSView *)bookInfoView;
{
	return [super bookInfoView];
}

- (void)updateInfoFromPlugin:(TBStdFormats *)aPlugin
{
	[super updateInfoFromPlugin:aPlugin];
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
			packageFileUrl = [fileUtils fileURLFromFolder:[bookData.folderPath path]  WithExtension:@"opf"];
			// check if we found the OPF file
			if (!packageFileUrl)
				// no opf file found so check for the NCX file
				controlFileURL = [fileUtils fileURLFromFolder:[bookData.folderPath path] WithExtension:@"ncx"];
		}
		else
		{
			// valid file url passed in
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
				}
			}
		}
		
		if(packageFileUrl)
		{
			if(!navCon)
				self.navCon = [[TBNavigationController alloc] init];
			
			if(!navCon.packageDocument)
				self.navCon.packageDocument = [[TBOPFDocument alloc] init];
			if([[navCon packageDocument] openWithContentsOfURL:packageFileUrl])
			{
				// the opf file opened correctly
				// get the dc:Format node string
				NSString *bookFormatString = [[[navCon packageDocument] stringForXquery:@"dc-metadata/data(*:Format)" ofNode:[[navCon packageDocument] metadataNode]] uppercaseString];
				if(YES == [bookFormatString isEqualToString:@"ANSI/NISO Z39.86-2002"])
				{
					// the opf file specifies that it is a 2002 format book
					if(!bookData.folderPath)
						self.bookData.folderPath = [NSURL fileURLWithPath:[[packageFileUrl path] stringByDeletingLastPathComponent] isDirectory:YES];
					
					// get the ncx filename
					self.navCon.packageDocument.ncxFilename = [[navCon packageDocument] stringForXquery:@"/package/manifest/item[@media-type='text/xml' ] [ends-with(@href,'.ncx')] /data(@href)" ofNode:nil];
					if(navCon.packageDocument.ncxFilename)
						controlFileURL = [NSURL fileURLWithPath:[[[bookData folderPath] path] stringByAppendingPathComponent:navCon.packageDocument.ncxFilename]];
					
					// get the text content filename
					self.navCon.packageDocument.textContentFilename = [[navCon packageDocument] stringForXquery:@"/package/manifest/item[@media-type='text/xml' ] [ends-with(@href,'.xml')] /data(@href)" ofNode:nil];
					// add loading of text document class here
					
					[[navCon packageDocument] processData];
										
					opfLoaded = YES;
				}
				else 
					self.navCon.packageDocument = nil;
				
			}
			else 
			{	
				self.navCon.packageDocument = nil;
				// opening the opf failed for some reason so try to open just the control file
				controlFileURL = [fileUtils fileURLFromFolder:[[packageFileUrl path] stringByDeletingLastPathComponent] WithExtension:@"ncx"];
			}
		}
		
		if (controlFileURL)
		{
			if(!navCon)
				self.navCon = [[TBNavigationController alloc] init];
			
			if(!navCon.controlDocument)
				self.navCon.controlDocument = [[TBNCXDocument alloc] init];
			// attempt to load the ncx file
			if([[navCon controlDocument] openWithContentsOfURL:controlFileURL])
			{
				// check if the folder path has already been set
				if (!bookData.folderPath)
					self.bookData.folderPath = [[NSURL alloc] initFileURLWithPath:[[controlFileURL path] stringByDeletingLastPathComponent] isDirectory:YES];
				
				[[navCon controlDocument] processData];
				
				[self moveToControlPosition:@""];
				
				ncxLoaded = YES;
			}
			else
				self.navCon.controlDocument = nil;
			
		}
	}
	
	// return YES if the Package document and/or Control Document loaded correctly
	// as we can do limited control and playback functions from the opf file this is a valid scenario.
	return ((packageFileUrl && opfLoaded) || (controlFileURL && ncxLoaded));
}

- (NSURL *)loadedURL
{
	if(navCon.packageDocument)
		return self.navCon.packageDocument.fileURL;
	if(navCon.controlDocument)
		return navCon.controlDocument.fileURL;
	
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
	return NSLocalizedString(@"This Book has been authored with the Daisy 2002 standard",@"Daisy 2002 Standard description");
}

- (NSXMLNode *)infoMetadataNode
{
	if(navCon.packageDocument)
		return [[navCon packageDocument] metadataNode];
	if(navCon.controlDocument)
		return [[navCon controlDocument] metadataNode];
	
	return nil;
}

- (void)moveToControlPosition:(NSString *)aNodePath
{
	
}

- (NSString *)currentControlPosition
{
	// placeholder
	return nil;
}

#pragma mark -


- (void) dealloc
{
	
	[super dealloc];
}

#pragma mark -
#pragma mark Private Methods

// this method checks the url for a file with a valid extension
// if a directory URL is passed the directory is scanned for a file with a valid extension
- (BOOL)canOpenBook:(NSURL *)bookURL;
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

