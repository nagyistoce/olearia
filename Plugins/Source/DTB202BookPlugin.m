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

@interface DTB202BookPlugin()

@property (readwrite, retain)	NSArray *validFileExtensions;

- (BOOL)canOpenBook:(NSURL *)bookURL;

@end

@implementation DTB202BookPlugin

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
	navCon = nil;
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

- (BOOL)openBook:(NSURL *)bookURL
{
	
	BOOL nccLoaded = NO;
	NSURL *controlFileURL = nil;

	// do a sanity check first to see that we can attempt to open the URL. 
	if([self canOpenBook:bookURL])
	{
		// first check if we were passed a folder
		if ([fileUtils URLisDirectory:bookURL])
		{	
			//self.bookData.folderPath = bookURL;
			NSArray *htmlFiles = [fileUtils fileURLsFromFolder:[bookURL path] WithExtension:@"html"];
			if([htmlFiles count])
			{
				for(NSURL *fileURL in htmlFiles)
				{
					if([[[[fileURL path] lastPathComponent] lowercaseString] isEqualToString:@"ncc.html"])
					{	
						controlFileURL = [fileURL copy];
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
				controlFileURL = [[bookURL copy] autorelease];
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
			if(!navCon)
				self.navCon = [[TBNavigationController alloc] init];
			
			// attempt to load the ncc.html file
			self.navCon.controlDocument = [[TBNCCDocument alloc] init];
			if([[navCon controlDocument] openWithContentsOfURL:controlFileURL])
			{
				// check if the folder path has already been set
				if (!bookData.folderPath)
					self.bookData.folderPath = [NSURL fileURLWithPath:[[controlFileURL path] stringByDeletingLastPathComponent]];
				// the control file opened correctly
				// get the dc:Format node string
				NSString *bookFormatString = [[[navCon controlDocument] stringForXquery:@"/html/head/meta[ends-with(@name,'format')] /data(@content)" ofNode:nil] uppercaseString];
				if(YES == [bookFormatString isEqualToString:@"DAISY 2.02"])
				{
					[[navCon controlDocument] processData];
					nccLoaded = YES;
				}
				else 
					self.navCon.controlDocument = nil;
				
			}
			else 
				self.navCon.controlDocument = nil;
			
			
		}
	}
	
	// return YES if the Package document and/or Control Document loaded correctly
	// as we can do limited control and playback functions from the opf file this is a valid scenario.
	return ((controlFileURL && nccLoaded));
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

- (NSXMLNode *)infoMetadataNode
{
	if(self.navCon.controlDocument)
		return [[navCon controlDocument] metadataNode];

	return nil;
}

- (NSURL *)loadedURL
{
	if(self.navCon.controlDocument)
		return [[navCon controlDocument] fileURL];
	
	return nil;
}
- (void)moveToControlPosition:(NSString *)aNodePath
{
		
}

- (NSString *)currentControlPosition
{
	//placeholder
	return nil;
}

- (void)startPlayback
{
	
}

- (void)stopPlayback
{
	
}
- (NSString *)FormatDescription
{
	return NSLocalizedString(@"This Book has been authored with the Daisy 2.02 standard",@"Daisy 2.02 Standard description");
}

#pragma mark -

- (void) dealloc
{
	[super dealloc];
}

#pragma mark -
#pragma mark Private Methods

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



@synthesize validFileExtensions;

@end

