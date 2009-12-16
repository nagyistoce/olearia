//
//  BBSAudioSegment.h
//
//  Created by Kieren Eaton on 6/12/08.
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

extern NSString * const BBSAudioSegmentDidEndNotification;
extern NSString * const BBSAudioSegmentChapterDidChangeNotifiction;
extern NSString * const BBSAudioSegmentLoadStateDidChangeNotification;

#import <QTKit/QTKit.h>


// make time comparisons easier to understand  
enum {
	BBSTimeIsShorter = -1,
	BBSTimesAreEqual,
	BBSTimeIsLonger
};
typedef NSInteger BBSTimeComparisonResult;

@interface BBSAudioSegment : NSObject 
{
	
@private 
	NSArray					*_extendedChapterData;
	QTMovie					*_theMovie;
	BOOL					_isAddingChapters;
	BOOL					_loadNotificationPosted;
	NSNotificationCenter	*noteCenter;	
	
}

- (id)initWithFile:(NSString *)fileName;
- (BOOL)openWithFile:(NSString *)aFilename;

@property (readwrite)	QTTime			currentTime;

@end

@interface BBSAudioSegment (Query)

- (BOOL)hasNextChapter;
- (BOOL)hasPreviousChapter;
- (BOOL)isPlaying;
- (NSString *)currentChapterName;
- (NSInteger)currentChapterNumber;
- (NSDictionary *)currentChapterDetails;
- (QTTime)startTimeOfChapterWithTitle:(NSString *)aChapterTitle;
- (NSArray *)chapters;
- (QTTime)duration;

@end

@interface  BBSAudioSegment (Playback)

- (void)nextChapter;
- (void)previousChapter;
- (void)play;
- (void)stop;

@end

@interface BBSAudioSegment (Utilities) 

- (BOOL)addChaptersOfDuration:(QTTime)aDuration;
- (BOOL)addChapters:(NSArray *)someChapters;
- (void)setRate:(float)rate;
- (void)setVolume:(float)volume;


@end










