//
//  TBPluginInterface.h
//  TalkingBook Framework
//
//  Created by Kieren Eaton on 19/05/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


#import <Cocoa/Cocoa.h>
#import "TalkingBookTypes.h"

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
// return a textual description of the book type
- (NSString *)FormatDescription;
// return YES if the book can be opened by this plugin
//- (BOOL)canOpenBook:(NSURL *)bookURL;
// return YES if the book can be and was opened correctly
- (BOOL)openBook:(NSURL *)bookURL;
// returns the node of the book that contains the full metadata
- (NSXMLNode *)infoMetadataNode;

// start or continue playback of the book
- (void)startPlayback;
// stop or pause playback of the book
- (void)stopPlayback;
// returns the URL of the file that was deemed by the plugin as the correct one to load first
- (NSURL *)loadedURL;


@end
