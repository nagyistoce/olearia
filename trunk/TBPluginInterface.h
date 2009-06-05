//
//  TBPluginInterface.h
//  TalkingBook Framework
//
//  Created by Kieren Eaton on 19/05/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol TBPluginInterface 

+ (BOOL)initializeClass:(NSBundle *)theBundle;
+ (void)terminateClass;
// return an enumerated list of instances of all the classes available in the bundle
+ (NSArray *)plugins;

// return a pointer to the text document instance if it has one. Nil otherwise.
// this will allow different plugins to return their specific variation of the text plugin
- (id)textPlugin;
// return a pointer to the SMIL document instance if it has one. Nil otherwise.
// this will allow different plugins to return their specific variation of the SMIL plugin
- (id)smilPlugin;

// return a textual description of the Format the book was authored with
- (NSString *)FormatDescription;

// return YES if the book was recognized and opened correctly 
- (BOOL)openBook:(NSURL *)bookURL;
// returns the node of the book that contains the full metadata
- (NSXMLNode *)infoMetadataNode;

// start or continue playback of the book
- (void)startPlayback;
// stop or pause playback of the book
- (void)stopPlayback;
// returns the URL of the file that was deemed by the plugin as the correct one to load first
- (NSURL *)loadedURL;

// move to a point in the book denoted by a string of the full node path 
- (void)moveToPosition:(NSString *)aNodePath;
// get the current play position of the node in the book
- (NSString *)currentPositionID;



@end
