//
//  DTB2005BookPlugin.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 20/05/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import "DTB2005BookPlugin.h"

@interface DTB2005BookPlugin()

@property (readwrite, retain)	NSArray *validFileExtensions;

@end


@implementation DTB2005BookPlugin

- (void)setupPluginSpecifics
{
	validFileExtensions = [NSArray arrayWithObjects:@"opf",@"ncx",nil];

}

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

- (id)textPlugin
{
	return nil;
}

- (id)smilPlugin
{
	return nil;
}

// this method checks the url for a file with a valid extension
// if a directory URL is passed the 
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
			packageFileUrl = [fileUtils fileURLFromFolder:[bookURL path] WithExtension:@"opf"];
			// check if we found the OPF file
			if (!packageFileUrl)
				// no opf file found so check for the NCX file
				controlFileURL = [fileUtils fileURLFromFolder:[bookURL path] WithExtension:@"ncx"];
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
				if(YES == [bookFormatString isEqualToString:@"ANSI/NISO Z39.86-2005"])
				{
					// the opf file specifies that it is a 2005 format book
					
					self.bookData.folderPath = [NSURL URLWithString:[[packageFileUrl path] stringByDeletingLastPathComponent]];
					
					// get the ncx filename
					self.packageDocument.ncxFilename = [packageDocument stringForXquery:@"/package/manifest/item[@media-type=\"application/x-dtbncx+xml\"]/data(@href)" ofNode:nil];
					// get the text content filename
					self.packageDocument.textContentFilename = [packageDocument stringForXquery:@"/package/manifest/item[@media-type=\"application/x-dtbook+xml\"]/data(@href)" ofNode:nil];
					[packageDocument processData];
					controlFileURL = [NSURL URLWithString:[packageDocument ncxFilename] relativeToURL:bookData.folderPath];  
					
					opfLoaded = YES;
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
			// check if the folder path has already been set
			if (!bookData.folderPath)
				self.bookData.folderPath = [NSURL URLWithString:[[controlFileURL path] stringByDeletingLastPathComponent]];
			// attempt to load the ncx file
			
		}
	}
	
	// return YES if the Package document and/or Control Document loaded correctly
	// as we can do limited control and playback functions from the opf file this is a valid scenario.
	return ((packageFileUrl && opfLoaded) || (controlFileURL && ncxLoaded));
}

- (NSURL *)loadedURL
{
	if(packageDocument)
		return [NSURL URLWithString:[packageDocument ncxFilename] relativeToURL:bookData.folderPath];
	if(controlDocument)
		return [controlDocument fileURL];
	
	return nil;
}

- (NSXMLNode *)infoMetadataNode
{
	if(packageDocument)
		return [packageDocument metadataNode];
	if(controlDocument)
		return [controlDocument metadataNode];
	
	return nil;
}

#pragma mark -

- (void) dealloc
{	
	[super dealloc];
}

@synthesize validFileExtensions;

@end
