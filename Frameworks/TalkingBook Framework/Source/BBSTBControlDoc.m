//
//  BBSTBControlDoc.m
//  BBSTalkingBook
//
//  Created by Kieren Eaton on 14/08/08.
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




#import "BBSTBControlDoc.h"
#import "BBSTBNCXDocument.h"

@implementation BBSTBControlDoc

- (id) init
{
	if (!(self=[super init])) return nil;
	
	segmentTitle = @"";
	bookTitle = @"";
	totalPages = 0;
	totalTargetPages = 0;
	currentLevel = 0;
	documentUID = @"";
	bookMediaFormat = unknownMediaFormat;
	
	
	return self;
}

- (void)finalize
{
	documentUID = nil;
	segmentTitle = nil;
	bookTitle = nil;
	
	[super finalize];
}

@synthesize levelNavChapterIncrement;
@synthesize currentLevel, totalPages, totalTargetPages;
@synthesize bookMediaFormat;
@synthesize segmentTitle, bookTitle, documentUID;


@end
