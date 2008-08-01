//
//  BBSTBOPFDocument.m
//  BBSTalkingBook
//
//  Created by Kieren Eaton on 15/04/08.
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

#import <Cocoa/Cocoa.h>

#import "BBSTBOPFDocument.h"
#import "BBSTalkingBookTypes.h"

@interface BBSTBOPFDocument ()

@property (readwrite, retain) NSDictionary *manifest; 	
@property (readwrite, retain) NSDictionary *guide;
@property (readwrite, retain) NSArray *spine;
@property (readwrite, retain) NSArray *tour;

@property (readwrite, retain) NSString *bookTitle;
@property (readwrite, retain) NSString *bookSubject;
@property (readwrite, retain) NSString *bookTotalTime;

@property (readwrite, retain) NSString *OPFBookTypeString;
@property (readwrite, retain) NSString *OPFMediaFormatString;

@property (readwrite) NSInteger	currentPosInSpine;

- (NSArray *)processSpineSection:(NSXMLElement *)aRootElement;
- (NSArray *)processTourSection:(NSXMLElement *)aRootElement;
- (NSDictionary *)processManifestSection:(NSXMLElement *)aRootElement;
- (BOOL)processMetadataSection:(NSXMLElement *)aRootElement;
- (NSDictionary *)processGuideSection:(NSXMLElement *)aRootElement;

- (NSInteger)prevSpinePos;
- (NSInteger)nextSpinePos;
- (NSString *)filenameForCurrentSpinePos;
- (NSString *)filenameForID:(NSString *)anID;

@end



@implementation BBSTBOPFDocument

@synthesize spine,manifest,tour,guide;
@synthesize bookTitle,bookTotalTime,bookSubject;
@synthesize OPFBookTypeString, OPFMediaFormatString;
@synthesize currentPosInSpine;

@dynamic bookMediaFormat,bookType;
@dynamic ncxFilename;


- (id)initWithURL:(NSURL *)opfURL
{
	self = [super init];
	if (self != nil) 
	{
		NSError *theError;
		
		// open the validated opf URL
		NSXMLDocument	*xmlOpfDoc = [[NSXMLDocument alloc] initWithContentsOfURL:opfURL options:NSXMLDocumentTidyXML error:&theError];
			
		if(xmlOpfDoc != nil)
		{
				// get the root element of the tree
			NSXMLElement *opfRoot = [xmlOpfDoc rootElement];
			
			
			// check we have any valid metadata before adding the rest.
			if([self processMetadataSection:opfRoot])
			{
				self.manifest = [NSDictionary dictionaryWithDictionary:[self processManifestSection:opfRoot]];
				self.spine = [NSArray arrayWithArray:[self processSpineSection:opfRoot]];
				self.guide = [NSDictionary dictionaryWithDictionary:[self processGuideSection:opfRoot]];
				currentPosInSpine = -1;
			}
			else
			{
				return nil;
			}

		}
		else // we got a nil return so display the error to the user
		{
			NSAlert *theAlert = [NSAlert alertWithError:theError];
			[theAlert runModal]; // ignore return value
			return nil;
		}
		
					
		
	}
	return self;
}

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
	
	currentPosInSpine = newPos;
	return [spine objectAtIndex:currentPosInSpine];
}

- (NSString *)prevSpineID
{ 
	NSInteger newPos = [self prevSpinePos];
	if(newPos == currentPosInSpine)
		return nil; // we are at the beginning of the spine
	
	currentPosInSpine = newPos;
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
		currentPosInSpine = newPos;
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
		currentPosInSpine = newPos;
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

#pragma mark -
#pragma mark Dynamic Accessors

- (TalkingBookType)bookType
{
	TalkingBookType type = UnknownBookType;
	// check the format string
	// DTB 2005 
	if([self.OPFBookTypeString compare:@"ANSI/NISO Z39.86-2005" options:NSCaseInsensitiveSearch] == NSOrderedSame)
		type = DaisyTalkingBook2005Type;
	// DTB 2002
	else if([self.OPFBookTypeString compare:@"ANSI/NISO Z39.86-2002" options:NSCaseInsensitiveSearch] == NSOrderedSame)
		type = DaisyTalkingBook2002Type;
#pragma mark TODO Add more format types and extra checks for bookshare types
	// bookshare types are specified in the identifier string so will need to check there too if dtb format is found.
	
	return type;
}

- (TalkingBookMediaFormat)bookMediaFormat
{
	// set the default
	TalkingBookMediaFormat mediaFormat;
	
	if([self.OPFMediaFormatString compare:@"audioFullText" options:NSCaseInsensitiveSearch] == NSOrderedSame)
		mediaFormat = AudioFullTextMediaFormat;
	else if([self.OPFMediaFormatString compare:@"audioPartText" options:NSCaseInsensitiveSearch] == NSOrderedSame)
		mediaFormat = AudioPartialTextMediaFormat;
	else if([self.OPFMediaFormatString compare:@"audioOnly" options:NSCaseInsensitiveSearch] == NSOrderedSame)
		mediaFormat = AudioOnlyMediaFormat;
	else if([self.OPFMediaFormatString compare:@"audioNCX" options:NSCaseInsensitiveSearch] == NSOrderedSame)
		mediaFormat = AudioNCXMediaFormat;
	else if([self.OPFMediaFormatString compare:@"textPartAudio" options:NSCaseInsensitiveSearch] == NSOrderedSame)
		mediaFormat = TextPartialAudioMediaFormat;
	else if([self.OPFMediaFormatString compare:@"textNCX" options:NSCaseInsensitiveSearch] == NSOrderedSame)
		mediaFormat = TextNCXMediaFormat;
	
	return mediaFormat;
}
// get the name of the ncx file as stored in the manifest
- (NSString *)ncxFilename
{
	// get the ncx filename
	NSString *ncxFile= [NSString stringWithString:[[manifest objectForKey:@"ncx"] objectForKey:@"href"]];
	// check if it wasnt there 
	if(([ncxFile isEqualToString:@""]) || (ncxFile == nil))
		return nil;
	
	return ncxFile;
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

- (BOOL)processMetadataSection:(NSXMLElement *)aRootElement
{
	BOOL validMetadata = NO;
	//NSXMLElement *metaNode = [[aRootElement nodesForXPath:@"metadata" error:nil] objectAtIndex:0];
	//NSLog(@" contents of Metadata : %@",[metaNode dictionaryFromElement]);
	// check that the URI contains a partial oebook  identifier
	// this makes sure that we have the right sort of content despite having the correct OPF extension 
	//NSLog(@" Book URI : %@",[aRootElement URI]);
	if([[aRootElement URI] rangeOfString:@"http://openebook.org/namespaces/oeb-package/" options:NSCaseInsensitiveSearch].length > 0)  
	{
		// we made it past the check so even if the rest of the metadata is empty we still have a valid header
		validMetadata = YES;
		
		NSArray *metadataNodes = [aRootElement nodesForXPath:@"metadata" error:nil];
		// check if there is a manifest node - there will be only one
		if([metadataNodes count] == 1)
		{
			//NSMutableArray *metaContents = [[NSMutableArray alloc] init];
			NSArray *metaElements = [[metadataNodes objectAtIndex:0] children];
			// check if there are item nodes
			if ([metaElements count] > 0)
			{
				for(NSXMLElement *anElement in metaElements)
				{
					NSArray *contents = [anElement children];
					// check which type of metadata we are looking at
					if([[anElement name] compare:@"dc-metadata" options:NSCaseInsensitiveSearch] == NSOrderedSame)
					{
						// iterate through the nodes
						for(NSXMLNode *aNode in contents)
						{
							// check the names of the children and set our class fields as appropriate
							if([[aNode name] compare:@"dc:Format" options:NSCaseInsensitiveSearch] == NSOrderedSame)
								self.OPFBookTypeString = [aNode stringValue];
							else if([[aNode name] compare:@"dc:Title" options:NSCaseInsensitiveSearch] == NSOrderedSame)
								self.bookTitle = [aNode stringValue];
							else if([[aNode name] compare:@"dc:Subject" options:NSCaseInsensitiveSearch] == NSOrderedSame) 
								self.bookSubject = [aNode stringValue];
						}						
					}
					else if([[anElement name] compare:@"x-metadata" options:NSCaseInsensitiveSearch] == NSOrderedSame)
					{
						// iterate through the nodes
						for(NSXMLElement *aNode in contents)
						{
							if([[[aNode attributeForName:@"name"] stringValue] compare:@"dtb:multimediaType" options:NSCaseInsensitiveSearch] == NSOrderedSame)
								self.OPFMediaFormatString = [[aNode attributeForName:@"content"] stringValue];
							if([[[aNode attributeForName:@"name"] stringValue] compare:@"dtb:totalTime" options:NSCaseInsensitiveSearch] == NSOrderedSame)
								self.bookTotalTime = [[aNode attributeForName:@"content"] stringValue];
						}
					}
				}
			}
			
		}
		
	}
	return validMetadata;
}

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
#pragma mark TODO Add extractin of tour content
	NSMutableArray *tourContents = nil;
	
	return tourContents;
}



@end

