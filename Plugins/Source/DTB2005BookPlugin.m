//
//  DTB2005BookPlugin.m
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


#import "DTB2005BookPlugin.h"
#import "TBOPFDocument.h"
#import "TBNCXDocument.h"
#import "TBNavigationController.h"

@interface DTB2005BookPlugin()

@end

@interface DTB2005BookPlugin (Private)

- (BOOL)canOpenBook:(NSURL *)bookURL;

@end



@implementation DTB2005BookPlugin

+ (DTB2005BookPlugin *)bookType
{
	DTB2005BookPlugin *instance = [[[self alloc] init] autorelease];
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
	BOOL opfLoaded = NO;
	BOOL ncxLoaded = NO;
	BOOL navConDidLoad = NO;
	NSURL *controlFileURL = nil;
	NSURL *packageFileUrl = nil;
	TalkingBookMediaFormat mediaFormat = UnknownMediaFormat;
	TBControlDoc *controlDoc = nil;
	TBPackageDoc *packageDoc = nil;
	
	// do a sanity check first to see that we can attempt to open the book. 
	if([self canOpenBook:bookURL])
	{
		
		// first check if we were passed a folder
		if ([fileUtils URLisDirectory:bookURL])
		{	
			bookData.baseFolderPath = [bookURL copy];
			// passed a folder so first check for an OPF file 
			packageFileUrl = [fileUtils fileURLFromFolder:[bookURL path] WithExtension:@"opf"];
			// check if we found the OPF file
			if (!packageFileUrl)
				// no opf file found so check for the NCX file
				controlFileURL = [fileUtils fileURLFromFolder:[bookURL path] WithExtension:@"ncx"];
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
			if(!packageDoc)
				packageDoc = [[[TBOPFDocument alloc] init] autorelease];
			
			if([packageDoc openWithContentsOfURL:packageFileUrl])
			{
				// the opf file opened correctly
				// get the dc:Format node string
				NSString *bookFormatString = [[packageDoc stringForXquery:@"/package/metadata/dc-metadata/data(*:Format)" ofNode:[packageDoc metadataNode]] uppercaseString];
				if(YES == [bookFormatString hasSuffix:@"Z39.86-2005"])
				{
					// the opf file specifies that it is a 2005 format book
					if(!bookData.baseFolderPath)
						bookData.baseFolderPath = [[NSURL alloc] initFileURLWithPath:[[packageFileUrl path] stringByDeletingLastPathComponent] isDirectory:YES];
					
					// get the ncx filename
					packageDoc.ncxFilename = [packageDoc stringForXquery:@"/package/manifest/item[@media-type='application/x-dtbncx+xml']/data(@href)" ofNode:nil];
					if(packageDoc.ncxFilename)
						controlFileURL = [NSURL fileURLWithPath:[[[bookData baseFolderPath] path] stringByAppendingPathComponent:[packageDoc ncxFilename]]] ;
					
					// get the text content filename
					packageDoc.textContentFilename = [packageDoc stringForXquery:@"/package/manifest/item[@media-type='application/x-dtbook+xml']/data(@href)" ofNode:nil];
					
					[packageDoc processData];
					
					opfLoaded = YES;
				}
				
			}
			else
			{
				// opening the opf failed for some reason so try to open just the control file
				controlFileURL = [fileUtils fileURLFromFolder:[[packageFileUrl path] stringByDeletingLastPathComponent] WithExtension:@"ncx"];
			}
		}
				
		if (controlFileURL)
		{
			if(!controlDoc)
				controlDoc = [[[TBNCXDocument alloc] init] autorelease];
			
			// attempt to load the ncx file
			if([controlDoc openWithContentsOfURL:controlFileURL])
			{
				// check if the folder path has already been set
				if (!bookData.baseFolderPath)
					bookData.baseFolderPath = [[NSURL alloc] initFileURLWithPath:[[controlFileURL path] stringByDeletingLastPathComponent] isDirectory:YES];
				
				[controlDoc processData];

				ncxLoaded = YES;
			}

		}	
		
		if(ncxLoaded || opfLoaded)
		{
			if (opfLoaded) 
				mediaFormat = [self mediaFormatFromString:[packageDoc mediaFormatString]];
			navConDidLoad = [self loadCorrectNavControllerForBookFormat:mediaFormat];
			
			if (navConDidLoad)
			{
				self.navCon.bookMediaFormat = mediaFormat;
				
				if(opfLoaded)
				{	
					self.navCon.packageDocument = packageDoc;
					self.currentPlugin = self;
				}
				if(ncxLoaded)
				{	
					self.navCon.controlDocument = controlDoc;
					self.currentPlugin = self;
				}
				
				[navCon prepareForPlayback];
				
			}
		}
	}
	else
		if(navCon)
			[navCon resetController];
	
	
	// return YES if the Package document and/or Control Document loaded correctly
	// The Control document gives us full navigation.
	// limited control from the (opf) package file.
	return ((ncxLoaded || opfLoaded) && navConDidLoad);
}

- (NSURL *)loadedURL
{
	if(self.navCon.packageDocument)
		return [[navCon packageDocument] fileURL];
	else if(navCon.controlDocument)
		return [[navCon controlDocument] fileURL];
	
	return nil;
}

- (NSString *)FormatDescription
{
	return LocalizedStringInTBStdPluginBundle(@"This Book has been authored with the Daisy 2005 standard",@"Daisy 2005 Standard description");
}

#pragma mark -

- (void)setupPluginSpecifics
{
	validFileExtensions = [[NSArray alloc] initWithObjects:@"opf",@"ncx",nil];
}

#pragma mark -
#pragma mark subclass Methods

- (NSXMLNode *)infoMetadataNode
{
	if(navCon.packageDocument)
		return [[navCon packageDocument] metadataNode];
	if(navCon.controlDocument)
		return [[navCon controlDocument] metadataNode];
	
	return nil;
}


@end

@implementation DTB2005BookPlugin (Private)

// this method checks the url for a file with a valid extension
// if a directory URL is passed in the entire folder is scanned 
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

