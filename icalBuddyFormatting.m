// icalBuddy output formatting functions
// 
// http://hasseg.org/icalBuddy
//

/*
The MIT License

Copyright (c) 2008-2010 Ali Rantakari

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#import "icalBuddyFormatting.h"
#import "HGCLIUtils.h"
#import "icalBuddyDefines.h"

#import "icalBuddyL10N.h"
#import "ANSIEscapeHelper.h"


// default version of the formatting styles dictionary
// that normally is under the "formatting" key in
// configDict (if the user has defined it in the
// configuration file.)
NSDictionary *defaultFormattingConfigDict;

NSDictionary *formattingConfigDict;

ANSIEscapeHelper *ansiEscapeHelper;

// the separator strings between properties in the output
NSArray *propertySeparators;



void initFormatting(NSDictionary *aFormattingConfigDict, NSArray *aPropertySeparators)
{
	ansiEscapeHelper = [[ANSIEscapeHelper alloc] init];
	
	formattingConfigDict = aFormattingConfigDict;
	
	// default formatting for different output elements
	defaultFormattingConfigDict = [NSDictionary dictionaryWithObjectsAndKeys:
		kFormatColorCyan,		@"datetimeName",
		kFormatColorYellow,		@"datetimeValue",
		@"",		 	 		@"titleValue",
		kFormatColorCyan, 	 	@"notesName",
		@"", 		 			@"notesValue",
		kFormatColorCyan, 		@"urlName",
		@"", 			 		@"urlValue",
		kFormatColorCyan, 		@"locationName",
		@"", 		 			@"locationValue",
		kFormatColorCyan, 		@"dueDateName",
		@"", 			 		@"dueDateValue",
		kFormatColorCyan, 	 	@"priorityName",
		@"", 		 			@"priorityValue",
		kFormatColorCyan, 	 	@"uidName",
		@"", 		 			@"uidValue",
		kFormatColorRed,		kFormatKeyPriorityValueHigh,
		kFormatColorYellow,	 	kFormatKeyPriorityValueMedium,
		kFormatColorGreen,		kFormatKeyPriorityValueLow,
		@"", 					kFormatKeySectionTitle,
		kFormatBold,			kFormatKeyFirstItemLine,
		@"", 					kFormatKeyBullet,
		strConcat(kFormatColorRed, @",", kFormatBold, nil),	kFormatKeyAlertBullet,
		kFormatColorBrightBlack,kFormatKeyNoItems,
		nil
		];
	
	propertySeparators = aPropertySeparators;
	if (propertySeparators == nil || [propertySeparators count] == 0)
		propertySeparators = kDefaultPropertySeparators;
}



NSString *ansiEscapedStringWithAttributedString(NSAttributedString *str)
{
	return [ansiEscapeHelper ansiEscapedStringWithAttributedString:str];
}



// returns the closest ANSI color (from the colors used by
// ansiEscapeHelper) to the given color, or nil if the given
// color is nil.
NSColor *getClosestAnsiColorForColor(NSColor *color, BOOL foreground)
{
	if (color == nil)
		return nil;
	
	enum sgrCode closestSGRCode = [ansiEscapeHelper closestSGRCodeForColor:color isForegroundColor:foreground];
	if (closestSGRCode == SGRCodeNoneOrInvalid)
		return nil;
	
	return [ansiEscapeHelper colorForSGRCode:closestSGRCode];
}




// returns a dictionary of attribute name (key) - attribute value (value)
// pairs (suitable for using directly with NSMutableAttributedString's
// attribute setter methods) based on a user-defined formatting specification
// (from the config file, like: "red,bg:blue,bold")
NSMutableDictionary* formattingConfigToStringAttributes(NSString *formattingConfig)
{
	NSMutableDictionary *returnAttributes = [NSMutableDictionary dictionary];
	
	NSArray *parts = [formattingConfig componentsSeparatedByString:@","];
	NSString *part;
	for (part in parts)
	{
		part = [[part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
		
		NSString *thisAttrName = nil;
		NSObject *thisAttrValue = nil;
		
		BOOL isColorAttribute = NO;
		BOOL isBackgroundColor = NO;
		if ([part hasPrefix:kFormatFgColorPrefix] ||
			[part isEqualToString:kFormatColorBlack] ||
			[part isEqualToString:kFormatColorRed] ||
			[part isEqualToString:kFormatColorGreen] ||
			[part isEqualToString:kFormatColorYellow] ||
			[part isEqualToString:kFormatColorBlue] ||
			[part isEqualToString:kFormatColorMagenta] ||
			[part isEqualToString:kFormatColorWhite] ||
			[part isEqualToString:kFormatColorCyan] ||
			[part isEqualToString:kFormatColorBrightBlack] ||
			[part isEqualToString:kFormatColorBrightRed] ||
			[part isEqualToString:kFormatColorBrightGreen] ||
			[part isEqualToString:kFormatColorBrightYellow] ||
			[part isEqualToString:kFormatColorBrightBlue] ||
			[part isEqualToString:kFormatColorBrightMagenta] ||
			[part isEqualToString:kFormatColorBrightWhite] ||
			[part isEqualToString:kFormatColorBrightCyan]
			)
		{
			thisAttrName = NSForegroundColorAttributeName;
			isColorAttribute = YES;
		}
		else if ([part hasPrefix:kFormatBgColorPrefix])
		{
			thisAttrName = NSBackgroundColorAttributeName;
			isColorAttribute = YES;
			isBackgroundColor = YES;
		}
		else if ([part isEqualToString:kFormatBold])
		{
			thisAttrName = NSFontAttributeName;
			thisAttrValue = [[NSFontManager sharedFontManager] convertFont:[ansiEscapeHelper font] toHaveTrait:NSBoldFontMask];
		}
		else if ([part isEqualToString:kFormatUnderlined])
		{
			thisAttrName = NSUnderlineStyleAttributeName;
			thisAttrValue = [NSNumber numberWithInteger:NSUnderlineStyleSingle];
		}
		else if ([part isEqualToString:kFormatDoubleUnderlined])
		{
			thisAttrName = NSUnderlineStyleAttributeName;
			thisAttrValue = [NSNumber numberWithInteger:NSUnderlineStyleDouble];
		}
		else if ([part isEqualToString:kFormatBlink])
		{
			thisAttrName = kBlinkAttributeName;
			thisAttrValue = [NSNumber numberWithBool:YES];
		}
		
		if (isColorAttribute)
		{
			enum sgrCode thisColorSGRCode = SGRCodeNoneOrInvalid;
			if ([part hasSuffix:kFormatColorBrightBlack])
				thisColorSGRCode = SGRCodeFgBrightBlack;
			else if ([part hasSuffix:kFormatColorBrightRed])
				thisColorSGRCode = SGRCodeFgBrightRed;
			else if ([part hasSuffix:kFormatColorBrightGreen])
				thisColorSGRCode = SGRCodeFgBrightGreen;
			else if ([part hasSuffix:kFormatColorBrightYellow])
				thisColorSGRCode = SGRCodeFgBrightYellow;
			else if ([part hasSuffix:kFormatColorBrightBlue])
				thisColorSGRCode = SGRCodeFgBrightBlue;
			else if ([part hasSuffix:kFormatColorBrightMagenta])
				thisColorSGRCode = SGRCodeFgBrightMagenta;
			else if ([part hasSuffix:kFormatColorBrightWhite])
				thisColorSGRCode = SGRCodeFgBrightWhite;
			else if ([part hasSuffix:kFormatColorBrightCyan])
				thisColorSGRCode = SGRCodeFgBrightCyan;
			else if ([part hasSuffix:kFormatColorBlack])
				thisColorSGRCode = SGRCodeFgBlack;
			else if ([part hasSuffix:kFormatColorRed])
				thisColorSGRCode = SGRCodeFgRed;
			else if ([part hasSuffix:kFormatColorGreen])
				thisColorSGRCode = SGRCodeFgGreen;
			else if ([part hasSuffix:kFormatColorYellow])
				thisColorSGRCode = SGRCodeFgYellow;
			else if ([part hasSuffix:kFormatColorBlue])
				thisColorSGRCode = SGRCodeFgBlue;
			else if ([part hasSuffix:kFormatColorMagenta])
				thisColorSGRCode = SGRCodeFgMagenta;
			else if ([part hasSuffix:kFormatColorWhite])
				thisColorSGRCode = SGRCodeFgWhite;
			else if ([part hasSuffix:kFormatColorCyan])
				thisColorSGRCode = SGRCodeFgCyan;
			
			if (thisColorSGRCode != SGRCodeNoneOrInvalid)
			{
				if (isBackgroundColor)
					thisColorSGRCode += 10;
				thisAttrValue = [ansiEscapeHelper colorForSGRCode:thisColorSGRCode];
			}
		}
		
		if (thisAttrName != nil && thisAttrValue != nil)
			[returnAttributes setValue:thisAttrValue forKey:thisAttrName];
	}
	
	return returnAttributes;
}



// insert ANSI escape sequences for custom formatting attributes (e.g. blink,
// which ANSIEscapeHelper doesn't support (with good reason)) into the given
// attributed string
void processCustomStringAttributes(NSMutableAttributedString **aAttributedString)
{
	NSMutableAttributedString *str = *aAttributedString;
	
	if (str == nil)
		return;
	
	
	NSArray *attrNames = [NSArray arrayWithObjects:
						  kBlinkAttributeName,
						  nil
						  ];
	
	NSRange limitRange;
	NSRange effectiveRange;
	id attributeValue;
	
	NSMutableArray *codesAndLocations = [NSMutableArray array];
	
	for (NSString *thisAttrName in attrNames)
	{
		limitRange = NSMakeRange(0, [str length]);
		while (limitRange.length > 0)
		{
			attributeValue = [str
							  attribute:thisAttrName
							  atIndex:limitRange.location
							  longestEffectiveRange:&effectiveRange
							  inRange:limitRange
							  ];
			int thisSGRCode = SGRCodeNoneOrInvalid;
			
			if ([thisAttrName isEqualToString:kBlinkAttributeName])
			{
				thisSGRCode = (attributeValue != nil) ? kSGRCodeBlink : kSGRCodeBlinkReset;
			}
			
			if (thisSGRCode != SGRCodeNoneOrInvalid)
			{
				[codesAndLocations addObject:
					[NSDictionary
					dictionaryWithObjectsAndKeys:
						[NSNumber numberWithInt:thisSGRCode], @"code",
						[NSNumber numberWithUnsignedInteger:effectiveRange.location], @"location",
						nil
						]
					];
			}
			
			limitRange = NSMakeRange(NSMaxRange(effectiveRange),
									 NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
		}
	}
	
	NSUInteger locationOffset = 0;
	for (NSDictionary *dict in codesAndLocations)
	{
		int sgrCode = [[dict objectForKey:@"code"] intValue];
		NSUInteger location = [[dict objectForKey:@"location"] unsignedIntegerValue];
		
		NSAttributedString *ansiStr = ATTR_STR(strConcat(
			kANSIEscapeCSI,
			[NSString stringWithFormat:@"%i", sgrCode],
			kANSIEscapeSGREnd,
			nil));
		
		[str insertAttributedString:ansiStr atIndex:(location+locationOffset)];
		
		locationOffset += [ansiStr length];
	}
}



// return formatting string attributes for specified key
NSDictionary* getStringAttributesForKey(NSString *key)
{
	if (key == nil)
		return [NSDictionary dictionary];
	
	NSString *formattingConfig = nil;
	
	if (formattingConfigDict != nil)
		formattingConfig = [formattingConfigDict objectForKey:key];
	
	if (formattingConfig == nil)
		formattingConfig = [defaultFormattingConfigDict objectForKey:key];
	
	if (formattingConfig != nil)
		return formattingConfigToStringAttributes(formattingConfig);
	
	return [NSDictionary dictionary];
}



// return string attributes for formatting a section title
NSDictionary* getSectionTitleStringAttributes(NSString *sectionTitle)
{
	return getStringAttributesForKey(kFormatKeySectionTitle);
}


// return string attributes for formatting the first printed
// line for a calendar item
NSDictionary* getFirstLineStringAttributes()
{
	return getStringAttributesForKey(kFormatKeyFirstItemLine);
}



// return string attributes for formatting a bullet point
NSDictionary* getBulletStringAttributes(BOOL isAlertBullet)
{
	return getStringAttributesForKey((isAlertBullet) ? kFormatKeyAlertBullet : kFormatKeyBullet);
}


// return string attributes for calendar names printed along
// with title properties
NSDictionary* getCalNameInTitleStringAttributes()
{
	return getStringAttributesForKey(kFormatKeyCalendarNameInTitle);
}


// return string attributes for formatting a property name
NSDictionary* getPropNameStringAttributes(NSString *propName)
{
	if (propName == nil)
		return [NSDictionary dictionary];
	
	NSString *formattingConfigKey = [propName stringByAppendingString:kFormatKeyPropNameSuffix];
	return getStringAttributesForKey(formattingConfigKey);
}


// return string attributes for formatting a property value
NSDictionary* getPropValueStringAttributes(NSString *propName, NSString *propValue)
{
	if (propName == nil)
		return [NSDictionary dictionary];
	
	NSString *formattingConfigKey = [propName stringByAppendingString:kFormatKeyPropValueSuffix];
	
	if (propName == kPropName_priority)
	{
		if (propValue != nil)
		{
			if ([propValue isEqual:localizedStr(kL10nKeyPriorityHigh)])
				formattingConfigKey = kFormatKeyPriorityValueHigh;
			else if ([propValue isEqual:localizedStr(kL10nKeyPriorityMedium)])
				formattingConfigKey = kFormatKeyPriorityValueMedium;
			else if ([propValue isEqual:localizedStr(kL10nKeyPriorityLow)])
				formattingConfigKey = kFormatKeyPriorityValueLow;
		}
	}
	
	return getStringAttributesForKey(formattingConfigKey);
}


// return separator string to prefix a printed property with, based on the
// number of the property (as in: is it the first to be printed (1), the second
// (2) and so on.)
NSString* getPropSeparatorStr(NSUInteger propertyNumber)
{
	NSCAssert((propertySeparators != nil), @"propertySeparators is nil");
	NSCAssert(([propertySeparators count] > 0), @"propertySeparators is empty");
	
	// we subtract two here because the first printed property is always
	// prefixed with a bullet (so we only have propertySeparator prefix
	// strings for properties thereafter -- thus -1) and we want a zero-based
	// index to use for the array access (thus the other -1)
	NSUInteger indexToGet = (propertyNumber >= 2) ? (propertyNumber-2) : 0;
	NSUInteger lastIndex = [propertySeparators count]-1;
	if (indexToGet > lastIndex)
		indexToGet = lastIndex;
	
	return [propertySeparators objectAtIndex:indexToGet];
}






