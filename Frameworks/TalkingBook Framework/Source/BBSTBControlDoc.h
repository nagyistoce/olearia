//
//  BBSTBControlDoc.h
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


#import <Foundation/Foundation.h>
#import "BBSTalkingBookTypes.h"





@interface BBSTBControlDoc : NSObject 
{
	TalkingBookMediaFormat			bookFormat;
	NSInteger			currentLevel;
	
	NSInteger			totalPages;			// dtb:maxPageNumber or dtb:maxPageNormal in pre 2005 spec
	NSInteger			totalTargetPages;	// dtb:totalPageCount
	NSString			*documentUID;		// dtb:uid
	NSString			*segmentTitle;
	NSString			*bookTitle;

	id					controlDocument;
	
}

- (BOOL)openFileWithURL:(NSURL *)aURL;
//- (TalkingBookControlDocType)typeOfControlDoc:(NSURL *)aURL;

//- (BOOL)canGoNext;
//- (BOOL)canGoPrev;
//- (BOOL)canGoUpLevel;
//- (BOOL)canGoDownLevel;


//- (NSString *)goUpALevel;
//- (NSString *)goDownALevel;


@property (readonly) TalkingBookMediaFormat bookFormat;
@property (readonly, retain) NSString	*bookTitle;
@property (readonly) NSInteger currentLevel;
@property (readonly) NSInteger totalPages;
@property (readonly) NSInteger totalTargetPages;
@property (readonly, retain) NSString *documentUID;
@property (readonly, retain) NSString *segmentTitle;

@end
