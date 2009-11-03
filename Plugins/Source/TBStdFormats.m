//
//  TBStdFormats.m
//  stdDaisyFormats
//
//  Created by Kieren Eaton on 13/04/09.
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

#import "TBStdFormats.h"
#import "DTB202BookPlugin.h"
#import "DTB2002BookPlugin.h"
#import "DTB2005BookPlugin.h"
#import "TBBooksharePlugin.h"
#import "TBNIMASPlugin.h"
#import "TBNavigationController.h"
#import "TBTextOnlyNavigationController.h"
#import "TBPackageDoc.h"
#import "TBControlDoc.h"



@interface TBStdFormats (Private)

//+ (NSMutableArray *)insertPlugin:(TBStdFormats *)aPlugin intoArray:(NSArray *)anArray;
- (TalkingBookMediaFormat)checkMediaFormat;

@end


@implementation TBStdFormats

+ (NSArray *)plugins 
{
	NSMutableArray* plugs = [[[NSMutableArray alloc] init] autorelease];
	
	//plugs = [self insertPlugin:[TBNIMASPlugin bookType] intoArray:plugs];
	[plugs addObject:[TBBooksharePlugin bookType]];
	[plugs addObject:[DTB202BookPlugin bookType]];
	[plugs addObject:[DTB2002BookPlugin bookType]];
	[plugs addObject:[DTB2005BookPlugin bookType]];
	
	return [plugs count] ? plugs : nil;
}

+ (id)bookType
{
	// subclasses will return an instance of themselves via this method
#ifdef DEBUG 	
	NSLog(@"Super Class %@ used instead of subclass",[self className]);
#endif
	return nil;	
}


- (BOOL)isVariant
{
	// plugins that are variants of standard types will return their superclass here 
	// for the concrete subclasses they will use this superclass method
	return NO;
}

- (NSView *)bookTextView;
{
	BOOL foundTextFile = NO;
	NSString *errorTextFilename = @"NoTextContent.html";
		
	// check if we should load the view nib
	if(!textview)
		if (![NSBundle loadNibNamed:@"TextView" owner:self])
			return nil;
		
	if((_mediaFormat != AudioWithControlMediaFormat) && (_mediaFormat != AudioOnlyMediaFormat))
	{	
		if(navCon.packageDocument.textContentFilename)
		{	
			//NSURL *textFileURL = [NSURL fileURLWithPath:[[[bookData folderPath] path] stringByAppendingPathComponent:navCon.packageDocument.textContentFilename]];
			NSURL *textFileURL = [NSURL URLWithString:navCon.packageDocument.textContentFilename relativeToURL:[bookData baseFolderPath]];
			
			foundTextFile = YES;
			[textview setURL:textFileURL];
			
			
		}
		else
			errorTextFilename = @"ErrorLoadingTextContent.html";
			
	}
		
	if(!foundTextFile)
	{
		// no text file found or it an audio only book
		// so set a message in the view for the user.
		NSString *localizedPath = [[NSBundle bundleForClass:[self class]] pathForResource:errorTextFilename ofType:nil];
		NSURL *errorTextURL = [NSURL fileURLWithPath:localizedPath];
		
		[textview  setURL:errorTextURL];
	}
			
	
	return textview;
}

- (NSView *)bookInfoView;
{
	// check if we should load the view nib
	if(!infoView)
		if (![NSBundle loadNibNamed:@"InformationView" owner:self]) 
			return nil;
	
	if([currentPlugin respondsToSelector:@selector(infoMetadataNode)])
		[infoView updateInfoFromPlugin:currentPlugin];
	
	
	return infoView;
}

- (NSString *)FormatDescription
{
	return LocalizedStringInTBStdPluginBundle(@"No Book Format Description",@"No Book Format Description");
}

- (BOOL)canOpenBook:(NSURL *)bookURL;
{
#ifdef DEBUG	
	NSLog(@"Super Class method %@ in Class %@ used instead of subclass method",@selector(_cmd),[self className]);
#endif
	return NO;
}

- (void)reset
{
	if(navCon)
		[navCon resetController];
	packageDoc = nil;
	controlDoc = nil;
}

- (BOOL)openBook:(NSURL *)bookURL
{
#ifdef DEBUG
	NSLog(@"Super Class method %@ in Class %@ used instead of subclass method",@selector(_cmd),[self className]);
#endif
	return NO;
}

- (NSXMLNode *)infoMetadataNode
{
#ifdef DEBUG
	NSLog(@"Super Class method infoMetadataNode in Class %@ used instead of subclass method",[self className]);
#endif
	return nil;
}

- (BOOL)processMetadata
{
#ifdef DEBUG	
	NSLog(@"Super Class method processMetadata in Class %@ used instead of subclass method",[self className]);
#endif
	return NO;
}

- (void)startPlayback
{	
	[navCon startPlayback];
}

- (void)stopPlayback
{	
	[navCon stopPlayback];
}

- (NSURL *)loadedURL
{
#ifdef DEBUG	
	NSLog(@"Super Class method loadedURL in Class %@ used instead of subclass method",[self className]);
#endif
	return nil;
}

- (NSString *)currentPlaybackTime
{
	if(navCon)
		return [navCon currentTime];
	
	return nil;
}

- (NSString *)currentControlPoint
{
	if(navCon)
		return [navCon currentNodePath];

	return nil;
}

- (void)jumpToControlPoint:(NSString *)aPoint andTime:(NSString *)aTime
{
	if(navCon)
		[navCon moveControlPoint:aPoint withTime:aTime];
		
	
}

- (BOOL)loadCorrectNavControllerForBookFormat
{
	BOOL loadedOK = NO;
	_mediaFormat = [self checkMediaFormat];
	
	// check if a navigation controller has been loaded before
	if(navCon)
	{
		if(([navCon isKindOfClass:[TBNavigationController class]]) && (_mediaFormat == TextWithControlMediaFormat))
		{
			navCon = nil;
		}
		else if(([navCon isKindOfClass:[TBTextOnlyNavigationController class]]) && (_mediaFormat != TextWithControlMediaFormat))
		{	
			navCon = nil;
		}
	}
	if (UnknownMediaFormat != _mediaFormat) 
	{
		if(!navCon)
		{
			switch (_mediaFormat)
			{
				case TextWithControlMediaFormat:
					navCon = [[TBTextOnlyNavigationController alloc] init];
					loadedOK = YES;
					break;
				case UnknownMediaFormat:
					navCon = nil;
					break;
				default:
					// check if the user wants to use the synthesized voice and its Full Text, Full Audio
					if ((![bookData ignoreRecordedAudioContent]) && (FullAudioFullTextMediaFormat == _mediaFormat)) 
					{
						navCon = [[TBNavigationController alloc] init];
					}
					else 
					{
						navCon = [[TBTextOnlyNavigationController alloc] init];
					}

					loadedOK = YES;
					break;
			}
		}
		else
			loadedOK = YES;
		
	}
	else
		[bookData resetData];
	
	return loadedOK;
}

- (TalkingBookMediaFormat)mediaFormatFromString:(NSString *)mediaTypeString
{
	TalkingBookMediaFormat format = UnknownMediaFormat;
	
	if(nil != mediaTypeString)
	{
		// make sure the string is lowercase for proper evaluation
		NSString *typeStr = [mediaTypeString lowercaseString];
		
		// set the mediaformat accordingly
		if([typeStr isEqualToString:@"audiofulltext"])
			format = FullAudioFullTextMediaFormat;
		else if([typeStr isEqualToString:@"audioparttext"])
			format = FullAudioPartialTextMediaFormat;
		else if([typeStr isEqualToString:@"audioonly"])
			format = AudioOnlyMediaFormat;
		else if(([typeStr isEqualToString:@"audioncc"])||([typeStr isEqualToString:@"audioncx"]))
			format = AudioWithControlMediaFormat;
		else if([typeStr isEqualToString:@"textpartaudio"])
			format = FullTextPartialAudioMediaFormat;
		else if(([typeStr isEqualToString:@"textncc"])||([typeStr isEqualToString:@"textncx"]))
			format = TextWithControlMediaFormat;
		else 
			format = UnknownMediaFormat;		
	}
	else
		format = UnknownMediaFormat;
	
	return format;
	
}



#pragma mark -
#pragma mark Navigation

- (void)nextReadingElement
{
	[navCon nextElement];
}
- (void)previousReadingElement
{
	[navCon previousElement];
}

- (void)upLevel
{
	[navCon goUpLevel];
}

- (void)downLevel
{
	[navCon goDownLevel];
}

- (void)setupPluginSpecifics
{ /* Dummy Method Placeholder */}



- (id) init
{
	if(!(self = [super init])) return nil;
	
	bookData = [TBBookData sharedBookData];
	fileUtils = [[TBFileUtils alloc] init];
	currentPlugin = nil;
	
	return self;
}


- (void) dealloc
{
	[fileUtils release];
	[validFileExtensions release];
	[controlDoc release];
	[packageDoc release];
	[navCon	release];
	
	[super dealloc];
}

@synthesize currentPlugin;
@synthesize validFileExtensions;
@synthesize navCon, packageDoc, controlDoc;
@synthesize bookData;

@end

@implementation TBStdFormats (Private)


//+ (NSMutableArray *)insertPlugin:(TBStdFormats *)aPlugin intoArray:(NSArray *)anArray
//{
//	NSMutableArray *currentTypes = [NSMutableArray arrayWithArray:anArray];
//	// check if the type is a variant of another type (possibly Standard Type)
//	if([aPlugin isVariant])
//		[currentTypes insertObject:aPlugin atIndex:0];
//	else
//		[currentTypes addObject:aPlugin];
//
//	return currentTypes;
//}

- (TalkingBookMediaFormat)checkMediaFormat
{
	NSInteger resultCode;
	TalkingBookMediaFormat format = _mediaFormat;
	
	if(UnknownMediaFormat == format)
	{
		// create an alert for the user as we cant establish what the media the book contains
		NSAlert *mediaFormatAlert = [[[NSAlert alloc] init] autorelease];
		[mediaFormatAlert setAlertStyle:NSWarningAlertStyle];
		[mediaFormatAlert setIcon:[NSApp applicationIconImage]];
		[mediaFormatAlert setMessageText:LocalizedStringInTBStdPluginBundle(@"Unknown Media Format", @"Unknown Media Format alert title")];
		[mediaFormatAlert setInformativeText:LocalizedStringInTBStdPluginBundle(@"This Book did not specify what type of media it contains.\nPlease choose the type of media for this book.\n\nNOTE: Choosing the incorrect type may cause unexpected playback problems, if in doubt choose Cancel and the book will not be loaded.", @"Unknown Media Format alert msg text")];
		[mediaFormatAlert addButtonWithTitle:LocalizedStringInTBStdPluginBundle(@"Audio Only",@"Audio Only Button")];
		[mediaFormatAlert addButtonWithTitle:LocalizedStringInTBStdPluginBundle(@"Text Only",@"Text Only Button")];
		[mediaFormatAlert addButtonWithTitle:LocalizedStringInTBStdPluginBundle(@"Cancel",@"Cancel Button")];
		resultCode = [mediaFormatAlert runModal];
	
		switch (resultCode)
		{
		case NSAlertFirstButtonReturn:
			format = AudioOnlyMediaFormat;
			break;
		case NSAlertSecondButtonReturn:
			format = TextWithControlMediaFormat;	
			break;
		default:
			format = UnknownMediaFormat;
			break;
		}

	}
	return format;
}


@end

