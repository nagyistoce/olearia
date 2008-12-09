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

@interface BBSTBAudioSegment ()



@end


@implementation BBSTBAudioSegment

- (id) init
{
	if (!(self=[super init])) return nil;
	
	_totalChapters = 0;
	
	return self;
}
- (void) dealloc
{
	
	
	[super dealloc];
}


#pragma mark -
#pragma mark ------- Public Methods ---------

- (void)addChaptersOfDuration:(QTTime)aDuration
{
	
	NSMutableArray *tempChapts = [[NSMutableArray alloc] init];
	QTTime movieDur = [self duration];
	// check that the actual audio duration is longer than the chapter duration
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
	if([tempChapts count] > 0) // check we have some chapters to add
	{
		// get the track the chapter will be associated with
		QTTrack *musicTrack = [[self tracksOfMediaType:QTMediaTypeSound] objectAtIndex:0];
		
		NSDictionary *trackDict = [NSDictionary dictionaryWithObjectsAndKeys:musicTrack, QTMovieChapterTargetTrackAttribute,nil];
		// add the chapters track to the movie data
		// dont worry about errors because it doesnt really matter if we cant get chapter markers

		[self addChapters:tempChapts withAttributes:trackDict error:nil];
		
	}

	_totalChapters = [self chapterCount];

}

- (BOOL)nextChapterIsAvail
{
	return ([self chapterIndexForTime:[self currentTime]] < _totalChapters) ? YES : NO;
}
- (BOOL)prevChapterIsAvail
{
	return ([self chapterIndexForTime:[self currentTime]] > 0) ? YES : NO;
}

- (void)jumpToNextChapter
{
	NSAssert(([self chapterIndexForTime:[self currentTime]]+1) < _totalChapters,@"trying to go past max chapters");
	[self setCurrentTime:[self startTimeOfChapter:([self chapterIndexForTime:[self currentTime]]+1)]];
}

- (void)jumpToPrevChapter
{
	NSAssert(([self chapterIndexForTime:[self currentTime]]+1) < _totalChapters,@"trying to go before the first chapter");
	[self setCurrentTime:[self startTimeOfChapter:([self chapterIndexForTime:[self currentTime]]-1)]];
}

#pragma mark -
#pragma mark ========= Notification Methods




@end
