//
//  RelaunchHelper.m
//  RelaunchHelper
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

#import <Foundation/Foundation.h>
#import <unistd.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// get the path
	NSString *relaunchPath = [NSString stringWithCString:argv[1] encoding:NSMacOSRomanStringEncoding];
	
	// make a url of it
	NSURL *pathURL = [NSURL fileURLWithPath:relaunchPath];
	
	// Sleep for a bit to allow proper application termination
	sleep(2);
	
	// set up the launch
	LSLaunchURLSpec launchSpec;
	launchSpec.appURL = (CFURLRef)pathURL;
	launchSpec.itemURLs = NULL;
	launchSpec.passThruParams = NULL;
	launchSpec.launchFlags = kLSLaunchNewInstance | kLSLaunchDefaults;
	launchSpec.asyncRefCon = NULL;
	
	OSErr err= LSOpenFromURLSpec(&launchSpec, NULL);
	if(err != noErr)
		NSLog(@"RelaunchHelper: could not relaunch the application. Error code: %d", err);
	
	[pool release];
	
	return 0;
}
