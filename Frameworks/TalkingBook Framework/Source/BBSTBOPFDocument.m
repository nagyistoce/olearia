//
//  BBSTBOPFDocument.m
//  TalkingBook Framework
//
//  Created by Kieren Eaton on 15/04/08.
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

#import <Cocoa/Cocoa.h>

#import "BBSTBOPFDocument.h"
#import "BBSTalkingBookTypes.h"
#import "NSXMLElement-BBSExtensions.h"

@interface BBSTBOPFDocument ()

@property (readwrite, retain) NSDictionary *manifest; 	
@property (readwrite, retain) NSDictionary *guide;
@property (readwrite, retain) NSArray *spine;
@property (readwrite, retain) NSArray *tour;
@property (readwrite, retain) NSXMLNode *metaDataNode;

@property (readwrite, copy) NSString	*ncxFilename;
@property (readwrite, copy) NSString	*xmlTextContentFilename;

@property (readwrite) NSInteger	currentPosInSpine;

- (NSArray *)processSpineSection:(NSXMLElement *)aRootElement;
- (NSArray *)processTourSection:(NSXMLElement *)aRootElement;
- (NSDictionary *)processManifestSection:(NSXMLElement *)aRootElement;
- (NSDictionary *)processGuideSection:(NSXMLElement *)aRootElement;

- (NSInteger)prevSpinePos;
- (NSInteger)nextSpinePos;
- (NSString *)filenameForCurrentSpinePos;
- (NSString *)filenameForID:(NSString *)anID;

@end



@implementation BBSTBOPFDocument

- (id) init
{
	if (!(self=[super init])) return nil;
		
	return self;
}

/*
 xpath / xquery statements
 
 get the xml filename 
 //manifest/item[@media-type="application/x-dtbook+xml"]/data(@href)
 get the ncx filename
 //manifest/item[@media-type="application/x-dtbncx+xml"]/data(@href)

 
 
 
 */




- (BOOL)processMetadata
{
	BOOL isOk = NO;	
	
	NSXMLNode *metaNode = [self metadataNode];
	
	// get the root element of the tree
	NSXMLElement *opfRoot = [xmlPackageDoc rootElement];
	
	// check we have any valid metadata before adding the rest.
	
	self.manifest = [NSDictionary dictionaryWithDictionary:[self processManifestSection:opfRoot]];
	self.spine = [NSArray arrayWithArray:[self processSpineSection:opfRoot]];
	self.guide = [NSDictionary dictionaryWithDictionary:[self processGuideSection:opfRoot]];
	currentPosInSpine = -1;
	
	// ends-with is used extensively here to avoid issues if the namespaces attached to the content 
	// ever change
	
	// get the media format of the book. 
	[commonInstance setMediaFormatFromString:[self stringForXquery:@"//meta[@name][ends-with(@name,'multimediaType')]/data(@content)" ofNode:opfRoot]];
	
	// get the dc:Format node string
	NSString *bookFormatString = [self stringForXquery:@"dc-metadata/data(*:Format)" ofNode:metaNode];
	
	// check the type for DTB 2002 specifier
	if(YES == [[bookFormatString uppercaseString] isEqualToString:@"ANSI/NISO Z39.86-2002"])
	{	
			// set the type to DTB 2002
		self.commonInstance.bookType = DTB2002Type;
		
		// it may be a bookshare book 
		// check the identifier node for a scheme attribute containing "BKSH"
		if([metaNode objectsForXQuery:@"dc-metadata/*:Identifier[@scheme=\"BKSH\"]/." error:nil] != nil)
			// change the book type to Bookshare
			commonInstance.bookType = BookshareType;

		
		ncxFilename = [self stringForXquery:@"/package/manifest/item[@media-type=\"text/xml\" ] [ends-with(@href,'.ncx')] /data(@href)" ofNode:opfRoot];
			
		// now check for the xml content filename
		xmlContentFilename = [self stringForXquery:@"/package/manifest/item[@media-type=\"text/xml\" ] [ends-with(@href,'.xml')] /data(@href)" ofNode:opfRoot];
	}
	// check for DTB 2005 spec identifier
	else if(YES == [[bookFormatString uppercaseString] isEqualToString:@"ANSI/NISO Z39.86-2005"])
	{
		commonInstance.bookType = DTB2005Type;
		// get the ncx filename
		ncxFilename = [self stringForXquery:@"/package/manifest/item[@media-type=\"application/x-dtbncx+xml\"]/data(@href)" ofNode:opfRoot];
		// get the text content filename
		xmlContentFilename = [self stringForXquery:@"/package/manifest/item[@media-type=\"application/x-dtbook+xml\"]/data(@href)" ofNode:opfRoot];
	}
	else
	{
		// we dont know what type it is so set the unknown type
		commonInstance.bookType = UnknownBookType;
	}
	
	
	// sanity check to see that we know what type of book we are opening
	if(commonInstance.bookType != UnknownBookType)
	{
		// set the book title
		NSString *titleStr = nil;
		titleStr = [self stringForXquery:@"dc-metadata/data(*:Title)" ofNode:metaNode];
		self.commonInstance.bookTitle = (titleStr) ? titleStr : NSLocalizedString(@"No Title", @"no title string"); 
		
		// set the subject
		NSString *subjectStr = nil;
		subjectStr = [self stringForXquery:@"dc-metadata/data(*:Subject)" ofNode:metaNode];
		self.commonInstance.bookSubject =  (subjectStr) ? subjectStr : NSLocalizedString(@"No Subject", @"no subject string");
		
		[commonInstance setMediaFormatFromString:[self stringForXquery:@"//meta[@name=\"dtb:multimediaType\"]/data(@content)" ofNode:metaNode]];
	}
	
	if(ncxFilename != nil)
		isOk = YES;
	
	return isOk;
}


/*
- (void) dealloc
{	
	// cleanup nice
	// check what we may have used
	
	[spine release];
	[manifest release];
	[guide release];
	[tour release];
	[OPFBookTypeString release];
	[OPFMediaFormatString release];
	[bookTitle release];
	[bookSubject release];
	[bookTotalTime release];
	
	[super dealloc];
}
*/

#pragma mark -
#pragma mark Private Methods

- (NSInteger)prevSpinePos
{
	return ((currentPosInSpine - 1) < 0) ?  0 : (currentPosInSpine - 1);
	
}

- (NSInteger)nextSpinePos
{
	NSUInteger newPos = (currentPosInSpine + 1);
	return (newPos == [self.spine count]) ? [self.spine count] : newPos;
	
}

- (NSString *)nextSpineID
{
	NSInteger newPos = [self nextSpinePos];
	if(newPos == currentPosInSpine)
		return nil; // we are at the end of the spine
	
	self.currentPosInSpine = newPos;
	return [spine objectAtIndex:currentPosInSpine];
}

- (NSString *)prevSpineID
{ 
	NSInteger newPos = [self prevSpinePos];
	if(newPos == currentPosInSpine)
		return nil; // we are at the beginning of the spine
	
	self.currentPosInSpine = newPos;
	return [spine objectAtIndex:currentPosInSpine];
}

#pragma mark -
#pragma mark Public Accessors

- (NSString *)nextAudioSegmentFilename
{
	//NSString *spineId;
	// first get the ID reference from the spine
	// check if we are at the first element of the spine
	NSInteger newPos = [self nextSpinePos];
	if(newPos > currentPosInSpine)
	{	
		self.currentPosInSpine = newPos;
		//spineId = [NSString stringWithString:[spine objectAtIndex:currentPosInSpine]];
	
		// check if we got an ID ref back
		//if(spineId != nil)
		//{
			// return the filename from the manifest
			return [self filenameForCurrentSpinePos];
		//}

	}
	
	return nil;

}

- (NSString *)prevAudioSegmentFilename
{
	//NSString *spineId;
	// first get the ID reference from the spine

	NSInteger newPos = [self prevSpinePos];
	if(newPos < currentPosInSpine)
	{	
		self.currentPosInSpine = newPos;
		//spineId = [NSString stringWithString:[spine objectAtIndex:currentPosInSpine]];
	
		// check if we got an 
		//if(spineId != nil)
		//{
			// return the filename from the manifest
			return [self filenameForCurrentSpinePos];
		//}
		
	
	}
	
	return nil;
}


// get the filename for an associated id from the manifest
- (NSString *)filenameForID:(NSString *)anID
{
	return [[manifest objectForKey:anID] objectForKey:@"href"];
}

- (NSString *)filenameForCurrentSpinePos
{
	// a nil value indicates there was no id or filename
	return [self filenameForID:[self.spine objectAtIndex:currentPosInSpine]];
}

#pragma mark -
#pragma mark Private Methods
		
- (NSArray *)processSpineSection:(NSXMLElement *)aRootElement
{
	NSMutableArray * spineContents = nil;
	
	NSArray *spineNodes = [aRootElement nodesForXPath:@"spine" error:nil];
	// check if there is a spine node
	if ([spineNodes count] == 1)
	{
		
		NSArray *spineElements = [[spineNodes objectAtIndex:0] nodesForXPath:@"itemref" error:nil];
		// check if there are some itemref nodes
		if ([spineElements count] > 0)
		{
			spineContents = [[NSMutableArray alloc] init];
			for(NSXMLElement *anElement in spineElements)
			{
				// get the element contained in the node then add its string contents to the temp array
				[spineContents addObject:[[[anElement attributes] objectAtIndex:0] stringValue]];
			}
		}
	}
		
	// return the array which may be nil if there was no spine 
	return spineContents; 
	
}

- (NSDictionary *)processManifestSection:(NSXMLElement *)aRootElement
{
	NSMutableDictionary * manifestContents = nil;
	
	NSArray *manifestNodes = [aRootElement nodesForXPath:@"manifest" error:nil];
	// check if there is a manifest node - there will be only one
	if([manifestNodes count] == 1)
	{
		NSArray *manifestElements = [[manifestNodes objectAtIndex:0] nodesForXPath:@"item" error:nil];
		// check if there are item nodes
		if ([manifestElements count] > 0)
		{
			manifestContents = [[NSMutableDictionary alloc] init];
			for(NSXMLElement *anElement in manifestElements)
			{
				// get the values and keys and add them tou our dictionary 
				NSMutableDictionary *nodeContents = [[NSMutableDictionary alloc] init];
				[nodeContents setValue:[[anElement attributeForName:@"href"] stringValue] forKey:@"href"];
				[nodeContents setValue:[[anElement attributeForName:@"media-type"] stringValue] forKey:@"media-type"];
				[manifestContents setObject:(NSDictionary *)nodeContents forKey:[[anElement attributeForName:@"id"] stringValue]];
			}
		}
	}
	// return the dict which may be nil if there was no manifest 
	return manifestContents;
}


- (NSDictionary *)processGuideSection:(NSXMLElement *)aRootElement
{
	NSMutableDictionary *guideContents = nil;

	NSArray *guideNodes = [aRootElement nodesForXPath:@"guide" error:nil];
	// check if there is a manifest node - there will be only one
	if([guideNodes count] == 1)
	{
		NSArray *guideElements = [[guideNodes objectAtIndex:0] nodesForXPath:@"reference" error:nil];
		// check if there are item nodes
		if ([guideElements count] > 0)
		{
			guideContents = [[NSMutableDictionary alloc] init];
			for(NSXMLElement *anElement in guideElements)
			{
				NSMutableDictionary *nodeContents = [[NSMutableDictionary alloc] init];
				[nodeContents setValue:[[anElement attributeForName:@"type"] stringValue] forKey:@"type"];
				[nodeContents setValue:[[anElement attributeForName:@"href"] stringValue] forKey:@"href"];
				[guideContents setObject:(NSDictionary *)nodeContents forKey:[[anElement attributeForName:@"title"] stringValue]];
			}
		}
	}
	return guideContents;
}

- (NSArray *)processTourSection:(NSXMLElement *)aRootElement
{
	
	NSMutableArray *tourContents = nil;
	
	return tourContents;
}

@synthesize spine,manifest,tour,guide;

@synthesize currentPosInSpine;
@synthesize metaDataNode;

@synthesize ncxFilename, xmlTextContentFilename;



@end

