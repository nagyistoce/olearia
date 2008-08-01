//
//  BBSTBTextDocument.h
//  BBSTalkingBook
//
//  Created by Kieren Eaton on 14/05/08.
//  BrainBender Software. All rights reserved.
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

//#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface BBSTBTextDocument : NSObject 
{
	BOOL			isFullText;
	NSXMLDocument	*textDoc;
	
}



@end
