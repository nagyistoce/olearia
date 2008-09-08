//
//  AboutBoxController.h
//  Olearia
//
//  Created by Kieren Eaton on 7/09/08.
//  Copyright 2008 BrainBender Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AboutBoxController : NSWindowController 

{
	IBOutlet NSPanel *aboutPanel;
	
	IBOutlet NSTextField *appNameField;
    IBOutlet NSTextField *copyrightField;
    IBOutlet NSTextView *creditsView;
    IBOutlet NSTextField *versionField;
    NSTimer *scrollTimer;
    float currentPosition;
    float maxScrollHeight;
    NSTimeInterval startTime;
    BOOL restartAtTop;
	
}

@end
