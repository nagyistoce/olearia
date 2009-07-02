//
//  TBTextView.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 28/06/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import "TBStdTextView.h"
//#import <WebKit/WebKit.h>

@implementation TBStdTextView

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) 
	{
		
    }
    return self;
}

- (void)setURL:(NSURL *)theURL
{
	if(![theURL isEqualTo:[theWebView mainFrameURL]])
		[theWebView setMainFrameURL:[theURL path]];
}


@end
