//
//  ANSIEscapeHelper.m
//
//  Created by Ali Rantakari on 18.3.09.
//  Copyright 2009 Ali Rantakari. All rights reserved.
//  
// todo: add license!

/*
 todo:
 
 
 */



#import "ANSIEscapeHelper.h"


// default colors
#define kDefaultANSIColorFgBlack	[NSColor blackColor]
#define kDefaultANSIColorFgRed		[NSColor redColor]
#define kDefaultANSIColorFgGreen	[NSColor greenColor]
#define kDefaultANSIColorFgYellow	[NSColor yellowColor]
#define kDefaultANSIColorFgBlue		[NSColor blueColor]
#define kDefaultANSIColorFgMagenta	[NSColor magentaColor]
#define kDefaultANSIColorFgCyan		[NSColor cyanColor]
#define kDefaultANSIColorFgWhite	[NSColor whiteColor]

#define kDefaultANSIColorBgBlack	[NSColor blackColor]
#define kDefaultANSIColorBgRed		[NSColor redColor]
#define kDefaultANSIColorBgGreen	[NSColor greenColor]
#define kDefaultANSIColorBgYellow	[NSColor yellowColor]
#define kDefaultANSIColorBgBlue		[NSColor blueColor]
#define kDefaultANSIColorBgMagenta	[NSColor magentaColor]
#define kDefaultANSIColorBgCyan		[NSColor cyanColor]
#define kDefaultANSIColorBgWhite	[NSColor whiteColor]

// dictionary keys for the SGR code dictionaries that the array
// escapeCodesForString:cleanString: returns contains
#define kCodeDictKey_code		@"code"
#define kCodeDictKey_location	@"location"

// dictionary keys for the string formatting attribute
// dictionaries that the array attributesForString:cleanString:
// returns contains
#define kAttrDictKey_range			@"range"
#define kAttrDictKey_attrName		@"attributeName"
#define kAttrDictKey_attrValue		@"attributeValue"


@implementation ANSIEscapeHelper

@synthesize font, ansiColors;

- (id) init
{
	self = [super init];
	
	// default font
	self.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	
	// default ANSI colors
	self.ansiColors = [NSMutableDictionary dictionary];
	
	return self;
}



- (NSArray*) escapeCodesForString:(NSString*)aString cleanString:(NSString**)aCleanString
{
	if (aString == nil)
		return nil;
	if ([aString length] <= [kANSIEscapeCSI length])
	{
		*aCleanString = [NSString stringWithString:aString];
		return [NSArray array];
	}
	
	NSString *cleanString = @"";
	
	// find all escape sequence codes from aString and put them in this array
	// along with their start locations within the "clean" version of aString
	NSMutableArray *formatCodes = [NSMutableArray array];
	
	NSUInteger aStringLength = [aString length];
	NSUInteger coveredLength = 0;
	NSRange searchRange = NSMakeRange(0,aStringLength);
	NSRange thisEscapeSequenceRange;
	do
	{
		thisEscapeSequenceRange = [aString rangeOfString:kANSIEscapeCSI options:NSLiteralSearch range:searchRange];
		if (thisEscapeSequenceRange.location != NSNotFound)
		{
			// adjust range's length so that it encompasses the whole ANSI escape sequence
			// and not just the Control Sequence Initiator (the "prefix") by finding the
			// final byte of the control sequence (one that has an ASCII decimal value
			// between 64 and 126.) at the same time, read all formatting codes from inside
			// this escape sequence (there may be several, separated by semicolons.)
			NSMutableArray *codes = [NSMutableArray array];
			unsigned int code = 0;
			unsigned int lengthAddition = 1;
			NSUInteger thisIndex;
			for (;;)
			{
				thisIndex = (thisEscapeSequenceRange.location+thisEscapeSequenceRange.length+lengthAddition-1);
				if (thisIndex >= aStringLength)
					break;
				
				int c = (int)[aString characterAtIndex:thisIndex];
				
				if ((48 <= c) && (c <= 57)) // 0-9
				{
					int digit = c-48;
					code = (code == 0) ? digit : code*10+digit;
				}
				
				// ASCII decimal 109 is the SGR (Select Graphic Rendition) final byte
				// ("m"). this means that the code value we've just read specifies formatting
				// for the output; exactly what we're interested in.
				if (c == 109)
				{
					[codes addObject:[NSNumber numberWithUnsignedInt:code]];
					break;
				}
				else if ((64 <= c) && (c <= 126)) // any other valid final byte
				{
					[codes removeAllObjects];
					break;
				}
				else if (c == 59) // semicolon (;) separates codes within the same sequence
				{
					[codes addObject:[NSNumber numberWithUnsignedInt:code]];
					code = 0;
				}
				
				lengthAddition++;
			}
			thisEscapeSequenceRange.length += lengthAddition;
			
			NSUInteger locationInCleanString = coveredLength+thisEscapeSequenceRange.location-searchRange.location;
			
			NSUInteger iCode;
			for (iCode = 0; iCode < [codes count]; iCode++)
			{
				[formatCodes addObject:
				 [NSDictionary dictionaryWithObjectsAndKeys:
				  [codes objectAtIndex:iCode], kCodeDictKey_code,
				  [NSNumber numberWithUnsignedInteger:locationInCleanString], kCodeDictKey_location,
				  nil
				  ]
				 ];
			}
			
			NSUInteger thisCoveredLength = thisEscapeSequenceRange.location-searchRange.location;
			if (thisCoveredLength > 0)
				cleanString = [cleanString stringByAppendingString:[aString substringWithRange:NSMakeRange(searchRange.location, thisCoveredLength)]];
			
			coveredLength += thisCoveredLength;
			searchRange.location = thisEscapeSequenceRange.location+thisEscapeSequenceRange.length;
			searchRange.length = aStringLength-searchRange.location;
		}
	}
	while(thisEscapeSequenceRange.location != NSNotFound);
	
	if (searchRange.length > 0)
		cleanString = [cleanString stringByAppendingString:[aString substringWithRange:searchRange]];
	
	*aCleanString = cleanString;
	
	return formatCodes;
}




- (NSString*) ansiFormattedStringWithCodesAndLocations:(NSArray*)aCodesArray cleanString:(NSString*)aCleanString
{
	NSString* retStr = @"";
	
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:kCodeDictKey_location ascending:YES] autorelease];
	NSArray *codesArray = [aCodesArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	NSUInteger aCleanStringIndex = 0;
	NSUInteger aCleanStringLength = [aCleanString length];
	NSDictionary *thisCodeDict;
	for (thisCodeDict in codesArray)
	{
		if (!(	[[thisCodeDict allKeys] containsObject:kCodeDictKey_code] &&
				[[thisCodeDict allKeys] containsObject:kCodeDictKey_location]
			))
			continue;
		
		enum sgrCode thisCode = [[thisCodeDict objectForKey:kCodeDictKey_code] unsignedIntValue];
		NSUInteger formattingRunStartLocation = [[thisCodeDict objectForKey:kCodeDictKey_location] unsignedIntegerValue];
		
		if (formattingRunStartLocation > aCleanStringLength)
			continue;
		
		if (aCleanStringIndex < formattingRunStartLocation)
			retStr = [retStr stringByAppendingString:[aCleanString substringWithRange:NSMakeRange(aCleanStringIndex, formattingRunStartLocation-aCleanStringIndex)]];
		retStr = [retStr stringByAppendingString:kANSIEscapeCSI];
		retStr = [retStr stringByAppendingString:[NSString stringWithFormat:@"%d", thisCode]];
		retStr = [retStr stringByAppendingString:kANSIEscapeSGREnd];
		
		aCleanStringIndex = formattingRunStartLocation;
	}
	
	if (aCleanStringIndex < aCleanStringLength)
		retStr = [retStr stringByAppendingString:[aCleanString substringFromIndex:aCleanStringIndex]];
	
	return retStr;
}





- (NSArray*) attributesForString:(NSString*)aString cleanString:(NSString**)aCleanString
{
	if (aString == nil)
		return nil;
	if ([aString length] <= [kANSIEscapeCSI length])
	{
		*aCleanString = [NSString stringWithString:aString];
		return [NSArray array];
	}
	
	NSMutableArray *attrsAndRanges = [NSMutableArray array];
	
	NSString *cleanString;
	
	NSArray *formatCodes = [self escapeCodesForString:aString cleanString:&cleanString];
	
	// go through all the found escape sequence codes and for each one, create
	// the string formatting attribute name and value, find the next escape
	// sequence that specifies the end of the formatting run started by
	// the currently handled code, and generate a range from the difference
	// in those codes' locations within the clean aString.
	NSUInteger iCode;
	for (iCode = 0; iCode < [formatCodes count]; iCode++)
	{
		NSDictionary *thisCodeDict = [formatCodes objectAtIndex:iCode];
		enum sgrCode thisCode = [[thisCodeDict objectForKey:kCodeDictKey_code] unsignedIntValue];
		NSUInteger formattingRunStartLocation = [[thisCodeDict objectForKey:kCodeDictKey_location] unsignedIntegerValue];
		
		// the attributed string attribute name for the formatting run introduced
		// by this code
		NSString *thisAttributeName = nil;
		
		// the attributed string attribute value for this formatting run introduced
		// by this code
		NSObject *thisAttributeValue = nil;
		
		// set attribute name
		switch(thisCode)
		{
			case SGRCodeFgBlack:
			case SGRCodeFgRed:
			case SGRCodeFgGreen:
			case SGRCodeFgYellow:
			case SGRCodeFgBlue:
			case SGRCodeFgMagenta:
			case SGRCodeFgCyan:
			case SGRCodeFgWhite:
				thisAttributeName = NSForegroundColorAttributeName;
				break;
			case SGRCodeBgBlack:
			case SGRCodeBgRed:
			case SGRCodeBgGreen:
			case SGRCodeBgYellow:
			case SGRCodeBgBlue:
			case SGRCodeBgMagenta:
			case SGRCodeBgCyan:
			case SGRCodeBgWhite:
				thisAttributeName = NSBackgroundColorAttributeName;
				break;
			case SGRCodeIntensityBold:
			case SGRCodeIntensityNormal:
				thisAttributeName = NSFontAttributeName;
				break;
			case SGRCodeUnderlineSingle:
			case SGRCodeUnderlineDouble:
				thisAttributeName = NSUnderlineStyleAttributeName;
				break;
			default:
				continue;
				break;
		}
		
		// set attribute value
		switch(thisCode)
		{
			case SGRCodeBgBlack:
			case SGRCodeFgBlack:
			case SGRCodeBgRed:
			case SGRCodeFgRed:
			case SGRCodeBgGreen:
			case SGRCodeFgGreen:
			case SGRCodeBgYellow:
			case SGRCodeFgYellow:
			case SGRCodeBgBlue:
			case SGRCodeFgBlue:
			case SGRCodeBgMagenta:
			case SGRCodeFgMagenta:
			case SGRCodeBgCyan:
			case SGRCodeFgCyan:
			case SGRCodeBgWhite:
			case SGRCodeFgWhite:
				thisAttributeValue = [self colorForSGRCode:thisCode];
				break;
			case SGRCodeIntensityBold:
				{
				NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:self.font toHaveTrait:NSBoldFontMask];
				thisAttributeValue = boldFont;
				}
				break;
			case SGRCodeIntensityNormal:
				{
				NSFont *unboldFont = [[NSFontManager sharedFontManager] convertFont:self.font toHaveTrait:NSUnboldFontMask];
				thisAttributeValue = unboldFont;
				}
				break;
			case SGRCodeUnderlineSingle:
				thisAttributeValue = [NSNumber numberWithInteger:NSUnderlineStyleSingle];
				break;
			case SGRCodeUnderlineDouble:
				thisAttributeValue = [NSNumber numberWithInteger:NSUnderlineStyleDouble];
				break;
			default:
				break;
		}
		
		
		// find the next sequence that specifies the end of this formatting run
		NSInteger formattingRunEndLocation = -1;
		if (iCode < ([formatCodes count]-1))
		{
			NSUInteger iEndCode;
			NSDictionary *thisEndCodeCandidateDict;
			unichar thisEndCodeCandidate;
			for (iEndCode = iCode+1; iEndCode < [formatCodes count]; iEndCode++)
			{
				thisEndCodeCandidateDict = [formatCodes objectAtIndex:iEndCode];
				thisEndCodeCandidate = [[thisEndCodeCandidateDict objectForKey:kCodeDictKey_code] unsignedIntValue];
				
				if ([self sgrCode:thisEndCodeCandidate endsFormattingIntroducedByCode:thisCode])
				{
					formattingRunEndLocation = [[thisEndCodeCandidateDict objectForKey:kCodeDictKey_location] unsignedIntegerValue];
					break;
				}
			}
		}
		if (formattingRunEndLocation == -1)
			formattingRunEndLocation = [aString length];
		
		// add attribute name, attribute value and formatting run range
		// to the array we're going to return
		[attrsAndRanges addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
		  [NSValue valueWithRange:NSMakeRange(formattingRunStartLocation, (formattingRunEndLocation-formattingRunStartLocation))], kAttrDictKey_range,
		  thisAttributeName, kAttrDictKey_attrName,
		  thisAttributeValue, kAttrDictKey_attrValue,
		  nil
		 ]
		];
	}
	
	*aCleanString = cleanString;
	
	return attrsAndRanges;
}





- (BOOL) sgrCode:(enum sgrCode)endCode endsFormattingIntroducedByCode:(enum sgrCode)startCode
{
	switch(startCode)
	{
		case SGRCodeFgBlack:
		case SGRCodeFgRed:
		case SGRCodeFgGreen:
		case SGRCodeFgYellow:
		case SGRCodeFgBlue:
		case SGRCodeFgMagenta:
		case SGRCodeFgCyan:
		case SGRCodeFgWhite:
			return (endCode == SGRCodeAllReset || endCode == SGRCodeFgReset || 
					endCode == SGRCodeFgBlack || endCode == SGRCodeFgRed || 
					endCode == SGRCodeFgGreen || endCode == SGRCodeFgYellow || 
					endCode == SGRCodeFgBlue || endCode == SGRCodeFgMagenta || 
					endCode == SGRCodeFgCyan || endCode == SGRCodeFgWhite);
			break;
		case SGRCodeBgBlack:
		case SGRCodeBgRed:
		case SGRCodeBgGreen:
		case SGRCodeBgYellow:
		case SGRCodeBgBlue:
		case SGRCodeBgMagenta:
		case SGRCodeBgCyan:
		case SGRCodeBgWhite:
			return (endCode == SGRCodeAllReset || endCode == SGRCodeBgReset || 
					endCode == SGRCodeBgBlack || endCode == SGRCodeBgRed || 
					endCode == SGRCodeBgGreen || endCode == SGRCodeBgYellow || 
					endCode == SGRCodeBgBlue || endCode == SGRCodeBgMagenta || 
					endCode == SGRCodeBgCyan || endCode == SGRCodeBgWhite);
			break;
		case SGRCodeIntensityBold:
		case SGRCodeIntensityNormal:
			return (endCode == SGRCodeAllReset || endCode == SGRCodeIntensityNormal || 
					endCode == SGRCodeIntensityBold || endCode == SGRCodeIntensityFaint);
			break;
		case SGRCodeUnderlineSingle:
		case SGRCodeUnderlineDouble:
			return (endCode == SGRCodeAllReset || endCode == SGRCodeUnderlineNone || 
					endCode == SGRCodeUnderlineSingle || endCode == SGRCodeUnderlineDouble);
			break;
		default:
			return NO;
			break;
	}
	
	return NO;
}




- (NSColor*) colorForSGRCode:(enum sgrCode)code
{
	if (self.ansiColors != nil)
	{
		NSColor *preferredColor = [self.ansiColors objectForKey:[NSNumber numberWithInt:code]];
		if (preferredColor != nil)
			return preferredColor;
	}
	
	switch(code)
	{
		case SGRCodeFgBlack:
			return kDefaultANSIColorFgBlack;
			break;
		case SGRCodeFgRed:
			return kDefaultANSIColorFgRed;
			break;
		case SGRCodeFgGreen:
			return kDefaultANSIColorFgGreen;
			break;
		case SGRCodeFgYellow:
			return kDefaultANSIColorFgYellow;
			break;
		case SGRCodeFgBlue:
			return kDefaultANSIColorFgBlue;
			break;
		case SGRCodeFgMagenta:
			return kDefaultANSIColorFgMagenta;
			break;
		case SGRCodeFgCyan:
			return kDefaultANSIColorFgCyan;
			break;
		case SGRCodeFgWhite:
			return kDefaultANSIColorFgWhite;
			break;
		case SGRCodeBgBlack:
			return kDefaultANSIColorBgBlack;
			break;
		case SGRCodeBgRed:
			return kDefaultANSIColorBgRed;
			break;
		case SGRCodeBgGreen:
			return kDefaultANSIColorBgGreen;
			break;
		case SGRCodeBgYellow:
			return kDefaultANSIColorBgYellow;
			break;
		case SGRCodeBgBlue:
			return kDefaultANSIColorBgBlue;
			break;
		case SGRCodeBgMagenta:
			return kDefaultANSIColorBgMagenta;
			break;
		case SGRCodeBgCyan:
			return kDefaultANSIColorBgCyan;
			break;
		case SGRCodeBgWhite:
			return kDefaultANSIColorBgWhite;
			break;
		default:
			break;
	}
	
	return kDefaultANSIColorFgBlack;
}



@end
