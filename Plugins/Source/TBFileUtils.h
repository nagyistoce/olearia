//
//  TBFileUtils.h
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 20/05/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface TBFileUtils : NSObject 
{
	NSFileManager *fileManager;
}

- (BOOL)URL:(NSURL *)aURL hasExtension:(NSArray *)validExtensions;
- (BOOL)URLisDirectory:(NSURL *)aDir;
- (NSURL *)fileURLFromFolder:(NSString *)aPath WithExtension:(NSString *)anExtension;


@end
