//
//  TBPluginInterface.h
//  TalkingBook Framework
//
//  Created by Kieren Eaton on 19/05/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TBTalkingBookTypes.h"

@protocol TBPluginInterface 

+ (BOOL)initializeClass:(NSBundle *)theBundle;
+ (void)terminateClass;
// return an enumerated list of instances of all the classes available in the bundle
+ (NSArray *)plugins;

// return an instance of the booktype. 
//+ (id)bookType;
// return the class of a types superclass. Nil otherwise 
//- (id)variantOfType;
// return a pointer to the text document parser class if it has one. Nil otherwise.
- (id)textPlugin;
// return a pointer to the SMIL document parser class if it has one. nil otherwise.
- (id)smilPlugin;
// return a textual description of the book type
- (NSString *)FormatDescription;
// return YES if the book can be opened by this plugin
//- (BOOL)canOpenBook:(NSURL *)bookURL;
// return YES if the book can be and was opened correctly
- (BOOL)openBook:(NSURL *)bookURL;
// returns the node of the book that contains the full metadata
- (NSXMLNode *)infoMetadataNode;

- (void)startPlayback;
- (void)stopPlayback;



@end
