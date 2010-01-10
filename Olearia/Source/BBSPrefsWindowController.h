//
//  BBSPrefsWindowController.h
//
//  Created by Kieren Eaton
// 
//	Based on the BBSPrefsWindowController by Dave Batton
//  http://www.Mere-Mortal-Software.com/blog/

#import <Cocoa/Cocoa.h>

@interface BBSPrefsWindowController : NSWindowController {
	@private
	NSMutableArray *toolbarIdentifiers;
	NSMutableDictionary *toolbarViews;
	NSMutableDictionary *toolbarItems;

	NSView *contentSubview;
	NSViewAnimation *viewAnimation;
}

+ (BBSPrefsWindowController *)sharedPrefsWindowController;
+ (NSString *)nibName;

- (void)setupToolbar;
- (void)addView:(NSView *)view label:(NSString *)label;
- (void)addView:(NSView *)view label:(NSString *)label image:(NSImage *)image;

@end
