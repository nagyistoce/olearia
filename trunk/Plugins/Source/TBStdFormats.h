//
//  TBStdFormats.h
//  stdDaisyFormats
//
//  Created by Kieren Eaton on 13/04/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
//
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

#import "TBPluginInterface.h"
#import "TBFileUtils.h"
#import "TBStdInfoView.h"
#import "TBStdTextView.h"
#import "TBBookData.h"

@class TBNavigationController, TBPackageDoc, TBControlDoc;


@interface TBStdFormats : NSObject<TBPluginInterface> 
{
	TBBookData			*bookData;
	TBFileUtils			*fileUtils;
	NSArray				*validFileExtensions;
	
	IBOutlet TBStdInfoView	*infoView;
	IBOutlet TBStdTextView   *textview;

	TBNavigationController	*navCon;
	
	TBPackageDoc			*packageDoc;
	TBControlDoc			*controlDoc;
	
	TBStdFormats			*currentPlugin;

}

- (void)setupPluginSpecifics;
+ (id)bookType;
- (NSXMLNode *)infoMetadataNode;
- (void)chooseCorrectNavControllerForBook;

@property (readonly, retain)	NSArray					*validFileExtensions;
@property (readwrite, assign)	TBBookData				*bookData;

@property (readwrite, retain)	TBNavigationController	*navCon;
@property (readwrite, assign)	TBPackageDoc			*packageDoc;
@property (readwrite, assign)	TBControlDoc			*controlDoc;

@property (readwrite, assign)	TBStdFormats			*currentPlugin;


@end
