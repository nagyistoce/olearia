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

NSString * const PreferredSynthesizerVoice = @"preferredVoiceIdentifier";
NSString * const AudioPlaybackRate = @"audioPlaybackRate";
NSString * const AudioPlaybackVolume = @"audioPlaybackVolume";

static TBBookData *sharedBookDataManager = nil;

@implementation TBBookData

+ (TBBookData *)sharedBookData
{
    @synchronized(self)
	{
		if(sharedBookDataManager == nil) 
		{
			sharedBookDataManager = [[self alloc] init]; 
		}
	}
	return sharedBookDataManager;
}


- (id) init
{
	Class myClass = [self class];
    @synchronized(myClass) 
	{
        if (sharedBookDataManager == nil) 
		{
            if ((self = [super init])) 
			{
                sharedBookDataManager = self;
				self.bookTitle = [[NSString alloc] init];
				self.bookSubject = [[NSString alloc] init];
				self.sectionTitle = [[NSString alloc] init];
				self.totalPlaybackTimeString = [[NSString alloc] init];
				self.currentPlaybackTimeString = [[NSString alloc] init];
				self.currentPageString = [[NSString alloc] init];
				self.currentLevelString = [[NSString alloc] init];
				self.preferredVoiceIdentifier = [[NSString alloc] init];
            }
        }
    }
	[self resetData];
    return sharedBookDataManager;
}


+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) 
	{
        if (sharedBookDataManager == nil) 
		{
            sharedBookDataManager = [super allocWithZone:zone];
        }
    }
	return sharedBookDataManager;
}

- (id)copyWithZone:(NSZone *)zone { return self; }

- (id)retain{ return self; }

- (NSUInteger)retainCount{ return UINT_MAX; }

- (void)release{}

- (id)autorelease{ return self; }


- (void)resetData
{
	// set the defaults for the newly loaded book before they are updated
	self.totalPages = 0;
	self.currentPageNumber = 0;
	self.currentLevel = 1;
	self.bookTitle = LocalizedStringInTBFrameworkBundle(@"No Title", @"no title string");
	self.bookSubject = LocalizedStringInTBFrameworkBundle(@"No Subject", @"no subject string");
	self.sectionTitle = @"";
	self.totalPlaybackTime = QTZeroTime;
	self.currentPlaybackTime = QTZeroTime;
	self.hasNextChapter = NO;
	self.hasPreviousChapter = NO;
	self.hasLevelUp = NO;
	self.hasLevelDown = NO;
	self.hasNextSegment = NO;
	self.hasPreviousSegment = NO;
	self.isPlaying = NO;
	self.localBookSettingsHaveChanged = NO;
	self.baseFolderPath = nil;
	self.voicePlaybackVolume = (float)1.0;
		
}

#pragma mark -
#pragma mark ====== Modified Accessors =====

- (void)setCurrentLevel:(NSInteger)aLevel
{
	currentLevel = aLevel;
	self.currentLevelString = [NSString stringWithFormat:@"%d",self.currentLevel];
}

- (void)setCurrentPageNumber:(NSInteger)aPageNum
{
	currentPageNumber = aPageNum;
	if(self.totalPages > 0)
		self.currentPageString = [NSString stringWithFormat:LocalizedStringInTBFrameworkBundle(@"%d of %d",@"current Page of total pages"),self.currentPageNumber,self.totalPages];
	else
		self.currentPageString = [NSString stringWithFormat:@"%d",self.currentPageNumber];

}

- (void)setTotalPages:(NSInteger)totalPageNum
{
	totalPages = totalPageNum;
	if(self.totalPages > 0)
		self.currentPageString = [NSString stringWithFormat:LocalizedStringInTBFrameworkBundle(@"%d of %d",@"current Page of total pages"),self.currentPageNumber,self.totalPages];
	else
		self.currentPageString = LocalizedStringInTBFrameworkBundle(@"No Page Numbers", @"no page numbers string");
}

@synthesize localBookSettingsHaveChanged;
@synthesize baseFolderPath;

// bindings
@synthesize bookTitle, bookSubject;
@synthesize sectionTitle, currentLevel, currentLevelString;
@synthesize currentPageNumber, currentPageString;
@synthesize totalPages;
@synthesize hasNextChapter, hasPreviousChapter;
@synthesize hasLevelUp, hasLevelDown;
@synthesize hasNextSegment, hasPreviousSegment;
@synthesize isPlaying;
@synthesize totalPlaybackTimeString, currentPlaybackTimeString;
@synthesize totalPlaybackTime, currentPlaybackTime;


// user settings
@synthesize preferredVoiceIdentifier;
@synthesize ignoreRecordedAudioContent;
@synthesize speakUserLevelChange;
@synthesize includeSkippableContent;
@synthesize audioSkipDuration;
@synthesize audioPlaybackRate, audioPlaybackVolume;
@synthesize voicePlaybackVolume;

@end
