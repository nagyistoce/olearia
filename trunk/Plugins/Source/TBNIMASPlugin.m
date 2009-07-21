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

- (void)setSharedBookData:(id)anInstance
{
	if(!bookData)
		[super setSharedBookData:anInstance];
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

- (void)reset
{
	[super reset];
}


- (NSView *)bookTextView;
{
	return [super bookTextView];
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
	NSURL *packageFileUrl = nil;
	
	// do a sanity check first to see that we can attempt to open the book. 
	if([self canOpenBook:bookURL])
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
			if(!packageDoc)
				self.packageDoc = [[TBOPFNimasDocument alloc] initWithSharedData:bookData];
			
			if([packageDoc openWithContentsOfURL:packageFileUrl])
			{
				// the opf file opened correctly
				// get the dc:Format node string
				NSString *bookFormatString = [[packageDoc stringForXquery:@"dc-metadata/data(*:Format)" ofNode:[packageDoc metadataNode]] uppercaseString];
				if(YES == [bookFormatString hasPrefix:@"NIMAS 1."])
				{
					// the opf file specifies that it is a NIMAS format book
					
					// set the folder path if required
					if(!bookData.folderPath)
						self.bookData.folderPath = [NSURL URLWithString:[[packageFileUrl path] stringByDeletingLastPathComponent]];
					
					// get the text content filename
					packageDoc.textContentFilename = [packageDoc stringForXquery:@"/package/manifest/item[@media-type='text/xml' ] [ends-with(@href,'.xml')] /data(@href)" ofNode:nil];
					
					[packageDoc processData];
					
					bookData.mediaFormat = TextOnlyNcxOrNccMediaFormat;
					
					opfLoaded = YES;
				}
				else 
					self.packageDoc = nil;
			}
			else
				self.packageDoc = nil;
		}
	}

	if(opfLoaded)
	{
		[super chooseCorrectNavControllerForBook];
		
		if(opfLoaded)
		{	
			self.navCon.packageDocument = packageDoc;
			self.packageDoc = nil;
		}
		
		[navCon moveControlPoint:nil withTime:nil];
		
		[navCon prepareForPlayback];
		
	}
	
	// return YES if the Package document and/or Control Document loaded correctly
	// as we can do limited control and playback functions from the opf file this is a valid scenario.
	return (opfLoaded);
	
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
	[super startPlayback];
}

- (void)stopPlayback
{
	[super stopPlayback];
}

- (NSString *)FormatDescription
{
	return NSLocalizedString(@"This Book has been authored with the NIMAS standard",@"NIMAS Standard description");
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
	
	validFileExtensions = [[NSArray alloc] initWithObjects:@"opf",nil];
	
}

- (void) dealloc
{
	
	[super dealloc];
}

@synthesize validFileExtensions;

@end
