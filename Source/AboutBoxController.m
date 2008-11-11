//
//  AboutBoxController.m
//  Olearia
//
//  Created by Kieren Eaton on 7/09/08.
//  Copyright 2008 BrainBender Software. All rights reserved.
//
//  Created by Kieren Eaton on 25/07/08.
//  Copyright 2008 BrainBender Software. All rights reserved.
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

#import "AboutBoxController.h"


@implementation AboutBoxController

- (id) init
{
	if (![super initWithWindowNibName:@"About"]) return nil;
	
	/*
	currentPosition = 0;
	restartAtTop = NO;
	startTime = [NSDate timeIntervalSinceReferenceDate] + 3.0;
	*/
	
	
	return self;
}

- (void)windowDidLoad
{
	[creditsView scrollPoint:NSMakePoint( 0, 0 )];
	
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
	
	NSString *creditsPath = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"];
	
	NSAttributedString *creditsString = [[NSAttributedString alloc] initWithPath:creditsPath 
										  documentAttributes:nil];
	
	[creditsView replaceCharactersInRange:NSMakeRange( 0, 0 ) 
								 withRTFD:[creditsString RTFDFromRange:NSMakeRange( 0, [creditsString length] )
												    documentAttributes:nil]];
	
	
	
	//maxScrollHeight = [[creditsView string] length];

}
/*
- (void)windowDidBecomeKey:(NSNotification *)notification
{

    scrollTimer = [NSTimer scheduledTimerWithTimeInterval:1/4 
												   target:self 
												 selector:@selector(scrollCredits:) 
												 userInfo:nil 
												  repeats:YES];
	
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    [scrollTimer invalidate];
}

- (void)scrollCredits:(NSTimer *)timer
{
	
    if ([NSDate timeIntervalSinceReferenceDate] >= startTime)
    {
		if (restartAtTop)
        {
            // Reset the startTime
            startTime = [NSDate timeIntervalSinceReferenceDate] + 3.0;
            restartAtTop = NO;
            
            // Set the position
            [creditsView scrollPoint:NSMakePoint( 0, 0 )];
            
            return;
        }
		if (currentPosition >= maxScrollHeight) 
        {
            // Reset the startTime
            startTime = [NSDate timeIntervalSinceReferenceDate] + 3.0;
            
            // Reset the position
            currentPosition = 0;
            restartAtTop = YES;
        }
        else
        {
			
            // Scroll to the position
            [[creditsView animator] scrollPoint:NSMakePoint( 0, currentPosition )];
            
            // Increment the scroll position
            currentPosition += 0.005;
        }
    }
}
*/

@end
