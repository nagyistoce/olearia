//
//  TBBookData.m
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

#import "TBBookData.h"

static TBBookData *sharedTBBookData = nil;

@implementation TBBookData

+ (TBBookData *)sharedBookData
{
    @synchronized(self)
	{
		if(sharedTBBookData == nil) 
		{
			sharedTBBookData = [[self alloc] init]; 
		}
	}
	return sharedTBBookData;
}


- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		[self resetForNewBook];
	}
	return self;
}

- (void) dealloc
{
	
	bookTitle = nil;
	bookSubject = nil;
	sectionTitle = nil;
	levelString = nil;
	pageString = nil;
	bookTotalTime = nil;
	folderPath = nil;
	
	[super dealloc];
}


+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedTBBookData == nil) {
            sharedTBBookData = [super allocWithZone:zone];
            return sharedTBBookData;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (unsigned)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}


- (void)resetForNewBook
{
	// set the defaults for the newly loaded book before they are updated
	self.totalPages = 0;
	self.currentPage = 0;
	self.currentLevel = 1;
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
	self.mediaFormat = UnknownMediaFormat;
	
	
}

#pragma mark -
#pragma mark ====== Modified Accessors =====

- (void)setCurrentLevel:(NSInteger)aLevel
{
	currentLevel = aLevel;
	self.levelString = [NSString stringWithFormat:@"%d",aLevel];
}

- (void)setCurrentPage:(NSInteger)aPageNum
{
	currentPage = aPageNum;
	if(totalPages > 0)
		self.pageString = [NSString stringWithFormat:@"%d of %d",currentPage,totalPages];
	else
		self.pageString = [NSString stringWithFormat:@"%d",currentPage];

		
}

- (void)setTotalPages:(NSInteger)totalPageNum
{
	totalPages = totalPageNum;
	if(totalPages != 0)
		self.pageString = [NSString stringWithFormat:@"%d of %d",currentPage,totalPages];
	else
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
			self.mediaFormat = TextOnlyNcxOrNccMediaFormat;
		else 
			self.mediaFormat = UnknownMediaFormat;		
	}
	else
		self.mediaFormat = UnknownMediaFormat;

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
@synthesize  folderPath;

@synthesize preferredVoice, voicePlaybackRate, voiceVolume;
@synthesize overrideRecordedContent, speakUserLevelChange, includeSkippableContent;
@synthesize chapterSkipDuration;
@synthesize playbackRate, playbackVolume;

@end
