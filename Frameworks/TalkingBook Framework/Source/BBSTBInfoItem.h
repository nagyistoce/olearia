//
//  InfoItem.h
//  BBSTalkingBook
//
//  Created by Kieren Eaton on 30/11/08.
//  Copyright 2008 . All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BBSTBInfoItem : NSObject 
{
	NSString	*title;
	NSString	*content;
}

- (id)initWithTitle:(NSString *)aTitle andContent:(NSString *)aContent;
- (BOOL)isEqual:(id)anObject;

@property (copy) NSString *title;
@property (copy) NSString *content;

@end
