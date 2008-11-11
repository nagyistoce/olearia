//
//  NSXMLElement-BBSExtensions.m
//  BBSTalkingBook
//
//  Created by Kieren Eaton on 3/07/08.
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

#import "NSXMLElement-BBSExtensions.h"

@implementation NSXMLElement (BBSExtensions)

- (NSInteger)attributeCount
{
	// return the count of how many (if any) attributes the node has
	return [[self attributes] count];
}

- (NSDictionary *)dictionaryFromAttributes
{
	// create a dictionary of all the attributes as keys and values
	NSMutableDictionary *attributes;
	
	if([self attributeCount] > 0) // check we have some attributes
	{
		attributes = [[NSMutableDictionary alloc] init];
		NSArray *attributeElements = [self attributes];
		for(NSXMLElement *anElement in attributeElements) // iterate through the attributes
		{
			// add each attribute to the dictionary
			[attributes setObject:[anElement stringValue] forKey:[anElement name]];
		}
	}
	else 
		return nil;
	
	return attributes;
}

- (NSDictionary *)dictionaryFromElement
{
	
	NSMutableDictionary *nodeElements = [[NSMutableDictionary alloc] init];
	
	if([self childCount] > 0) // check if the node has any child nodes
	{
		NSArray *children = [self children];
		for(NSXMLElement *aChild in children) // iterate through the child nodes
		{
			// check if the node has children
			if([aChild childCount] > 0)
				if([aChild name] != nil) // sometimes a node has no name so ignore it
				{	
					// process the child node 
					NSDictionary *aDict = [aChild dictionaryFromElement];
					if(aDict != nil) // check if there was anything in the node
						[nodeElements setObject:aDict forKey:[aChild name]];
				}

			
			NSString *nodeName = [aChild name]; // get the nodes name
			NSString *nodeContent = [aChild stringValue]; // get the nodes content
			//NSLog(@" node Name : %@ : Value : %@",[aChild name],[aChild stringValue]);
			// check that there is a value in both the name and content 
			// and that the key doesnt already exist
			if((nodeName != nil) && (nodeContent != nil) && ([aChild attributeCount] == 0) && ([nodeElements objectForKey:nodeName] == nil))
			{	
				// add the name and its content to the dict
				[nodeElements setObject:[aChild stringValue] forKey:[aChild name]];
			}
			//else
			//	[nodeElements addEntriesFromDictionary:<#(NSDictionary *)otherDictionary#>
			
						
			// a TEXT node holds the content of its parent node so make sure that its not one
			// and add the attributes as a dictionary off the node name
			if(([aChild kind] != NSXMLTextKind) && ([aChild attributeCount] > 0))
			//if([aChild attributeCount] > 0)
				[nodeElements setObject:[aChild dictionaryFromAttributes] forKey:[aChild name]];
			
			//NSLog(@"node elements contains : %@",nodeElements);
		}
	}
	else // node has no children		
		if([self stringValue] != nil) // as long as there is content add it to the dict 
			[nodeElements setObject:[self stringValue] forKey:[self name]];
	
	if([self attributeCount] > 0) // check if the node contains attributes. A node can have children and attributes
		[nodeElements setObject:[self dictionaryFromAttributes] forKey:[self name]];

	// return the contents of the dictionary if there was anything added to it
	return ([nodeElements count] == 0) ? nil : nodeElements;
}

/*
- (NSArray *)arrayFromElement
{
	NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	if([self childCount] > 0)
	{
		NSArray *nodeChildren = [self children];
		for(NSXMLElement *aChild in nodeChildren)
		{
			if
			NSDictionary *childContents = [aChild dictionaryFromElement];
			if(childContents != nil)
				[tempArray addObject:childContents]; 
			NSLog(@" temp array contents : %@",tempArray);
		}
	}
	return ([tempArray count] > 0) ? tempArray : nil; 
}
*/
@end
