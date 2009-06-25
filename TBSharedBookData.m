//
//  TBSharedBookData.m
//  TalkingBook Framework
//
//  Created by Kieren Eaton on 9/12/08.
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

#import "TBSharedBookData.h"

NSString * const TalkingBookAudioSegmentDidChangeNotification = @"TalkingBookAudioSegmentDidChangeNotification";

static TBSharedBookData *sharedInstanceManager = nil;

@implementation TBSharedBookData

+ (TBSharedBookData *)sharedInstance
{
    @synchronized(self) 
	{
        if (sharedInstanceManager == nil) 
		{
            [[self alloc] init]; 
			
			// watch KVO notifications
			[self addObserver:self
						forKeyPath:@"playbackRate" 
						   options:NSKeyValueObservingOptionNew
						   context:NULL]; 
			
			[self addObserver:self
						forKeyPath:@"playbackVolume" 
						   options:NSKeyValueObservingOptionNew
						   context:NULL]; 
			
        }
    }
	
    return sharedInstanceManager;
	
}


- (id) init
{
	if (!sharedInstanceManager) 
	{
		sharedInstanceManager = [super init];
	}
	else
		[self dealloc];
	
    [self resetForNewBook];
	
    return sharedInstanceManager;
}

- (void)resetForNewBook
{
	// set the defaults for the newly loaded book before they are updated
	self.totalPages = 0;
	self.currentLevel = 1;
	self.currentPage = 0;
	self.bookTitle = nil;
	self.bookSubject = nil;
	self.levelString = nil;
	self.pageString = nil;
	self.sectionTitle = nil;
	self.bookTotalTime = nil;
	self.hasNextChapter = NO;
	self.hasPreviousChapter = NO;
	self.hasLevelUp = NO;
	self.hasLevelDown = NO;
	self.hasNextSegment = NO;
	self.hasPreviousSegment = NO;
	self.isPlaying = NO;
	self.settingsHaveChanged = NO;
	self.folderPath = nil;
	
	
}

#pragma mark -
#pragma mark ====== Accessors =====

- (void)setCurrentLevel:(NSInteger)aLevel
{
	currentLevel = aLevel;
	self.levelString = [NSString stringWithFormat:@"%d",aLevel];
}

- (void)setCurrentPage:(NSInteger)aPageNum
{
	currentPage = aPageNum;
	if(totalPages > 0)
		self.pageString = [NSString stringWithFormat:@"%d of %d",aPageNum,totalPages];
}

- (void)setTotalPages:(NSInteger)totalPageNum
{
	totalPages = totalPageNum;
	if(totalPageNum == 0)
		self.pageString = NSLocalizedString(@"No Page Numbers", @"no page numbers string");
}

- (void)setMediaFormatFromString:(NSString *)mediaTypeString
{
	if(nil != mediaTypeString)
	{
		NSString *typeStr = [mediaTypeString lowercaseString];
		// set the mediaformat accordingly
		if([typeStr isEqualToString:@"audiofulltext"])
			self.mediaFormat = AudioFullTextMediaFormat;
		else if([typeStr isEqualToString:@"audioparttext"])
			self.mediaFormat = AudioPartialTextMediaFormat;
		else if([typeStr isEqualToString:@"audioonly"])
			self.mediaFormat = AudioOnlyMediaFormat;
		else if(([typeStr isEqualToString:@"audioncc"])||([typeStr isEqualToString:@"audioncx"]))
			self.mediaFormat = AudioNcxOrNccMediaFormat;
		else if([typeStr isEqualToString:@"textpartaudio"])
			self.mediaFormat = TextPartialAudioMediaFormat;
		else if(([typeStr isEqualToString:@"textncc"])||([typeStr isEqualToString:@"textncx"]))
			self.mediaFormat = TextNcxOrNccMediaFormat;
		else 
			self.mediaFormat = UnknownMediaFormat;		
	}
	else
		self.mediaFormat = UnknownMediaFormat;

}
#pragma mark -
#pragma mark KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(([keyPath isEqualToString:@"playbackVolume"]) || ([keyPath isEqualToString:@"playbackRate"]))
		self.settingsHaveChanged = YES;
	else
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
}



// bindings related
@synthesize bookTitle, bookSubject, sectionTitle, bookTotalTime;
@synthesize mediaFormat;
@synthesize currentLevel, levelString;
@synthesize currentPage, totalPages, pageString;

@synthesize hasNextChapter, hasPreviousChapter;
@synthesize hasLevelUp, hasLevelDown;
@synthesize hasNextSegment, hasPreviousSegment;
@synthesize isPlaying, settingsHaveChanged;
@synthesize chapterSkipDuration;
@synthesize playbackRate, playbackVolume;
@synthesize  folderPath, includeSkippableContent;

@end