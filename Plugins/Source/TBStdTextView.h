//
//  TBTextView.h
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 28/06/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class WebView;


@interface TBStdTextView : NSView
{
	IBOutlet WebView	*theWebView;
}

- (void)setURL:(NSURL *)theURL;

@end
