//
//  BBSTalkingBook.h
//  BBSTalkingBook
//
//  Created by Kieren Eaton on 5/05/08.
//  BrainBender Software. 
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

#import <Cocoa/Cocoa.h>
#import "BBSTalkingBookTypes.h"

@class BBSTBOPFDocument, BBSTBNCXDocument, BBSTBSMILDocument, BBSTBTextDocument;
@class QTMovie;

extern NSString * const BBSTBCanGoNextFileNotification;
extern NSString * const BBSTBCanGoPrevFileNotification;
extern NSString * const BBSTBCanGoUpLevelNotification;
extern NSString * const BBSTBCanGoDownLevelNotification;
extern NSString * const BBSTBhasNextChapterNotification;
extern NSString * const BBSTBhasPrevChapterNotification;


@interface BBSTalkingBook : NSObject 
{

	
	
	NSString				*bookTitle;
	NSString				*sectionTitle;
	NSInteger				maxLevels;
	NSInteger				totalChapters;
	NSInteger				currentLevelIndex;
	NSInteger				currentPageIndex;
	NSInteger				currentChapterIndex;
	float					currentPlaybackRate;
	float					currentPlaybackVolume;
	
	
	BBSTBOPFDocument		*opfDoc;
	BBSTBNCXDocument		*ncxDoc;
	BBSTBTextDocument		*textDoc;
	BBSTBSMILDocument		*smilDoc;
	
	
	NSString				*bookPath;
	NSString				*segmentFilename;
	
	
	NSNotificationCenter	*TalkingBookNotificationCenter;


	BOOL					didLoadOK;
	BOOL					hasOPFFile;
	BOOL					hasNCXFile;
	BOOL					isPlaying;
	BOOL					isFastForwarding;
	BOOL					isFastRewinding;

	QTMovie					*currentAudioFile;
}

@property (readonly,retain)	NSString	*bookTitle;
@property (readonly,retain) NSString	*sectionTitle;

@property (readonly)		NSInteger	maxLevels;
@property (readonly)		NSInteger	currentLevelIndex;
@property (readonly)		NSInteger	currentPageIndex;

@property (retain,readwrite)	BBSTBOPFDocument		*opfDoc;
@property (retain,readwrite)	BBSTBNCXDocument		*ncxDoc;
@property (retain,readonly)		BBSTBTextDocument		*textDoc;


- (id)initWithFile:(NSURL *)aURL;
- (void)playAudio;
- (void)pauseAudio;

- (BOOL)nextSegmentOnLevel;
- (BOOL)nextSegment;
- (BOOL)previousSegment;

- (BOOL)hasNextFile;
- (BOOL)hasPrevFile;
- (BOOL)hasChapters;

- (void)upOneLevel;
- (void)downOneLevel;
- (NSInteger)currentLevelIndex;

- (void)sendNotificationsForPosInBook;

- (void)nextChapter;
- (void)previousChapter;

- (NSDictionary *)getBookInfo;
- (void)gotoPage;
- (NSDictionary *)getCurrentPageInfo;

- (void)setNewVolumeLevel:(float)aLevel;
- (void)setNewPlaybackRate:(float)aRate;



@end
