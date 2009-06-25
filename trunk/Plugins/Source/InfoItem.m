//
//  TBInfoItem.m
//  TalkingBook Framework
//
//  Created by Kieren Eaton on 30/11/08.
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


#import "InfoItem.h"


@implementation InfoItem
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ = %@",title,content];
}

- (id) init
{
	if (!(self=[super init])) return nil;
	
	title = @"No Title";
	content = @"No Content";
	
	return self;
}

- (id)initWithTitle:(NSString *)aTitle andContent:(NSString *)aContent
{
	if (!(self=[self init])) return nil;

	if(![aTitle isEqualToString:@""])
		self.title = [aTitle copy];
	if(![aContent isEqualToString:@""])
		self.content = [aContent copy];
	
	return self;
}

- (BOOL)isEqual:(id)anObject
{
	BOOL isEqual = NO;
	
	if([anObject isKindOfClass:[self class]])
	{	
		if([[anObject title] isEqualToString:title])
			if([[anObject content] isEqualToString:content])
				isEqual = YES;
	}
	
	return isEqual;
}


@synthesize title,content;

@end

