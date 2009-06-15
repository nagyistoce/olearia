//
//  InfoView.h
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 15/06/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

@class TBStdFormats;

@interface InfoView : NSView 
{
	IBOutlet NSTableView	*infoTableView;

	NSMutableArray			*_metaInfo;
	
	CGFloat _maxStrLen;
}

- (void)updateInfoFromPlugin:(TBStdFormats *)aPlugin;

@end
