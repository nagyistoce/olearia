//
//  AboutBoxController.m
//  Olearia
//
//  Created by Kieren Eaton on 7/09/08.
//  Copyright 2008 BrainBender Software. All rights reserved.
//

#import "AboutBoxController.h"


@implementation AboutBoxController

- (id) init
{
	if (![super initWithWindowNibName:@"About"]) return nil;
	
	
	
	
	
	return self;
}

- (void)windowDidLoad
{
	[aboutPanel makeKeyAndOrderFront:self];
	
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	
	// Setup the app name field
	NSString *appName = [infoDict objectForKey:@"CFBundleName"];
	[appNameField setStringValue:appName];
	
	// Set the about box window title
	[aboutPanel setTitle:[NSString stringWithFormat:@"About %@", appName]];
	
	// Setup the version field
	[versionField setStringValue:[NSString stringWithFormat:@"Version %@ (%@)", [infoDict objectForKey:@"CFBundleShortVersionString"],[infoDict objectForKey:@"CFBundleVersion"]]];
	
	[copyrightField setStringValue:[infoDict valueForKey:@"NSHumanReadableCopyright"]];
	
	NSString *creditsPath = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtfd"];
	
	NSAttributedString *creditsString = [[NSAttributedString alloc] initWithPath:creditsPath 
										  documentAttributes:nil];
	
	[creditsView replaceCharactersInRange:NSMakeRange( 0, 0 ) 
								 withRTFD:[creditsString RTFDFromRange:NSMakeRange( 0, [creditsString length] )
												    documentAttributes:nil]];
	
	
}


@end
