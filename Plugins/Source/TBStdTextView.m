//
//  TBStdTextView.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 28/06/09.
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

#import "TBStdTextView.h"

@implementation TBStdTextView


- (void)setURL:(NSURL *)theURL
{
	if(![[theURL path] isEqualToString:[webContentView mainFrameURL]])
		[webContentView setMainFrameURL:[theURL path]];

	//NSAttributedString *contentString = [[[NSAttributedString alloc] initWithPath:[theURL path] 
//															   documentAttributes:nil] autorelease];
//	NSString *contentString = [NSString stringWithContentsOfURL:theURL encoding:NSUTF8StringEncoding error:nil];
//	
//	[textContentView read];

//		NSAttributedString *creditsString = [[[NSAttributedString alloc] initWithURL:theURL
//																  documentAttributes:nil]
//											 autorelease];
//		
//		[textContentView replaceCharactersInRange:NSMakeRange( 0, 0 ) 
//									 withRTFD:[creditsString RTFDFromRange:NSMakeRange( 0, [creditsString length] )
//													    documentAttributes:nil]];
	
}


@end
