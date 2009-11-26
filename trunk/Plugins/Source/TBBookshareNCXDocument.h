//
//  TBBookshareNCXDocument.h
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 18/11/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TBNCXDocument.h"


@interface TBBookshareNCXDocument : TBNCXDocument
{

@private	
	NSArray		*m_navPoints;
	NSUInteger	m_currentNavPointIndex;
}

@end
