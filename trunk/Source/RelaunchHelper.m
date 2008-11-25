//
//  RelaunchHelper.m


#import <Cocoa/Cocoa.h>
#import <unistd.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// get the path
	NSString *bundleToRelaunchPath = [NSString stringWithCString: argv[1]];
		
	NSURL *url = [NSURL fileURLWithPath: bundleToRelaunchPath];
	
	/* Sleep a few seconds to make shure the application has terminated */
	sleep(2);
	
	/* ... and relaunch */
	LSLaunchURLSpec launchSpec;
	launchSpec.appURL = (CFURLRef)url;
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
