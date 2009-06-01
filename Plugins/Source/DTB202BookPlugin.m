//
//  DTB202BookPlugin.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 20/05/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import "DTB202BookPlugin.h"

@implementation DTB202BookPlugin

- (void)setupPluginSpecifics
{
	
}

+ (DTB202BookPlugin *)bookType
{
	DTB202BookPlugin *instance = [[[self alloc] init] autorelease];
	if (instance)
	{	
		[instance setupPluginSpecifics];
		return instance;
	}
	
	return nil;
}

- (BOOL)openBook:(NSURL *)bookURL
{
	
	
	
	return NO;
}

- (id)textPlugin
{
	
	return nil;
}

- (id)smilPlugin
{
	
	return nil;
}


- (void) dealloc
{
	[super dealloc];
}



@end

