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
	self.currentPageNumber = 0;
	self.sectionTitle = @"";
	self.bookTotalTime = @"";
	self.hasNextChapter = NO;
	self.hasPreviousChapter = NO;
	self.hasLevelUp = NO;
	self.hasLevelDown = NO;
	self.hasNextSegment = NO;
	self.hasPreviousSegment = NO;
	self.isPlaying = NO;
	self.localBookSettingsHaveChanged = NO;
	self.baseFolderPath = nil;
	//self.mediaFormat = UnknownMediaFormat;
	self.voicePlaybackVolume = (float)1.0;
		
}

#pragma mark -
#pragma mark ====== Modified Accessors =====

- (void)setCurrentLevel:(NSInteger)aLevel
{
	m_currentLevel = aLevel;
	self.currentLevelString = [NSString stringWithFormat:@"%d",self.currentLevel];
}

- (void)setCurrentPageNumber:(NSInteger)aPageNum
{
	m_currentPageNumber = aPageNum;
	if(self.totalPages > 0)
		self.currentPageString = [NSString stringWithFormat:LocalizedStringInTBFrameworkBundle(@"%d of %d",@"current Page of total pages"),self.currentPageNumber,self.totalPages];
	else
		self.currentPageString = [NSString stringWithFormat:@"%d",self.currentPageNumber];

}

- (void)setTotalPages:(NSInteger)totalPageNum
{
	m_totalPages = totalPageNum;
	if(self.totalPages > 0)
		self.currentPageString = [NSString stringWithFormat:LocalizedStringInTBFrameworkBundle(@"%d of %d",@"current Page of total pages"),self.currentPageNumber,self.totalPages];
	else
		self.currentPageString = LocalizedStringInTBFrameworkBundle(@"No Page Numbers", @"no page numbers string");
}

//- (void)setMediaFormatFromString:(NSString *)mediaTypeString
//{
//	if(nil != mediaTypeString)
//	{
//		// make sure the string is lowercase for proper evaluation
//		NSString *typeStr = [mediaTypeString lowercaseString];
//		
//		// set the mediaformat accordingly
//		if([typeStr isEqualToString:@"audiofulltext"])
//			self.mediaFormat = AudioFullTextMediaFormat;
//		else if([typeStr isEqualToString:@"audioparttext"])
//			self.mediaFormat = AudioPartialTextMediaFormat;
//		else if([typeStr isEqualToString:@"audioonly"])
//			self.mediaFormat = AudioOnlyMediaFormat;
//		else if(([typeStr isEqualToString:@"audioncc"])||([typeStr isEqualToString:@"audioncx"]))
//			self.mediaFormat = AudioNcxOrNccMediaFormat;
//		else if([typeStr isEqualToString:@"textpartaudio"])
//			self.mediaFormat = TextPartialAudioMediaFormat;
//		else if(([typeStr isEqualToString:@"textncc"])||([typeStr isEqualToString:@"textncx"]))
//			self.mediaFormat = TextOnlyNcxOrNccMediaFormat;
//		else 
//			self.mediaFormat = UnknownMediaFormat;		
//	}
//	else
//		self.mediaFormat = UnknownMediaFormat;
//
//}

// bindings related
@synthesize bookTitle = m_bookTitle, bookSubject = m_bookSubject;
@synthesize sectionTitle = m_sectionTitle, bookTotalTime = m_bookTotalTime;
//@synthesize mediaFormat = m_mediaFormat;
@synthesize currentLevel = m_currentLevel, currentLevelString = m_currentLevelString;
@synthesize currentPageNumber = m_currentPageNumber, currentPageString = m_currentPageString;
@synthesize totalPages = m_totalPages;
@synthesize hasNextChapter = m_hasNextChapter, hasPreviousChapter = m_hasPreviousChapter;
@synthesize hasLevelUp = m_hasLevelUp, hasLevelDown = m_hasLevelDown;
@synthesize hasNextSegment = m_hasNextSegment, hasPreviousSegment = m_hasPreviousSegment;
@synthesize isPlaying = m_isPlaying;
@synthesize localBookSettingsHaveChanged = m_localBookSettingsHaveChanged;
@synthesize baseFolderPath = m_baseFolderPath;

@synthesize preferredVoiceIdentifier = m_preferredVoiceIdentifier;
@synthesize ignoreRecordedAudioContent = m_ignoreRecordedAudioContent;
@synthesize speakUserLevelChange = m_speakUserLevelChange;
@synthesize includeSkippableContent = m_includeSkippableContent;
@synthesize audioSkipDuration = m_audioSkipDuration;
@synthesize audioPlaybackRate = m_audioPlaybackRate, audioPlaybackVolume = m_audioPlaybackVolume;
@synthesize voicePlaybackVolume = m_voicePlaybackVolume;

@end
