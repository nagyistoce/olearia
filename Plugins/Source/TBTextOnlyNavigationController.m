//
//  TBTextOnlyNavigationController.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 3/07/09.
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
#import "TBTextOnlyNavigationController.h"
#import "TBOPFDocument.h"
#import "TBNCXDocument.h"
#import "TBSMILDocument.h"

@implementation TBTextOnlyNavigationController

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		
	}
	
	return self;
}

- (void) dealloc
{
	
	[super dealloc];
}

- (void)prepareForPlayback
{
	[self resetController];
	
	
//	if(controlDocument)
//	{
//		
//		NSString *filename = [controlDocument contentFilenameFromCurrentNode];
//		if([[filename pathExtension] isEqualToString:@"smil"])
//		{
//			if(!_smilDoc)
//				_smilDoc = [[TBSMILDocument alloc] init];
//			
//			// check if the smil file REALLY needs to be loaded
//			// Failsafe for single smil books 
//			if(![_currentSmilFilename isEqualToString:filename])
//			{
//				_currentSmilFilename = [filename copy];
//				[_smilDoc openWithContentsOfURL:[NSURL URLWithString:_currentSmilFilename relativeToURL:bookData.folderPath]];
//			}
//			_currentAudioFilename = _smilDoc.relativeAudioFilePath;
//		}
//		else
//		{
//			// no smil filename
//			
//		}
//		
//		if(_currentAudioFilename) 
//			if([self updateAudioFile:_currentAudioFilename])
//				_currentTag = [controlDocument currentIdTag];			
//	}
//	else if(packageDocument)
//	{
//		// setup for package navigation
//	}
}


@end
