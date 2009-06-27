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
	
	
	
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	
	// Setup the app name field
	NSString *appName = [infoDict objectForKey:@"CFBundleName"];
	[appNameField setStringValue:appName];
	
	// Set the about box window title
	[[self window] setTitle:[NSString stringWithFormat:NSLocalizedString(@"About %@", @"about panel about string"), appName]];
	
	// Setup the version field
	[versionField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Version %@ (%@)", @"about panel version string"), [infoDict objectForKey:@"CFBundleShortVersionString"],[infoDict objectForKey:@"CFBundleVersion"]]];
	
	[copyrightField setStringValue:[infoDict valueForKey:@"NSHumanReadableCopyright"]];
	
	NSString *creditsPath = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"];
	
	NSAttributedString *creditsString = [[[NSAttributedString alloc] initWithPath:creditsPath 
										  documentAttributes:nil] autorelease];
	
	[creditsView replaceCharactersInRange:NSMakeRange( 0, 0 ) 
								 withRTFD:[creditsString RTFDFromRange:NSMakeRange( 0, [creditsString length] )
												    documentAttributes:nil]];
	
	[[self window] makeKeyAndOrderFront:self];
	
	//maxScrollHeight = [[creditsView string] length];

}

- (IBAction)donate:(NSButton *)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&encrypted=-----BEGIN+PKCS7-----MIIHPwYJKoZIhvcNAQcEoIIHMDCCBywCAQExggEwMIIBLAIBADCBlDCBjjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQwEgYDVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9jZXJ0czERMA8GA1UEAxQIbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBhbC5jb20CAQAwDQYJKoZIhvcNAQEBBQAEgYCQSQ6k1nBhCa2wyOZosokgJvG%2F1qlAXFFCKef5gVX1j0J%2FlnEI1B%2FkPAqC3UtO1TVjxYCGnZrsCXJmjB24nS0POgHnvgxEWxm%2BNAQaQo3I4Ne0bK8yQ6xxl7WbvR5l%2BeYDTfFklFBTyLjZAUuPrxRHaxc0HCm3OtRYwRYd0FolSzELMAkGBSsOAwIaBQAwgbwGCSqGSIb3DQEHATAUBggqhkiG9w0DBwQI%2F3UQWQ9v5BaAgZhwfon0nvIht6HVLypkNvhLpv2IgE3oAFDRl%2FyMj1w2nxyslcE%2FKCxUS7oIck%2BacfKE6BoIyTpzUzYt%2FBFw9O36vck6iw2SgbzHY6So2kutiRQiLn2p1DRG%2BgSXcx8Y8Gh%2B13naZtNh7fhzzA7ViAKengiXU808yZtftF%2BG8Bt2pVw6EWino4YA%2F8gutdOdupYnsXkmB9B%2FtqCCA4cwggODMIIC7KADAgECAgEAMA0GCSqGSIb3DQEBBQUAMIGOMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExFjAUBgNVBAcTDU1vdW50YWluIFZpZXcxFDASBgNVBAoTC1BheVBhbCBJbmMuMRMwEQYDVQQLFApsaXZlX2NlcnRzMREwDwYDVQQDFAhsaXZlX2FwaTEcMBoGCSqGSIb3DQEJARYNcmVAcGF5cGFsLmNvbTAeFw0wNDAyMTMxMDEzMTVaFw0zNTAyMTMxMDEzMTVaMIGOMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExFjAUBgNVBAcTDU1vdW50YWluIFZpZXcxFDASBgNVBAoTC1BheVBhbCBJbmMuMRMwEQYDVQQLFApsaXZlX2NlcnRzMREwDwYDVQQDFAhsaXZlX2FwaTEcMBoGCSqGSIb3DQEJARYNcmVAcGF5cGFsLmNvbTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAwUdO3fxEzEtcnI7ZKZL412XvZPugoni7i7D7prCe0AtaHTc97CYgm7NsAtJyxNLixmhLV8pyIEaiHXWAh8fPKW%2BR017%2BEmXrr9EaquPmsVvTywAAE1PMNOKqo2kl4Gxiz9zZqIajOm1fZGWcGS0f5JQ2kBqNbvbg2%2FZa%2BGJ%2FqwUCAwEAAaOB7jCB6zAdBgNVHQ4EFgQUlp98u8ZvF71ZP1LXChvsENZklGswgbsGA1UdIwSBszCBsIAUlp98u8ZvF71ZP1LXChvsENZklGuhgZSkgZEwgY4xCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJDQTEWMBQGA1UEBxMNTW91bnRhaW4gVmlldzEUMBIGA1UEChMLUGF5UGFsIEluYy4xEzARBgNVBAsUCmxpdmVfY2VydHMxETAPBgNVBAMUCGxpdmVfYXBpMRwwGgYJKoZIhvcNAQkBFg1yZUBwYXlwYWwuY29tggEAMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEAgV86VpqAWuXvX6Oro4qJ1tYVIT5DgWpE692Ag422H7yRIr%2F9j%2FiKG4Thia%2FOflx4TdL%2BIFJBAyPK9v6zZNZtBgPBynXb048hsP16l2vi0k5Q2JKiPDsEfBhGI%2BHnxLXEaUWAcVfCsQFvd2A1sxRr67ip5y2wwBelUecP3AjJ%2BYcxggGaMIIBlgIBATCBlDCBjjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQwEgYDVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9jZXJ0czERMA8GA1UEAxQIbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBhbC5jb20CAQAwCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTA4MDQxMDA5MjI0N1owIwYJKoZIhvcNAQkEMRYEFLwOfkI7ap6EQ61xZLGF1bW1Osb8MA0GCSqGSIb3DQEBAQUABIGAXtlFv9XQmcJmq0vzI5VxP2fbM8sgrg9foJ7SWJUDaGIeeKzuF2q5UfsL0BCr8GQbpiY9okieETJ%2B9IgaBh%2FvbJ3372JnstwYbqQniCmIL4WvZEY5wz0S30ChjBqo%2BXBcTZTW6Br6iSY%2FiV85yDq8wFxWhRhbx3fPJd%2BQ1fPLfv8=-----END+PKCS7-----"]];
}

- (IBAction)gotoHomepage:(NSButton *)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://olearia.googlecode.com"]];
}

- (IBAction)showLicense:(NSButton *)sender
{
	NSString *licenseFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"License" ofType:@"txt"];
	[licenseView setString:[NSString stringWithContentsOfFile:licenseFilePath encoding:NSUTF8StringEncoding error:nil]];
	
	[NSApp beginSheet:licensePanel
	   modalForWindow:[self window]
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
	
}

- (IBAction)hideLicense:(NSButton *)sender
{
    [licensePanel orderOut:nil];
    [NSApp endSheet:licensePanel returnCode:0];
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
