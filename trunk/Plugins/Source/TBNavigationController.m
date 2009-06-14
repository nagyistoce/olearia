//
//  TBNavigationController.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 11/06/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TBNavigationController.h"
#import "TBOPFDocument.h"
#import "TBNCXDocument.h"
#import "TBSMILDocument.h"
#import "TBAudioSegment.h"

@interface TBNavigationController () 

@property (readwrite, retain)	TBSMILDocument		*_smilDoc;
@property (readwrite, retain)	TBAudioSegment		*_audioFile;
@property (readwrite, retain)	TBSharedBookData	*_bookData;
@property (readwrite, copy)		NSString			*_currentTag;
@property (readwrite, copy)		NSString			*_currentSmilFilename;
@property (readwrite, copy)		NSString			*_currentAudioFilename;


-(void)checkMediaFormat;

@end

@implementation TBNavigationController

- (id) init
{
	if (!(self=[super init])) return nil;
	
	packageDocument = nil;
	controlDocument = nil;
	_smilDoc = nil;
	_audioFile = nil;
	_currentTag = nil;
	_bookData = [TBSharedBookData sharedInstance];
	
	return self;
}

- (void) dealloc
{
	self.packageDocument = nil;
	self.controlDocument = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Public Methods

- (void)moveToNodeWihPath:(NSString *)aNodePath
{
	// the control document will always be our first choice for navigation
	if(controlDocument)
		[controlDocument jumpToNodeWithId:aNodePath];
	else if(packageDocument)
	{
		// need to add navigation methods for package documents
	}

}

- (NSString *)currentNodePath
{
	if(controlDocument)
		return [controlDocument currentPositionID];
	
	return nil;
}

- (void)prepareForPlayback
{
	[self checkMediaFormat];
	
	if(controlDocument)
	{
		// check for audio media
		if(TextNcxOrNccMediaFormat != _bookData.mediaFormat)
		{
			NSString *filename = [controlDocument filenameFromCurrentNode];
			if([[filename pathExtension] isEqualToString:@"smil"])
			{
				_currentSmilFilename = [filename copy];
				// load the smil doc
			}
			//_audioFile = [[TBAudioSegment alloc] initWithFile:_currentAudioFilename error:nil];
			_currentTag = [[controlDocument currentReferenceTag] copy];	
		}
		
	}
	else if(packageDocument)
	{
		// setup for package navigation
	}
}

- (void)startPlayback
{
	self._bookData.isPlaying = YES;
	[_audioFile play];
}

- (void)stopPlayback
{
	self._bookData.isPlaying = NO;
	[_audioFile stop];
}


- (void)checkMediaFormat
{
	if(UnknownMediaFormat == _bookData.mediaFormat)
	{
		// create an alert for the user as we cant establish what the media the book contains
		NSAlert *mediaFormatAlert = [[NSAlert alloc] init];
		[mediaFormatAlert setAlertStyle:NSWarningAlertStyle];
		[mediaFormatAlert setMessageText:NSLocalizedString(@"Unknown Media Format", @"Unknown Media Format alert title")];
		[mediaFormatAlert setInformativeText:NSLocalizedString(@"This Book did not specify what type of media it contains.\n  It will be assumed it contains audio only content.", @"Unknown Media Format alert msg text")];
		[mediaFormatAlert runModal];
		_bookData.mediaFormat = AudioOnlyMediaFormat;
	}
}

#pragma mark -
#pragma mark Private Methods

@synthesize packageDocument, controlDocument;
@synthesize _audioFile, _smilDoc, _bookData;
@synthesize _currentSmilFilename, _currentAudioFilename, _currentTag;
			   

@end
