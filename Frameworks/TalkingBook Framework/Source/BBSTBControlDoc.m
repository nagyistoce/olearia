//
//  BBSTBControlDoc.m
//  BBSTalkingBook
//
//  Created by Kieren Eaton on 14/08/08.
//  2008 BrainBender Software.
//
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

@interface BBSTBControlDoc()

- (NSUInteger)navPointsOnCurrentLevel;
- (NSUInteger)navPointIndexOnCurrentLevel;

@end


@implementation BBSTBControlDoc

@synthesize bookFormat, currentLevel, totalPages, totalTargetPages;
@synthesize bookTitle, segmentTitle, documentUID;

- (BOOL)canGoNext
{
	// return YES if we can go forward in the navmap
	return ([self navPointIndexOnCurrentLevel] < ([self navPointsOnCurrentLevel] - 1)) ? YES : NO; 
}

- (BOOL)canGoPrev
{
	// return YES if we can go backwards in the navMap
	return ([self navPointIndexOnCurrentLevel] > 0) ? YES : NO;
}

- (BOOL)canGoUpLevel
{
	// return Yes if we are at a lower level
	return (currentLevel > 1) ? YES : NO;
}

- (BOOL)canGoDownLevel
{
	// return YES if there are navPoint Nodes below this level
	return ([[currentNavPoint nodesForXPath:@"navPoint" error:nil] count] > 0) ? YES : NO;
}

- (NSUInteger)navPointsOnCurrentLevel
{
	return [[[currentNavPoint parent] nodesForXPath:@"navPoint" error:nil] count]; 
}

- (NSUInteger)navPointIndexOnCurrentLevel
{
	// returns an index of the current navPoint relative to the other navPoints on the same level
	return [[[currentNavPoint parent] nodesForXPath:@"navPoint" error:nil] indexOfObject:currentNavPoint];
}
/*
- (NSString *)goUpALevel
{
	
}
- (NSString *)goDownALevel
{
	
}
*/
@end
