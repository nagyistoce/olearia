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


#import "TBAudioSegment.h"

@interface TBAudioSegment ()

@property (readwrite, retain)   NSArray	*_extendedChapterData;
@property (readwrite)			BOOL isPlaying;

@end


@implementation TBAudioSegment

- (id)initWithFile:(NSString *)fileName error:(NSError **)errorPtr
{
	self = [super initWithFile:fileName error:errorPtr];
	if (nil == self) return nil;
	
	_extendedChapterData = [[NSArray alloc] init];
	
	return self;
}

- (void)play
{
	self.isPlaying = YES;
	[super play];
}

- (void)stop
{
	self.isPlaying = NO;
	[super stop];
}

- (void)setAttribute:(id)value forKey:(NSString *)attributeKey
{
	if ([attributeKey isEqualToString:QTMoviePreferredRateAttribute])
	{
		// this is a workaround for the issue that play will start
		// after the attribute is set even if the movie is not playing
		[super setAttribute:value forKey:QTMoviePreferredRateAttribute];
		if (!isPlaying) 
			[self stop];
	}
	else 
		[super setAttribute:value forKey:attributeKey];

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
			NSDictionary *thisChapter =[[[NSDictionary alloc] initWithObjectsAndKeys:
										 [NSValue valueWithQTTime:(chapterStart)],QTMovieChapterStartTime,
										 [[NSNumber numberWithInteger:chIndex] stringValue],QTMovieChapterName,
										 nil] autorelease];
			
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
		[self addChapters:tempChapts withAttributes:musicTrackDict error:nil];
	}
	else
	{
		// there were no chapters added so add a first chapter 
		NSDictionary *thisChapter = [[[NSDictionary alloc] initWithObjectsAndKeys:[NSValue valueWithQTTime:(QTZeroTime)],QTMovieChapterStartTime,
									 @"1",QTMovieChapterName,
									 nil] autorelease];
		[tempChapts addObject:thisChapter];
		[self addChapters:tempChapts withAttributes:musicTrackDict error:nil];
	}
	
}

- (void)addChapters:(NSArray *)chapters withAttributes:(NSDictionary *)attributes error:(NSError **)errorPtr
{
	
	[super addChapters:chapters withAttributes:attributes error:(NSError **)errorPtr];
	if(([self hasChapters]))
	{	
		_extendedChapterData = [chapters copy];
		[self setCurrentTime:QTZeroTime];
	}
	else
		_extendedChapterData = nil;
}

- (NSArray *)chapters
{
	return ([self chapterCount]) ? _extendedChapterData : nil;
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
	return [[_extendedChapterData objectAtIndex:[self currentChapterNumber]] valueForKey:QTMovieChapterName];
}

- (NSDictionary *)currentChapterInfo
{
	return [_extendedChapterData objectAtIndex:[self currentChapterNumber]];
}

- (QTTime)startTimeOfChapterWithTitle:(NSString *)aChapterTitle
{
	QTTime startTime = [self startTimeOfChapter:0];
	
	for(NSDictionary *chapInfo in _extendedChapterData)
	{
		if([[chapInfo valueForKey:QTMovieChapterName] isEqualToString:aChapterTitle])
		{
			startTime = [[chapInfo valueForKey:QTMovieChapterStartTime] QTTimeValue];
			break;
		}
	}
	
	return startTime;
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


@synthesize _extendedChapterData, isPlaying;

@end
