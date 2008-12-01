//
//  InfoItem.m
//  Olearia
//
//  Created by Kieren Eaton on 30/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BBSTBInfoItem.h"


@implementation BBSTBInfoItem
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

	title = aTitle ;
	content = aContent;
	
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

