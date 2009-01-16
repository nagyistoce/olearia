//
//  BBSTBAudioSegment.m
//  TalkingBook Framework
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


#import "BBSTBAudioSegment.h"
#import <QTKit/QTKit.h>
#import "BBSTBCommonDocClass.h"

@implementation BBSTBAudioSegment

- (id)initWithFile:(NSString *)fileName error:(NSError **)errorPtr
{
	
	
	
	//commonInstance = [BBSTBCommonDocClass sharedInstance];
	
	return [super initWithFile:fileName error:errorPtr];
}



#pragma mark -
#pragma mark ------- Public Methods ---------

- (void)addChaptersOfDuration:(QTTime)aDuration
{
	NSAssert(aDuration.timeValue != 0,@"Chapter Duration is Zero and should not be");
	NSMutableArray *tempChapts = [[NSMutableArray alloc] init];
	QTTime movieDur = [self duration];

	if(NSOrderedDescending == QTTimeCompare(movieDur, aDuration))
	{	
		
		QTTime chapterStart = QTZeroTime;
		NSInteger chIndex = 0;
		
		while(NSOrderedAscending == QTTimeCompare(chapterStart, movieDur))
		{
			NSMutableDictionary *thisChapter = [[NSMutableDictionary alloc] init];
			[thisChapter setObject:[NSValue valueWithQTTime:(chapterStart)] forKey:QTMovieChapterStartTime];
			[thisChapter setObject:[[NSNumber numberWithInt:chIndex] stringValue] forKey:QTMovieChapterName];
			[tempChapts addObject:thisChapter];
			chIndex++;
			chapterStart = QTTimeIncrement(chapterStart, aDuration);
		}
		
	}
	// get the track the chapter will be associated with
	QTTrack *musicTrack = [[self tracksOfMediaType:QTMediaTypeSound] objectAtIndex:0];
	NSDictionary *musicTrackDict = [NSDictionary dictionaryWithObjectsAndKeys:musicTrack, QTMovieChapterTargetTrackAttribute,nil];

	if([tempChapts count] > 0) // check we have some chapters to add
	{
		
		// add the chapters track to the movie data
		// dont worry about errors because it doesnt really matter if we cant get chapter markers
		[self addChapters:tempChapts withAttributes:musicTrackDict error:nil];
		
	}
	else
	{
		// there were no chapters added so add a first chapter 
		NSDictionary *thisChapter = [[NSDictionary alloc] initWithObjectsAndKeys:[NSValue valueWithQTTime:(QTZeroTime)],QTMovieChapterStartTime,
									 @"1",QTMovieChapterName,
									 nil];
		[tempChapts addObject:thisChapter];
		[self addChapters:tempChapts withAttributes:musicTrackDict error:nil];
	}
	
}

- (BOOL)nextChapterIsAvail
{
	return ([self chapterIndexForTime:[self currentTime]] < [self chapterCount]);
}

- (BOOL)prevChapterIsAvail
{
	return ([self chapterIndexForTime:[self currentTime]] > 0);
}

- (NSInteger)currentChapterNumber
{
	return [self chapterIndexForTime:[self currentTime]];
}
- (NSString *)currentChapterName
{
	return [[[self chapters] objectAtIndex:[self currentChapterNumber]] valueForKey:QTMovieChapterName]; 
}

- (void)updateForChapterPosition
{
	self.commonInstance.hasNextChapter = [self nextChapterIsAvail];
	self.commonInstance.hasPreviousChapter = [self prevChapterIsAvail];
}

- (void)jumpToNextChapter
{
	NSAssert(([self chapterIndexForTime:[self currentTime]]+1) < [self chapterCount],@"trying to go past max chapters");
	[self setCurrentTime:[self startTimeOfChapter:([self chapterIndexForTime:[self currentTime]]+1)]];
}



- (void)jumpToPrevChapter
{
	NSAssert(([self chapterIndexForTime:[self currentTime]]-1) < 0,@"trying to go before the first chapter");
	[self setCurrentTime:[self startTimeOfChapter:([self chapterIndexForTime:[self currentTime]]-1)]];
}



#pragma mark -
#pragma mark ===== Notification Methods =====





@synthesize commonInstance;

@end
