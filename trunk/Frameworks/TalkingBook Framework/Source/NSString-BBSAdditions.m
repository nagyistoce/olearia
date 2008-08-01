//
//  NSString-BBSAdditions.m
//  BBSTalkingBook
//
//  Created by Kieren Eaton on 25/07/08.
//  BrainBender Software. 
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

#define TIMECODEREGEX @"(?:(\\d?\\d):)?(?:(\\d?\\d):)?(?:(\\d?\\d))(?:\\.(\\d\\d?\\d?))?"

@implementation NSString (BBSAdditions)

- (NSString *)qtTimeStringFromSmilTimeString:(NSString *)aTimeString
{
	NSString *qtFormattedString = nil;
	NSInteger hours = 0, minutes = 0, seconds = 0, fractions = 0;
	// check for a specifically set timescale first
	if([aTimeString isMatchedByRegex:@"(h|min|ms|s)"])
	{
		// we have a specific timescaled clock-value
		NSString *scaleStr = nil;
		
		NSInteger  value;
		long long totalTimeInSeconds = 0;
		// get the values from the string

		NSRange matchedRange = NSMakeRange(NSNotFound, 0); // setup the range
		
		// get the string that specifies the scale
		matchedRange = [aTimeString rangeOfRegex:@"(h|min|ms|s)" capture:1];
		scaleStr = [aTimeString substringWithRange:matchedRange];
		
		// get the value so we can work with it
		matchedRange = [aTimeString rangeOfRegex:TIMECODEREGEX capture:3]; // get the value if any 
		value = (matchedRange.location != NSNotFound) ? [[aTimeString substringWithRange:matchedRange] intValue] : 0;
		
		// get the fractional value
		matchedRange = [aTimeString rangeOfRegex:TIMECODEREGEX capture:4]; // get the fraction if any
		fractions = (matchedRange.location != NSNotFound) ? [[aTimeString substringWithRange:matchedRange] intValue] : 0;
		
		if(NO == [scaleStr isEqualToString:@"ms"])
		{
			// check the multiplier
			if(YES == [scaleStr isEqualToString:@"s"])	// seconds
			{
				
				if((fractions != 0) && (fractions > 999)) // check if there was a milisecond value larger than 1 second
				{
					totalTimeInSeconds = totalTimeInSeconds + (NSInteger)(fractions / 1000);
					fractions = fractions % 1000; // leftover milliseconds 
				}
				totalTimeInSeconds = totalTimeInSeconds + value;  // total number of whole seconds 
			}
			else if(YES == [scaleStr isEqualToString:@"min"]) // minutes
			{
				// 60 seconds in a minute
				
				totalTimeInSeconds = (60 * value) + fractions;
				fractions = 0; // we have added the seconds to the total time so set this to 0
			}
			else // scaleStr == "h" for hours
			{
				// 60 Secs * 60 Mins = 3600 seconds in an hour
				totalTimeInSeconds = (3600 * value) + (60 * fractions); 
			}
		}
		else  // scaleStr == ms (miliseconds)
		{
			if(value < 1000) // milliseconds value less than 1 second?
			{
				totalTimeInSeconds = (int)(value * 10);
				fractions = (int)(value * 10) + (int)(fractions * 10); // leftover milliseconds 
			}
			else
			{	
				totalTimeInSeconds = (int)((value * 10) / 1000);
				fractions = (int)((value * 10) % 1000) + (int)(fractions * 10); // leftover milliseconds 
			}
		}
		hours = totalTimeInSeconds % 3600; // 60 secs * 60 mins
		totalTimeInSeconds = totalTimeInSeconds - (hours * 3600);
		minutes = totalTimeInSeconds % 60; // 60 seconds
		seconds = totalTimeInSeconds - (minutes * 60);
	}
	else 
	{	
		// we have a SMPTE similar form of timecode.
		if([aTimeString isMatchedByRegex:TIMECODEREGEX])
		{
			NSRange matchedRange = NSMakeRange(NSNotFound, 0); // setup the range
			
			matchedRange = [aTimeString rangeOfRegex:TIMECODEREGEX capture:1]; // check for the hours
			hours = (matchedRange.location != NSNotFound) ? [[aTimeString substringWithRange:matchedRange] intValue] : 0;
			
			matchedRange = [aTimeString rangeOfRegex:TIMECODEREGEX capture:2]; // check for the minutes
			minutes = (matchedRange.location != NSNotFound) ? [[aTimeString substringWithRange:matchedRange] intValue] : 0;
			
			matchedRange = [aTimeString rangeOfRegex:TIMECODEREGEX capture:3]; // check for seconds
			seconds = (matchedRange.location != NSNotFound) ? [[aTimeString substringWithRange:matchedRange] intValue] : 0;
			
			matchedRange = [aTimeString rangeOfRegex:TIMECODEREGEX capture:4]; // check for fractions of a second
			fractions = (matchedRange.location != NSNotFound) ? [[aTimeString substringWithRange:matchedRange] intValue] : 0;
			
		}
	}
	// no Days so use 00
	qtFormattedString = [NSString stringWithFormat:@"00:%d:%d:%d.%d", hours, minutes, seconds, fractions];
	return qtFormattedString;
}

- (NSString *)qtTimeStringFromSmilTimeString:(NSString *)aTimeString withTimescale:(long)aTimeScale
{
	NSMutableString *qtTimeString = [NSMutableString stringWithString:[self qtTimeStringFromSmilTimeString:aTimeString]];
	[qtTimeString stringByAppendingFormat:@"/%ld",aTimeScale];
	
	return qtTimeString;
}


@end
