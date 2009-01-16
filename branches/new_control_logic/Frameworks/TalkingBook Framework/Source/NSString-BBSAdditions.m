//
//  NSString-BBSAdditions.m
//  TalkingBook Framework
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

#import "NSString-BBSAdditions.h"
#import "RegexKitLite.h"

#define TIMECODEREGEX @"(?:(^\\d\\d?):(\\d\\d?):|(^\\d\\d?):)?(\\d*)(?:\\.(\\d{1,3}))?"

@implementation NSString (BBSAdditions)

+ (NSString *)QTStringFromSmilTimeString:(NSString *)aTimeString
{

	NSInteger hours = 0, minutes = 0, seconds = 0, fractions = 0;
	
	// check for a specifically set timescale first
	if([aTimeString isMatchedByRegex:@"(h|min|ms)|(s)"])
	{
		// we have a specific timescaled clock-value
		
		NSInteger  capt4=0,capt5=0;
		long long totalTimeInSeconds = 0;
		// get the values from the string

		NSRange matchedRange = NSMakeRange(NSNotFound, 0); // setup the range
		
		// get the string that specifies the scale
		matchedRange = [aTimeString rangeOfRegex:@"(h|min|ms)|(s)" capture:1];
		if (NSNotFound == matchedRange.location)
			matchedRange = [aTimeString rangeOfRegex:@"(h|min|ms)|(s)" capture:2];
		NSString *scaleStr = [aTimeString substringWithRange:matchedRange];
		
		// get the fourth capture value -- usually seconds 
		matchedRange = [aTimeString rangeOfRegex:TIMECODEREGEX capture:4]; // get the value if any 
		capt4 = (matchedRange.location != NSNotFound) ? [[aTimeString substringWithRange:matchedRange] intValue] : 0;
		
		// get the fractional value if it exists
		matchedRange = [aTimeString rangeOfRegex:TIMECODEREGEX capture:5]; // get the fraction if any
		capt5 = (matchedRange.location != NSNotFound) ? [[aTimeString substringWithRange:matchedRange] intValue] : 0;
				
		// check for miliseconds as a default specifier
		if(NO == [scaleStr isEqualToString:@"ms"])
		{
			// check the multiplier
			if(YES == [scaleStr isEqualToString:@"s"])	// seconds
			{
				
				if((fractions != 0) && (fractions > 999)) // check if there was a milisecond value larger than 1 second
				{
					totalTimeInSeconds = (NSInteger)(capt5 / 1000);
					fractions = fractions % 1000; // leftover milliseconds 
				}
				totalTimeInSeconds = totalTimeInSeconds + capt4;  // total number of whole seconds 
			}
			else if(YES == [scaleStr isEqualToString:@"min"]) // minutes
			{
				// 60 seconds in a minute
				totalTimeInSeconds = (60 * capt4) + (capt5 * 60);  
				fractions = 0; // we have added the seconds to the total time so set this to 0
			}
			else // scaleStr == "h" for hours
			{
				// 60 Secs * 60 Mins = 3600 seconds in an hour
				totalTimeInSeconds = (3600 * capt4) + (capt5 * 60); 
			}
		}
		else  // scaleStr 
		{
			if(capt4 < 1000) // milliseconds value less than 1 second?
			{
				totalTimeInSeconds = (int)(capt4 * 10);
				fractions = (int)(capt5 * 10); // leftover milliseconds 
			}
			else 
			{	// more than 1 second of milliseconds 
				totalTimeInSeconds = (int)(capt4 / 1000);
				fractions = (int)(capt4 % 1000) + (int)(capt5 * 10); // leftover milliseconds 
			}
		}
		hours = totalTimeInSeconds / 3600; 
		minutes = (totalTimeInSeconds / 3600) % 60; 
		seconds = ((totalTimeInSeconds / 3600) % 60) % 60;
	}
	else 
	{	
		// we have a SMPTE similar form of timecode.
		if([aTimeString isMatchedByRegex:TIMECODEREGEX])
		{
			NSRange matchedRange = NSMakeRange(NSNotFound, 0); // setup the range
			
			matchedRange = [aTimeString rangeOfRegex:TIMECODEREGEX capture:4]; // seconds
			seconds = (matchedRange.location != NSNotFound) ? [[aTimeString substringWithRange:matchedRange] intValue] : 0;
			
			matchedRange = [aTimeString rangeOfRegex:TIMECODEREGEX capture:5]; // fractions
			fractions = (matchedRange.location != NSNotFound) ? [[aTimeString substringWithRange:matchedRange] intValue] : 0;
			
			// get the third capture value --  usually minutes
			matchedRange = [aTimeString rangeOfRegex:TIMECODEREGEX capture:3];
			if(NSNotFound == matchedRange.location)
			{	 
				// if there is not third capture we may have hours and minutes
				// which due to the way the regex works get moved to positions 1 and 2 and 3 is empty
				matchedRange = [aTimeString rangeOfRegex:TIMECODEREGEX capture:1]; // get the value if any 
				hours = (matchedRange.location != NSNotFound) ? [[aTimeString substringWithRange:matchedRange] intValue] : 0;
				matchedRange = [aTimeString rangeOfRegex:TIMECODEREGEX capture:2]; // get the value if any 
				minutes = (matchedRange.location != NSNotFound) ? [[aTimeString substringWithRange:matchedRange] intValue] : 0;
			}
			else // get the value of the third capture value 
				minutes = (matchedRange.location != NSNotFound) ? [[aTimeString substringWithRange:matchedRange] intValue] : 0;
			
			
			
		}
	}
	// no Days so use 00
	return [self stringWithFormat:@"00:%d:%d:%d.%d", hours, minutes, seconds, fractions];

}

+ (NSString *)QTStringFromSmilTimeString:(NSString *)aTimeString withTimescale:(long)aTimeScale
{
	return [self stringWithFormat:@"%@/%ld",[self QTStringFromSmilTimeString:aTimeString], aTimeScale];
}


@end
