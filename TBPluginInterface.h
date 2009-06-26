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

// return an instance of the view used in the text window.
// this will allow different plugins to have complete control over the display 
// of the view
- (NSView *)textView;

// return an instance of the view used in the information window.
// this will allow plugins to have their own information laid out as they like
- (NSView *)bookInfoView;

// pass in the plugin for which the book information view will be updated
// this causes the plugin to update its data in the information view.
// Structured this way to allow the principal class not to have to track 
// which plugin is being used. 
- (void)updateInfoFromPlugin:(id)aPlugin;

// return a textual description of the Format the book was authored with
- (NSString *)FormatDescription;

// reset the plugin to a state ready for loading a book. 
- (void)reset;

// return YES if the book was recognized and opened correctly 
- (BOOL)openBook:(NSURL *)bookURL;

// start or continue playback of the book
- (void)startPlayback;

// stop playback of the book
- (void)stopPlayback;

// returns the URL of the file that was deemed by the plugin as the correct one to load first
// used for passing the correct URL for loading to things like recent documents lists
- (NSURL *)loadedURL;

// move to a point in the book denoted by a string of the full path within the control document
// used in the resuming of playback with recent files list
- (void)moveToControlPosition:(NSString *)aNodePath;

// returns the a string representation of the position in the book
// used mainly for saving in the recent files list
- (NSString *)currentControlPosition;

@end
