//
//  NSXMLNode-TBAdditions.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 20/08/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import "NSXMLNode-TBAdditions.h"


@implementation NSXMLNode (TBAdditions)

- (NSString *)contentValue
{
	if(([self childCount] == 1) && ([[self nextNode] kind] == NSXMLTextKind)) 
		return [[self nextNode] stringValue];
	
	return [self stringValue];
}


@end
