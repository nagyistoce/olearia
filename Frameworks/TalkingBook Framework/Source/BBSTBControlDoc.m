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

@interface BBSTBControlDoc()

//- (NSUInteger)navPointsOnCurrentLevel;
//- (NSUInteger)navPointIndexOnCurrentLevel;
//- (TalkingBookControlDocType)typeOfControlDoc:(NSURL *)aURL;

@end


@implementation BBSTBControlDoc

/*
- (BOOL)openFileWithURL:(NSURL *)aURL
{
	BOOL fileOK = NO;
	
	TalkingBookControlDocType docType = [self typeOfControlDoc:aURL];

	if(ncxControlDocType == docType)
	{
		controlDocument = [[BBSTBNCXDocument alloc] initWithURL:aURL];
		  
	}
	else if(nccControlDocType == docType)
	{
		// open the ncc file here
	}
	
	if( nil != controlDocument)
	{	
		fileOK = YES;
		// bind the values for easy updating when changed in the subclass
	
	}
	
	return fileOK;
	
}
*/

#pragma mark -
#pragma mark Dynamic Methods

- (TalkingBookMediaFormat)bookFormat
{
	return [controlDocument bookFormat];
}

- (NSString	*)bookTitle
{
	return [controlDocument bookTitle];
}

- (NSInteger)currentLevel
{
	return [controlDocument currentLevel];
}

- (NSInteger)totalPages
{
	return [controlDocument totalPages];
}

- (NSInteger)totalTargetPages
{
	return [controlDocument totalTargetPages];
}

- (NSString *)documentUID
{
	return [controlDocument documentUID];
}

- (NSString *)segmentTitle
{
	return [controlDocument segmentTitle];
}
@end
