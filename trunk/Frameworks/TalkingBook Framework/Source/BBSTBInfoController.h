//
//  InfoWindowController.h
//  Olearia
//
//  Created by Kieren Eaton on 30/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BBSTalkingBook; 

@interface BBSTBInfoController : NSObject 
{
	IBOutlet NSPanel		*infoPanel;
	IBOutlet NSTableView	*infoTableView;
	
	NSMutableArray *metaInfo;
}

- (void)displayInfoPanel;
- (id)initWithMetadataNode:(NSXMLNode *)aNode;
- (void)updateMetaInfoFromNode:(NSXMLNode *)metaNode;

@property (readwrite, retain) NSMutableArray *metaInfo;

@end
