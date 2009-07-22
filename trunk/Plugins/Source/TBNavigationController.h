//
//  TBNavigationController.h
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 11/06/09.
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

#import <Foundation/Foundation.h>
#import <QTKit/QTTime.h>
#import "TBTextContentDoc.h"
@class TBPackageDoc, TBControlDoc, TBSMILDocument, TBAudioSegment;
@class TBTextView;

@interface TBNavigationController : NSObject 
{
	TBBookData	*bookData;
	
	TBPackageDoc		*packageDocument;
	TBControlDoc		*controlDocument;
	TBTextContentDoc	*textDocument;
	TBSMILDocument		*smilDocument;
	
	NSString			*currentSmilFilename;
	NSString			*currentTextFilename;
	NSString			*currentTag;
	
	TBAudioSegment		*_audioFile;
	NSString			*_currentAudioFilename;
	BOOL				_justAddedChapters;
	BOOL				_didUserNavigation;
	BOOL				_shouldJumpToTime;
	QTTime				_timeToJumpTo;
	
	NSNotificationCenter *noteCentre;
}

- (id)initWithSharedData:(id)sharedDataClass;

// methods used for setting and getting the current position in the document
- (void)moveControlPoint:(NSString *)aNodePath withTime:(NSString *)aTime;
- (NSString *)currentNodePath;
- (NSString *)currentTime;


- (void)prepareForPlayback;
- (void)resetController;
- (void)nextElement;
- (void)previousElement;
- (void)goUpLevel;
- (void)goDownLevel;

@property (readwrite, retain)	TBPackageDoc		*packageDocument;
@property (readwrite, retain)	TBControlDoc		*controlDocument;
@property (readwrite, retain)	TBSMILDocument		*smilDocument;
@property (readwrite, retain)	TBTextContentDoc	*textDocument;
@property (readwrite, retain)	TBBookData			*bookData;
@property (readwrite, copy)		NSString			*currentTag;
@property (readwrite, copy)		NSString			*currentSmilFilename;
@property (readwrite, copy)		NSString			*currentTextFilename;
@property (readwrite, retain)	NSNotificationCenter *noteCentre;

@end
