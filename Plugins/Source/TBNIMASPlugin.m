//
//  TBNIMASPlugin.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 20/05/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import "TBNIMASPlugin.h"


@implementation TBNIMASPlugin

- (void)setupPluginSpecifics
{

	
}

+ (TBNIMASPlugin *)bookType
{
	TBNIMASPlugin *instance = [[[self alloc] init] autorelease];
	if (instance)
	{	
		[instance setupPluginSpecifics];
		return instance;
	}

	return nil;
}

- (id)variantOfType
{
	// return the super classes id 
	return [self superclass];
}

- (id)textPlugin
{
	
}

- (id)smilPlugin
{
	// Text Only Book so no need for a SMIL plugin
	return nil;
}
#pragma mark -

- (void) dealloc
{
	
	[super dealloc];
}

@end
