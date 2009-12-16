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


#import "BBSAudioSegment.h"

NSString * const BBSAudioSegmentDidEndNotification = @"BBSAudioSegmentDidEndNotification";
NSString * const BBSAudioSegmentChapterDidChangeNotifiction = @"BBSAudioSegmentChapterDidChangeNotifiction";
NSString * const BBSAudioSegmentLoadStateDidChangeNotification = @"BBSAudioSegmentLoadStateDidChangeNotification";

@interface BBSAudioSegment () 

- (void)setupNotifications;
- (void)setupAttributes;

@end


@implementation BBSAudioSegment

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		_theMovie = nil;
		_extendedChapterData = [[NSArray alloc] init];
		noteCenter = [NSNotificationCenter defaultCenter];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_theMovie release];
	[_extendedChapterData release];
	
	[super dealloc];
}


- (id)initWithFile:(NSString *)aFilename 
{
	self = [self init];
	if (self != nil) 
	{
				
		_theMovie = [[QTMovie alloc] initWithFile:aFilename error:nil];
		//_theMovie = [[QTMovie movieWithFile:aFilename error:nil] retain];
		if (!_theMovie) 
			return nil;
		
		
		[self setupAttributes];
		[self setupNotifications];
	}
	
	return self;
}

- (BOOL)openWithFile:(NSString *)aFilename
{
	BOOL loadedOK = NO;
	if (_theMovie)
	{
		[noteCenter removeObserver:self];
		_theMovie = nil;
	}
	
	_theMovie = [[QTMovie alloc] initWithFile:aFilename error:nil];
	if (_theMovie) 
	{
		[self setupAttributes];
		[self setupNotifications];
		loadedOK = YES;
	}
	
		
	return loadedOK;
}

- (void)setupNotifications
{
	_loadNotificationPosted = NO;
	
	// watch for load state changes
	[noteCenter addObserver:self
				   selector:@selector(loadStateDidChange:)
					   name:QTMovieLoadStateDidChangeNotification
					 object:_theMovie];
	
	// watch for chapter change notifications 
	[noteCenter addObserver:self 
				   selector:@selector(updateForChapterChange:) 
					   name:QTMovieChapterDidChangeNotification 
					 object:_theMovie];
	
	// watch for end of audio file notifications
	[noteCenter addObserver:self 
				   selector:@selector(audioFileDidEnd:) 
					   name:QTMovieDidEndNotification 
					 object:_theMovie];
	
	// do a check if the movie has already completed loading
	if([[_theMovie attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete)
	{	
		[noteCenter postNotificationName:QTMovieLoadStateDidChangeNotification object:_theMovie];
		_loadNotificationPosted = YES;
	}

	
	
}

- (void)setupAttributes
{
	// make the file editable 
	[_theMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
	// set the preserves pitch option
	[_theMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieRateChangesPreservePitchAttribute];
	

}

- (QTTime)currentTime
{
	return (_theMovie) ? [_theMovie currentTime] : QTZeroTime;
}

- (void)setCurrentTime:(QTTime)aTime
{
	if(_theMovie)
		[_theMovie setCurrentTime:aTime];
}




@end



@implementation BBSAudioSegment (Playback)

- (void)play
{
	[_theMovie play];
}

- (void)stop
{
	[_theMovie stop];
}

- (void)nextChapter
{
	if([self hasNextChapter])
		[_theMovie setCurrentTime:[_theMovie startTimeOfChapter:([_theMovie chapterIndexForTime:[_theMovie currentTime]]+1)]];
}

- (void)previousChapter
{
	if ([self hasPreviousChapter])
		[_theMovie setCurrentTime:[_theMovie startTimeOfChapter:([_theMovie chapterIndexForTime:[_theMovie currentTime]]-1)]];
}

@end

@implementation BBSAudioSegment (Query)

- (BOOL)isPlaying
{
	return ((_theMovie) && ([_theMovie rate] != 0.0));
}

- (QTTime)duration
{
	return [_theMovie duration];
}

- (NSArray *)chapters
{
	return ([_theMovie chapterCount]) ? _extendedChapterData : nil;
}

- (BOOL)hasNextChapter
{
	return ([_theMovie chapterIndexForTime:[_theMovie currentTime]] < [_theMovie chapterCount]);
}

- (BOOL)hasPreviousChapter
{
	return ([_theMovie chapterIndexForTime:[_theMovie currentTime]] > 0);
}

- (NSInteger)currentChapterNumber
{
	return [_theMovie chapterIndexForTime:[_theMovie currentTime]];
}

- (NSString *)currentChapterName
{
	return [[_extendedChapterData objectAtIndex:[self currentChapterNumber]] valueForKey:QTMovieChapterName];
}

- (NSDictionary *)currentChapterDetails
{
	return [_extendedChapterData objectAtIndex:[self currentChapterNumber]];
}

- (QTTime)startTimeOfChapterWithTitle:(NSString *)aChapterTitle
{
	QTTime startTime;
	BOOL foundChapter = NO;
	if ([_theMovie hasChapters])
	{
		for(NSDictionary *aChapter in _extendedChapterData)
		{
			if ([[aChapter valueForKey:QTMovieChapterName] isEqualToString:aChapterTitle])
			{
				startTime = [[aChapter valueForKey:QTMovieChapterStartTime] QTTimeValue];
				foundChapter = YES;
				break;
			}
			
		}
		if (!foundChapter)
			startTime = [_theMovie startTimeOfChapter:0];
		
	}
	else 
		startTime = QTZeroTime;

	 
	
//	for(NSDictionary *chapInfo in _extendedChapterData)
//	{
//		if([[chapInfo valueForKey:QTMovieChapterName] isEqualToString:aChapterTitle])
//		{
//			startTime = [[chapInfo valueForKey:QTMovieChapterStartTime] QTTimeValue];
//			break;
//		}
//	}
//	
	return startTime;
}


@end

@implementation BBSAudioSegment (Utilities) 

- (BOOL)addChaptersOfDuration:(QTTime)aDuration 
{
	NSAssert(aDuration.timeValue != 0,@"Chapter Duration is Zero and should not be");
	NSMutableArray *tempChapts = [[NSMutableArray alloc] init];
	QTTime movieDur = [_theMovie duration];

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
	QTTrack *musicTrack = [[_theMovie tracksOfMediaType:QTMediaTypeSound] objectAtIndex:0];
	NSDictionary *musicTrackDict = [NSDictionary dictionaryWithObjectsAndKeys:musicTrack, QTMovieChapterTargetTrackAttribute,nil];

	if([tempChapts count] > 0) // check we have some chapters to add
	{
		// add the chapters track to the movie data
		[_theMovie addChapters:tempChapts withAttributes:musicTrackDict error:nil];
	}
	else
	{
		// there were no chapters added so add a first chapter 
		NSDictionary *thisChapter = [[[NSDictionary alloc] initWithObjectsAndKeys:[NSValue valueWithQTTime:(QTZeroTime)],QTMovieChapterStartTime,
									 @"1",QTMovieChapterName,
									 nil] autorelease];
		[tempChapts addObject:thisChapter];
		[_theMovie addChapters:tempChapts withAttributes:musicTrackDict error:nil];
	}
	
	return ([_theMovie hasChapters]);
	
}

- (BOOL)addChapters:(NSArray *)someChapters 
{
	BOOL didAddChapters = NO;
	
	if (_theMovie && [someChapters count])
	{
		
		// get the track the chapter will be associated with
		QTTrack *musicTrack = [[_theMovie tracksOfMediaType:QTMediaTypeSound] objectAtIndex:0];
		NSDictionary *musicTrackDict = [NSDictionary dictionaryWithObjectsAndKeys:musicTrack, QTMovieChapterTargetTrackAttribute,nil];
		
		_isAddingChapters  = YES;
		
		[_theMovie addChapters:someChapters withAttributes:musicTrackDict error:nil];
		didAddChapters = [_theMovie hasChapters];
		if(didAddChapters)
		{	
			_extendedChapterData = [someChapters copy];
			[_theMovie setCurrentTime:QTZeroTime];
			
		}
		else
			_extendedChapterData = nil;
	}
	
	return (didAddChapters);
	
}

- (void)setRate:(float)aRate
{
	if(_theMovie)
	{
		if ([self isPlaying])
			[_theMovie setRate:aRate];
		else
		{
			[_theMovie setAttribute:[NSNumber numberWithFloat:aRate] forKey:QTMoviePreferredRateAttribute];
		}
	}

}

- (void)setVolume:(float)aVolume
{
	if(_theMovie)
	{
		[_theMovie setAttribute:[NSNumber numberWithFloat:aVolume] forKey:QTMoviePreferredVolumeAttribute];
		[_theMovie setVolume:aVolume];
	}
}

@end

@implementation BBSAudioSegment (Notifications)

- (void)audioFileDidEnd:(NSNotification *)notification
{
	
	if([notification object] == _theMovie)
		[noteCenter postNotificationName:BBSAudioSegmentDidEndNotification object:self];		
	
}

- (void)loadStateDidChange:(NSNotification *)notification
{
	if([notification object] == _theMovie)
		if([[notification name] isEqualToString:QTMovieLoadStateDidChangeNotification])
			if([[_theMovie attributeForKey:QTMovieLoadStateAttribute] longValue] == QTMovieLoadStateComplete)
				if (!_loadNotificationPosted)
					if (!_isAddingChapters) 
					{
						_loadNotificationPosted = YES;
						[noteCenter postNotificationName:BBSAudioSegmentLoadStateDidChangeNotification object:self];
						
					}
					
				
			
}


- (void)updateForChapterChange:(NSNotification *)notification
{
	if(([notification object] == _theMovie))
	{
		if (!_isAddingChapters)
			[noteCenter postNotificationName:BBSAudioSegmentChapterDidChangeNotifiction object:self];
		else 
			_isAddingChapters = NO;

	}
}


@end

