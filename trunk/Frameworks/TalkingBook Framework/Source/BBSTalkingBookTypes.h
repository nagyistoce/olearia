//
//  BBSTalkingBookTypes.h
//  BBSTalkingBook
//
//  Created by Kieren Eaton on 16/04/08.
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

// document type Names
#define NCX_Document_Type_Name  @"Talking Book Navigation Control Document"
#define OPF_Document_Type_Name @"IDPF Package Document"
#define SMIL_Document_Type_Name @"SMIL Audio Playback Control Document"

#define DTB_Short_Description @"Daisy Talking Book"
#define BOOKSHARE_Short_Description @"Bookshare Talking Book"

#define BBSTBClipBeginKey @"clipBegin"


typedef enum 
{
	DTB2002Type = 20,
	DTB2005Type = 21,
	BookshareType = 22,
	DTBPre2002Type = 30,
	NIMASType = 40,
	UnknownBookType = 99
} TalkingBookType;

typedef enum 
{
	AudioFullTextMediaFormat,
	AudioPartialTextMediaFormat,
	AudioOnlyMediaFormat,
	AudioNCXMediaFormat,
	TextNCXMediaFormat,
	TextPartialAudioMediaFormat,
	TextOnlyMediaFormat,
	unknownMediaFormat = 99
} TalkingBookMediaFormat;

typedef enum
{
	ncxControlDocType = 10,
	bookshareNcxControlDocType = 11,
	nccControlDocType = 20,
	unknownControlDocType = 99
} TalkingBookControlDocType;
