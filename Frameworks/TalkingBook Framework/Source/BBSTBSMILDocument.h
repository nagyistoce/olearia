//
//  BBSTBSMILDocument.h
//  TalkingBook Framework
//
//  Created by Kieren Eaton on 15/04/08.
//  Copyright 2008 BrainBender Software. All rights reserved.
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

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@class BBSTBAudioSegment, BBSTBCommonDocClass;

@interface BBSTBSMILDocument : NSObject 
{
		
	
	NSURL			*_currentFilePath;
	
	//NSDictionary	*smilContent;
	//NSArray			*smilContent;
	//NSString		*xmlContentFilename;
	NSDictionary	*smilChapterData;
	//NSString		*filename;
	NSArray			*_parNodes;
	NSDictionary	*_parNodeIndexes;
	
	NSXMLDocument		*_xmlSmilDoc;
	BBSTBAudioSegment	*_currentAudioFile;
	BBSTBCommonDocClass *commonInstance;
	BOOL				_isPlaying;
	QTTime				skipDuration;
	
	
	
	// public ivars
	float			audioPlayRate; 
	float			audioVolume;
	QTTime			chapterSkipDuration;
	
	BOOL			includeSkippableContent; 
	BOOL			useSmilChapters;
	NSString		*currentTime;
}

- (BOOL)openWithContentsOfURL:(NSURL *)aURL;
//- (NSArray *)chapterMarkers;
- (NSArray *)chapterMarkersFromId:(NSString *)startId toId:(NSString *)endId;
- (NSString *)audioFilenameForId:(NSString *)anId;
- (void)playAudio;
- (void)pauseAudio;
//- (BOOL)hasNextChapter;
- (void)nextChapter;
//- (BOOL)hasPreviousChapter;
- (void)previousChapter;
- (void)setChapterSkipDuration:(QTTime)aDuration;

@property (readwrite)			float				audioPlayRate;
@property (readwrite)			float				audioVolume;
@property (readwrite)			QTTime				chapterSkipDuration;
@property (readwrite)			BOOL				includeSkippableContent;
@property (readwrite)			BOOL				useSmilChapters;
@property (readwrite, copy)		NSString			*currentTimeString;

@end
