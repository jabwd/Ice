//
//  SKProtobufConstants.h
//  Ice
//
//  Created by Antwan van Houdt on 25/10/14.
//  Copyright (c) 2014 Exurion. All rights reserved.
//
//	https://developers.google.com/protocol-buffers/docs/encoding
//

typedef NS_ENUM(UInt8, WireType)
{
	WireTypeVarint		= 0,
	WireTypeFixed32		= 5, // yes... this is actually true
	WireTypeFixed64		= 1,
	WireTypePacked		= 2,
	WireTypeDeprecated1 = 3,
	WireTypeDeprecated2 = 4,
};