// icalBuddy
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


#import <Foundation/Foundation.h>
#import <CalendarStore/CalendarStore.h>
#import <AppKit/AppKit.h>
#import <AddressBook/AddressBook.h>
#import "HGUtils.h"
#import "HGCLIUtils.h"
#import "HGCLIAutoUpdater.h"
#import "HGDateFunctions.h"
#import "IcalBuddyAutoUpdaterDelegate.h"
#import "ANSIEscapeHelper.h"



#define kInternalErrorDomain @"org.hasseg.icalBuddy"

#define kPropertyListEditorAppName @"Property List Editor"

// custom date-formatting specifiers
#define kRelativeWeekFormatSpecifier @"%RW"
#define kDayDiffFormatSpecifier @"%RD"


// property names
#define kPropName_title 	@"title"
#define kPropName_location 	@"location"
#define kPropName_notes 	@"notes"
#define kPropName_url 		@"url"
#define kPropName_datetime 	@"datetime"
#define kPropName_priority 	@"priority"
#define kPropName_UID		@"uid"


// keys for the "sections" dictionary (see printItemSections())
#define kSectionDictKey_title 				@"sectionTitle"
#define kSectionDictKey_items 				@"sectionItems"
#define kSectionDictKey_eventsContextDay 	@"eventsContextDay"


// output formatting configuration keys
#define kFormatKeySectionTitle			@"sectionTitle"
#define kFormatKeyFirstItemLine			@"firstItemLine"
#define kFormatKeyBullet				@"bullet"
#define kFormatKeyAlertBullet			@"alertBullet"
#define kFormatKeyNoItems				@"noItems"
#define kFormatKeyCalendarNameInTitle	@"calendarNameInTitle"
#define kFormatKeyPriorityValueHigh		@"priorityValueHigh"
#define kFormatKeyPriorityValueMedium	@"priorityValueMedium"
#define kFormatKeyPriorityValueLow		@"priorityValueLow"
// the "suffix" definitions below are used like:
//   kPropName_notes + kFormatKeyPropNameSuffix
//   ^-- defines the formatting config key for the
//       "notes" property name
#define kFormatKeyPropNameSuffix		@"Name"
#define kFormatKeyPropValueSuffix		@"Value"


// output formatting parameters
#define kFormatFgColorPrefix		@"fg:"
#define kFormatBgColorPrefix		@"bg:"
#define kFormatDoubleUnderlined		@"double-underlined"
#define kFormatUnderlined			@"underlined"
#define kFormatBold					@"bold"
#define kFormatBlink				@"blink"
#define kFormatColorBlack			@"black"
#define kFormatColorRed				@"red"
#define kFormatColorGreen			@"green"
#define kFormatColorYellow			@"yellow"
#define kFormatColorBlue			@"blue"
#define kFormatColorMagenta			@"magenta"
#define kFormatColorWhite			@"white"
#define kFormatColorCyan			@"cyan"
#define kFormatColorBrightBlack		@"bright-black"
#define kFormatColorBrightRed		@"bright-red"
#define kFormatColorBrightGreen		@"bright-green"
#define kFormatColorBrightYellow	@"bright-yellow"
#define kFormatColorBrightBlue		@"bright-blue"
#define kFormatColorBrightMagenta	@"bright-magenta"
#define kFormatColorBrightWhite		@"bright-white"
#define kFormatColorBrightCyan		@"bright-cyan"

// custom string formatting attribute(s)
#define kBlinkAttributeName			@"blinkAttributeName"
#define kSGRCodeBlink				5
#define kSGRCodeBlinkReset			25

// localization configuration keys
#define kL10nKeyPropNameTitle		kPropName_title
#define kL10nKeyPropNameLocation	kPropName_location
#define kL10nKeyPropNameNotes		kPropName_notes
#define kL10nKeyPropNameUrl			kPropName_url
#define kL10nKeyPropNamePriority	kPropName_priority
#define kL10nKeyPropNameUID			kPropName_UID
#define kL10nKeyPropNameDueDate		@"dueDate"
#define kL10nKeyNoDueDate			@"noDueDate"
#define kL10nKeyToday				@"today"
#define kL10nKeyTomorrow			@"tomorrow"
#define kL10nKeyDayAfterTomorrow	@"dayAfterTomorrow"
#define kL10nKeyYesterday			@"yesterday"
#define kL10nKeyDayBeforeYesterday	@"dayBeforeYesterday"
#define kL10nKeyXDaysAgo			@"xDaysAgo"
#define kL10nKeyXDaysFromNow		@"xDaysFromNow"
#define kL10nKeyLastWeek			@"lastWeek"
#define kL10nKeyThisWeek			@"thisWeek"
#define kL10nKeyNextWeek			@"nextWeek"
#define kL10nKeyXWeeksAgo			@"xWeeksAgo"
#define kL10nKeyXWeeksFromNow		@"xWeeksFromNow"
#define kL10nKeyPriorityHigh 		@"high"
#define kL10nKeyPriorityMedium		@"medium"
#define kL10nKeyPriorityLow			@"low"
#define kL10nKeySomeonesBirthday	@"someonesBirthday"
#define kL10nKeyMyBirthday			@"myBirthday"
#define kL10nKeyDateTimeSeparator	@"dateTimeSeparator"
#define kL10nKeyNoItemsInSection	@"noItems"



// default item property order + list of allowed property names (i.e. these must be in
// the default order and include all of the allowed property names)
#define kDefaultPropertyOrder [NSArray arrayWithObjects:kPropName_title, kPropName_location, kPropName_notes, kPropName_url, kPropName_datetime, kPropName_priority, kPropName_UID, nil]

#define kDefaultPropertySeparators [NSArray arrayWithObjects:@"\n    ", nil]

// localization configuration file path
#define kL10nFilePath @"~/.icalBuddyLocalization.plist"

// general configuration file path
#define kConfigFilePath @"~/.icalBuddyConfig.plist"

// contents for a new configuration file "stub"
#define kConfigFileStub [NSDictionary dictionaryWithObjectsAndKeys:\
						 [NSDictionary dictionary], @"formatting",\
						 nil\
						]





const int VERSION_MAJOR = 1;
const int VERSION_MINOR = 7;
const int VERSION_BUILD = 10;







// printOptions for calendar item printing functions
enum calItemPrintOption
{
	PRINT_OPTION_NONE = 				0,
	PRINT_OPTION_SINGLE_DAY = 			(1 << 0),	// in the contex of a single day (for events) (i.e. don't print out full dates)
	PRINT_OPTION_CALENDAR_AGNOSTIC = 	(1 << 1),	// calendar-agnostic (i.e. don't print out the calendar name)
	PRINT_OPTION_WITHOUT_PROP_NAMES =	(1 << 2),	// without property names (i.e. print only the values)
	PRINT_OPTION_CAL_COLORS_FOR_SECTION_TITLES = (1 << 3)
} CalItemPrintOption;


typedef enum datePrintOption
{
	DATE_PRINT_OPTION_NONE = 	0,
	ONLY_DATE =					(1 << 0),
	ONLY_TIME = 				(1 << 1),
	DATE_AND_TIME =				(1 << 2)
} DatePrintOption;








// the order of properties in the output
NSArray *propertyOrder;

// the separator strings between properties in the output
NSArray *propertySeparators = nil;

// the prefix strings
NSString *prefixStrBullet = 			@"• ";
NSString *prefixStrBulletAlert = 		@"! ";
NSString *sectionSeparatorStr = 		@"\n------------------------";

NSString *timeFormatStr = 				nil;
NSString *dateFormatStr = 				nil;
NSSet *includedEventProperties = 		nil;
NSSet *excludedEventProperties = 		nil;
NSSet *includedTaskProperties = 		nil;
NSSet *excludedTaskProperties = 		nil;
NSString *notesNewlineReplacement =		nil;

BOOL displayRelativeDates = YES;
BOOL excludeEndDates = NO;
BOOL useCalendarColorsForTitles = YES;
BOOL showUIDs = NO;
NSUInteger maxNumPrintedItems = 0; // 0 = no limit
NSUInteger numPrintedItems = 0;


NSDate *now;
NSDate *today;


// dictionary for configuration values
NSMutableDictionary *configDict;

// default version of the formatting styles dictionary
// that normally is under the "formatting" key in
// configDict (if the user has defined it in the
// configuration file.)
NSDictionary *defaultFormattingConfigDict;

// dictionary for localization values
NSDictionary *L10nStringsDict;

// default version of L10nStringsDict
NSDictionary *defaultStringsDict;

// the output buffer string where we add everything we
// want to print out, and right before terminating
// convert to an ANSI-escaped string and push it to
// the standard output. this way we can easily modify
// the formatting of the output right up until the
// last minute.
NSMutableAttributedString *stdoutBuffer;

ANSIEscapeHelper *ansiEscapeHelper;
HGCLIAutoUpdater *autoUpdater;
IcalBuddyAutoUpdaterDelegate *autoUpdaterDelegate;





//-------------------------------------------------------------------
//-------------------------------------------------------------------
// BEGIN: Misc. helper functions


NSString* versionNumberStr()
{
	return [NSString stringWithFormat:@"%d.%d.%d", VERSION_MAJOR, VERSION_MINOR, VERSION_BUILD];
}



// adds the specified attributed string to the output buffer.
void addToOutputBuffer(NSAttributedString *aStr)
{
	[stdoutBuffer appendAttributedString:aStr];
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



// returns localized, human-readable string corresponding to the
// specified localization dictionary key
NSString* localizedStr(NSString *str)
{
	if (str == nil)
		return nil;
	
	if (L10nStringsDict != nil)
	{
		NSString *localizedStr = [L10nStringsDict objectForKey:str];
		if (localizedStr != nil)
			return localizedStr;
	}
	
	NSString *defaultStr = [defaultStringsDict objectForKey:str];
	NSCAssert((defaultStr != nil), @"defaultStr is nil");
	return defaultStr;
}



NSError *internalError(NSInteger code, NSString *description)
{
	return [NSError
		errorWithDomain:kInternalErrorDomain
		code:code
		userInfo:[NSDictionary
			dictionaryWithObject:description
			forKey:NSLocalizedDescriptionKey
			]
		];
}





// sort function for sorting tasks:
// - sort numerically by priority except treat CalPriorityNone (0) as a special case
// - if priorities match, sort tasks that are late from their due date to be first and then
//   order alphabetically by title
NSInteger prioritySort(id task1, id task2, void *context)
{
    if ([task1 priority] < [task2 priority])
	{
		if ([task1 priority] == CalPriorityNone)
			return NSOrderedDescending;
		else
			return NSOrderedAscending;
	}
    else if ([task1 priority] > [task2 priority])
		if ([task2 priority] == CalPriorityNone)
			return NSOrderedAscending;
		else
			return NSOrderedDescending;
    else
	{
		// check if one task is late and the other is not
		BOOL task1late = NO;
		BOOL task2late = NO;
		if ([task1 dueDate] != nil &&
			[now compare:[task1 dueDate]] == NSOrderedDescending
			)
			task1late = YES;
		if ([task2 dueDate] != nil &&
			[now compare:[task2 dueDate]] == NSOrderedDescending
			)
			task2late = YES;
		
		if (task1late && !task2late)
			return NSOrderedAscending;
		else if (task2late && !task1late)
			return NSOrderedDescending;
		
		// neither task is, or both tasks are late -> order alphabetically by title
        return [[task1 title] compare:[task2 title]];
	}
}







// whether propertyName is ok to be printed, based on a set of property
// names to be included and a set of property names to be excluded
BOOL shouldPrintProperty(NSString *propertyName, NSSet *inclusionsSet, NSSet *exclusionsSet)
{
	if (propertyName == kPropName_UID)
		return showUIDs;
	
	if (propertyName == nil || (inclusionsSet == nil && exclusionsSet == nil))
		return YES;
	
	if (inclusionsSet != nil &&
		![inclusionsSet containsObject:propertyName]
		)
		return NO;
	
	if (exclusionsSet != nil &&
		([exclusionsSet containsObject:propertyName] ||
		 ([exclusionsSet containsObject:@"*"] && ![propertyName isEqualToString:kPropName_title])
		 )
		)
		return NO;
	
	return YES;
}






// returns a formatted date+time
NSString* dateStr(NSDate *date, DatePrintOption printOption)
{
	if (date == nil)
		return @"";
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	
	NSString *outputDateStr = nil;
	NSString *outputTimeStr = nil;
	
	BOOL includeDate = (printOption != ONLY_TIME);
	BOOL includeTime = (printOption != ONLY_DATE);
	
	if (includeDate)
	{
		if (displayRelativeDates &&
			datesRepresentSameDay(date, now)
			)
			outputDateStr = localizedStr(kL10nKeyToday);
		else if (displayRelativeDates &&
				datesRepresentSameDay(date, dateByAddingDays(now, 1))
				)
			outputDateStr = localizedStr(kL10nKeyTomorrow);
		else if (displayRelativeDates &&
				datesRepresentSameDay(date, dateByAddingDays(now, 2))
				)
			outputDateStr = localizedStr(kL10nKeyDayAfterTomorrow);
		else if (displayRelativeDates &&
				datesRepresentSameDay(date, dateByAddingDays(now, -1))
				)
			outputDateStr = localizedStr(kL10nKeyYesterday);
		else if (displayRelativeDates &&
				datesRepresentSameDay(date, dateByAddingDays(now, -2))
				)
			outputDateStr = localizedStr(kL10nKeyDayBeforeYesterday);
		else
		{
			NSString *useDateFormatStr = dateFormatStr;
			
			if (useDateFormatStr != nil)
			{
				// use user-specified date format
				
				// implement the "relative week" date format specifier
				NSRange relativeWeekFormatSpecifierRange = [useDateFormatStr rangeOfString:kRelativeWeekFormatSpecifier];
				if (relativeWeekFormatSpecifierRange.location != NSNotFound)
				{
					NSInteger weekDiff = getWeekDiff(now, date);
					if ([now compare:date] == NSOrderedDescending)
						weekDiff *= -1; // in the past
					
					NSString *weekDiffStr = nil;
					if (weekDiff < -1)
						weekDiffStr = [NSString stringWithFormat:localizedStr(kL10nKeyXWeeksAgo), abs(weekDiff)];
					else if (weekDiff == -1)
						weekDiffStr = localizedStr(kL10nKeyLastWeek);
					else if (weekDiff == 0)
						weekDiffStr = localizedStr(kL10nKeyThisWeek);
					else if (weekDiff == 1)
						weekDiffStr = localizedStr(kL10nKeyNextWeek);
					else if (weekDiff > 1)
						weekDiffStr = [NSString stringWithFormat:localizedStr(kL10nKeyXWeeksFromNow), weekDiff];
					
					if (weekDiffStr != nil)
						useDateFormatStr = [useDateFormatStr
							stringByReplacingCharactersInRange:relativeWeekFormatSpecifierRange
							withString:weekDiffStr
							];
				}
				
				// implement the "x days from now" date format specifier
				NSRange dayDiffFormatSpecifierRange = [useDateFormatStr rangeOfString:kDayDiffFormatSpecifier];
				if (dayDiffFormatSpecifierRange.location != NSNotFound)
				{
					NSInteger dayDiff = getDayDiff(now, date);
					
					NSString *dayDiffStr = nil;
					if (dayDiff < -1)
						dayDiffStr = [NSString stringWithFormat:localizedStr(kL10nKeyXDaysAgo), abs(dayDiff)];
					else if (dayDiff == -1)
						dayDiffStr = localizedStr(kL10nKeyYesterday);
					else if (dayDiff == 0)
						dayDiffStr = localizedStr(kL10nKeyToday);
					else if (dayDiff == 1)
						dayDiffStr = localizedStr(kL10nKeyTomorrow);
					else if (dayDiff > 1)
						dayDiffStr = [NSString stringWithFormat:localizedStr(kL10nKeyXDaysFromNow), dayDiff];
					
					if (dayDiffStr != nil)
						useDateFormatStr = [useDateFormatStr
							stringByReplacingCharactersInRange:dayDiffFormatSpecifierRange
							withString:dayDiffStr
							];
				}
				
				outputDateStr = [date
					descriptionWithCalendarFormat:useDateFormatStr
					timeZone:nil
					locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
					];
			}
			else
			{
				// use date formats from system preferences
				
				[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
				[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
				outputDateStr = [dateFormatter stringFromDate:date];
			}
		}
	}
	
	if (includeTime)
	{
		if (timeFormatStr != nil)
		{
			// use user-specified time format
			outputTimeStr = [date
				descriptionWithCalendarFormat:timeFormatStr
				timeZone:nil
				locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
				];
		}
		else
		{
			// use time formats from system preferences
			
			[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
			[dateFormatter setDateStyle:NSDateFormatterNoStyle];
			outputTimeStr = [dateFormatter stringFromDate:date];
		}
	}
	
	if ([outputDateStr length] == 0)
		outputDateStr = nil;
	if ([outputTimeStr length] == 0)
		outputTimeStr = nil;
	
	if (outputDateStr == nil && outputTimeStr == nil)
		return @"";
	else if (outputDateStr != nil && outputTimeStr == nil)
		return outputDateStr;
	else if (outputDateStr == nil && outputTimeStr != nil)
		return outputTimeStr;
	else
		return strConcat(outputDateStr, localizedStr(kL10nKeyDateTimeSeparator), outputTimeStr, nil);
}








//-------------------------------------------------------------------
//-------------------------------------------------------------------
// BEGIN: Functions for formatting the output


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
	
	if (configDict != nil)
	{
		NSDictionary *formattingConfigDict = [configDict objectForKey:@"formatting"];
		if (formattingConfigDict != nil)
			formattingConfig = [formattingConfigDict objectForKey:key];
	}
	
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








//-------------------------------------------------------------------
//-------------------------------------------------------------------
// BEGIN: Functions for pretty-printing data


// returns a pretty-printed string representation of the specified event property
NSMutableAttributedString* getEventPropStr(NSString *propName, CalEvent *event, int printOptions, NSDate *contextDay)
{
	if (event == nil)
		return nil;
	
	NSMutableAttributedString *thisPropOutputName = nil;
	NSMutableAttributedString *thisPropOutputValue = nil;
	NSMutableAttributedString *thisPropOutputValueSuffix = nil;
	
	if ([propName isEqualToString:kPropName_title])
	{
		NSString *thisPropTempValue = nil;
		
		if ([[[event calendar] type] isEqualToString:CalCalendarTypeBirthday])
		{
			// special case for events in the Birthdays calendar (they don't seem to have titles
			// so we have to use the URI to find the ABPerson from the Address Book
			// and print their name from there)
			
			NSString *personId = [[NSString stringWithFormat:@"%@", [event url]]
				stringByReplacingOccurrencesOfString:@"addressbook://"
				withString:@""
				];
			ABRecord *person = [[ABAddressBook sharedAddressBook] recordForUniqueId:personId];
			
			if (person != nil)
			{
				if ([person isMemberOfClass: [ABPerson class]])
				{
					NSString *thisTitle;
					if ([person isEqual:[[ABAddressBook sharedAddressBook] me]])
						thisTitle = localizedStr(kL10nKeyMyBirthday);
					else
					{
						NSString *contactFullName = strConcat(
							[person valueForProperty:kABFirstNameProperty],
							@" ",
							[person valueForProperty:kABLastNameProperty],
							nil
							);
						thisTitle = [NSString stringWithFormat:localizedStr(kL10nKeySomeonesBirthday), contactFullName];
					}
					thisPropTempValue = thisTitle;
				}
			}
		}
		else
			thisPropTempValue = [event title];
		
		thisPropOutputValue = M_ATTR_STR(thisPropTempValue);
		
		if (!(printOptions & PRINT_OPTION_CALENDAR_AGNOSTIC))
		{
			thisPropOutputValueSuffix = M_ATTR_STR(@" ");
			[thisPropOutputValueSuffix
				appendAttributedString: mutableAttrStrWithAttrs(
					strConcat(@"(", [[event calendar] title], @")", nil),
					getCalNameInTitleStringAttributes()
					)
				];
		}
	}
	else if ([propName isEqualToString:kPropName_location])
	{
		thisPropOutputName = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameLocation), @":", nil));
		
		if ([event location] != nil &&
			![[[event location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]
			)
			thisPropOutputValue = M_ATTR_STR([event location]);
	}
	else if ([propName isEqualToString:kPropName_notes])
	{
		thisPropOutputName = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameNotes), @":", nil));
		
		if ([event notes] != nil &&
			![[[event notes] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]
			)
		{
			NSString *thisNewlineReplacement;
			if (notesNewlineReplacement == nil)
			{
				NSInteger thisNewlinesIndentModifier = [thisPropOutputName length]+1;
				thisNewlineReplacement = [NSString
					stringWithFormat:@"\n%@",
						WHITESPACE(thisNewlinesIndentModifier)
					];
			}
			else
				thisNewlineReplacement = notesNewlineReplacement;
			
			thisPropOutputValue = M_ATTR_STR(
				[[event notes]
					stringByReplacingOccurrencesOfString:@"\n"
					withString:thisNewlineReplacement
					]
				);
		}
	}
	else if ([propName isEqualToString:kPropName_url])
	{
		thisPropOutputName = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameUrl), @":", nil));
		
		if ([event url] != nil &&
			![[[event calendar] type] isEqualToString:CalCalendarTypeBirthday]
			)
			thisPropOutputValue = M_ATTR_STR(([NSString stringWithFormat: @"%@", [event url]]));
	}
	else if ([propName isEqualToString:kPropName_UID])
	{
		thisPropOutputName = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameUID), @":", nil));
		thisPropOutputValue = M_ATTR_STR([event uid]);
	}
	else if ([propName isEqualToString:kPropName_datetime])
	{
		if ([[[event calendar] type] isEqualToString:CalCalendarTypeBirthday])
		{
			if (!(printOptions & PRINT_OPTION_SINGLE_DAY))
				thisPropOutputValue = M_ATTR_STR(dateStr([event startDate], ONLY_DATE));
		}
		else
		{
			// TODO:
			// fix the convoluted control flow here.
			// should probably determine the start and end datetime strings
			// first (i.e. make them "..." if singleDayContext and the event
			// doesn't start or end on context day) and then combine them together
			// based on what we want to display.
			
			BOOL singleDayContext = (printOptions & PRINT_OPTION_SINGLE_DAY);
			BOOL startsOnContextDay = NO;
			BOOL endsOnContextDay = NO;
			if (contextDay != nil)
			{
				startsOnContextDay = datesRepresentSameDay(contextDay, [event startDate]);
				endsOnContextDay = datesRepresentSameDay(contextDay, [event endDate]);
			}
			
			if ( !singleDayContext || (singleDayContext && ![event isAllDay]) )
			{
				if (excludeEndDates || [[event startDate] isEqualToDate:[event endDate]])
				{
					// -> we only want to show the start datetime
					
					if (singleDayContext && !startsOnContextDay)
						thisPropOutputValue = M_ATTR_STR(@"...");
					else
					{
						DatePrintOption datePrintOpt = DATE_PRINT_OPTION_NONE;
						BOOL printDate = !singleDayContext;
						BOOL printTime = ![event isAllDay];
						
						if (printDate && printTime)
							datePrintOpt = DATE_AND_TIME;
						else if (printDate)
							datePrintOpt = ONLY_DATE;
						else if (printTime)
							datePrintOpt = ONLY_TIME;
						
						if (datePrintOpt != DATE_PRINT_OPTION_NONE)
							thisPropOutputValue = M_ATTR_STR(
								dateStr([event startDate], datePrintOpt)
								);
					}
				}
				else
				{
					if (singleDayContext)
					{
						if (startsOnContextDay && endsOnContextDay)
							thisPropOutputValue = M_ATTR_STR((
								strConcat(
									dateStr([event startDate], ONLY_TIME),
									@" - ",
									dateStr([event endDate], ONLY_TIME),
									nil
									)
								));
						else if (startsOnContextDay)
							thisPropOutputValue = M_ATTR_STR((
								strConcat(dateStr([event startDate], ONLY_TIME), @" - ...", nil)
								));
						else if (endsOnContextDay)
							thisPropOutputValue = M_ATTR_STR((
								strConcat(@"... - ", dateStr([event endDate], ONLY_TIME), nil)
								));
						else
							thisPropOutputValue = M_ATTR_STR(@"... - ...");
					}
					else
					{
						if ([event isAllDay])
						{
							// all-day events technically span from <start day> at 00:00 to <end day+1> at 00:00 even though
							// we want them displayed as only spanning from <start day> to <end day>
							NSDate *endDateMinusOneDay = dateByAddingDays([event endDate], -1);
							NSInteger daysDiff = getDayDiff([event startDate], endDateMinusOneDay);
							
							if (daysDiff > 0)
							{
								thisPropOutputValue = M_ATTR_STR((
									strConcat(
										dateStr([event startDate], ONLY_DATE),
										@" - ",
										dateStr(endDateMinusOneDay, ONLY_DATE),
										nil
										)
									));
							}
							else
								thisPropOutputValue = M_ATTR_STR(dateStr([event startDate], ONLY_DATE));
						}
						else
						{
							NSString *startDateFormattedStr = dateStr([event startDate], DATE_AND_TIME);
							
							DatePrintOption datePrintOpt = datesRepresentSameDay([event startDate], [event endDate]) ? ONLY_TIME : DATE_AND_TIME;
							NSString *endDateFormattedStr = dateStr([event endDate], datePrintOpt);
							
							thisPropOutputValue = M_ATTR_STR(strConcat(startDateFormattedStr, @" - ", endDateFormattedStr, nil));
						}
					}
				}
			}
		}
	}
	
	if (thisPropOutputValue == nil)
		return nil;
	
	if (thisPropOutputName != nil)
	{
		[thisPropOutputName
			setAttributes:getPropNameStringAttributes(propName)
			range:NSMakeRange(0, [thisPropOutputName length])
			];
	}
	
	[thisPropOutputValue
		setAttributes:getPropValueStringAttributes(propName, [thisPropOutputValue string])
		range:NSMakeRange(0, [thisPropOutputValue length])
		];
	
	// if no foreground color for title, use calendar color by default
	if ([propName isEqualToString:kPropName_title]
		&& useCalendarColorsForTitles
		&& ![[[thisPropOutputValue attributesAtIndex:0 effectiveRange:NULL] allKeys] containsObject:NSForegroundColorAttributeName]
		)
		[thisPropOutputValue
			addAttribute:NSForegroundColorAttributeName
			value:getClosestAnsiColorForColor([[event calendar] color], YES)
			range:NSMakeRange(0, [thisPropOutputValue length])
			];
	
	if (thisPropOutputValueSuffix != nil)
		[thisPropOutputValue appendAttributedString:thisPropOutputValueSuffix];
	
	NSMutableAttributedString *retVal = kEmptyMutableAttributedString;
	
	if (thisPropOutputName != nil && !(printOptions & PRINT_OPTION_WITHOUT_PROP_NAMES))
	{
		[thisPropOutputName appendAttributedString:ATTR_STR(@" ")];
		[retVal appendAttributedString:thisPropOutputName];
	}
	
	[retVal appendAttributedString:thisPropOutputValue];
	
	return retVal;
}




// pretty-prints out the specified event
void printCalEvent(CalEvent *event, int printOptions, NSDate *contextDay)
{
	if (maxNumPrintedItems > 0 && maxNumPrintedItems <= numPrintedItems)
		return;
	
	if (event != nil)
	{
		NSUInteger numPrintedProps = 0;
		
		for (NSString *thisProp in propertyOrder)
		{
			if (!shouldPrintProperty(thisProp, includedEventProperties, excludedEventProperties))
				continue;
			
			NSMutableAttributedString *thisPropStr = getEventPropStr(thisProp, event, printOptions, contextDay);
			if (thisPropStr == nil || [thisPropStr length] <= 0)
				continue;
			
			NSMutableAttributedString *prefixStr;
			if (numPrintedProps == 0)
				prefixStr = mutableAttrStrWithAttrs(prefixStrBullet, getBulletStringAttributes(NO));
			else
				prefixStr = M_ATTR_STR(getPropSeparatorStr(numPrintedProps+1));
			
			// if prefixStr contains at least one newline, prefix all newlines in thisPropStr
			// with a number of whitespace characters ("indentation") that matches the
			// length of prefixStr's contents after the last newline
			NSRange prefixStrLastNewlineRange = [[prefixStr string]
				rangeOfString:@"\n"
				options:(NSLiteralSearch|NSBackwardsSearch)
				range:NSMakeRange(0,[prefixStr length])
				];
			if (prefixStrLastNewlineRange.location != NSNotFound)
			{
				replaceInMutableAttrStr(
					thisPropStr,
					@"\n",
					ATTR_STR(
						strConcat(
							@"\n",
							WHITESPACE([prefixStr length]-NSMaxRange(prefixStrLastNewlineRange)),
							nil
							)
						)
					);
			}
			
			NSMutableAttributedString *thisOutput = kEmptyMutableAttributedString;
			[thisOutput appendAttributedString:prefixStr];
			[thisOutput appendAttributedString:thisPropStr];
			
			if (numPrintedProps == 0)
				[thisOutput
					addAttributes:getFirstLineStringAttributes()
					range:NSMakeRange(0,[thisOutput length])
					];
			
			addToOutputBuffer(thisOutput);
			
			numPrintedProps++;
		}
		
		if (numPrintedProps > 0)
			addToOutputBuffer(M_ATTR_STR(@"\n"));
		
		numPrintedItems++;
	}
}










// returns a pretty-printed string representation of the specified task property
NSMutableAttributedString* getTaskPropStr(NSString *propName, CalTask *task, int printOptions)
{
	if (task == nil)
		return nil;
	
	NSMutableAttributedString *thisPropOutputName = nil;
	NSMutableAttributedString *thisPropOutputValue = nil;
	NSMutableAttributedString *thisPropOutputValueSuffix = nil;
	
	if ([propName isEqualToString:kPropName_title])
	{
		thisPropOutputValue = M_ATTR_STR([task title]);
		
		if (!(printOptions & PRINT_OPTION_CALENDAR_AGNOSTIC))
		{
			thisPropOutputValueSuffix = M_ATTR_STR(@" ");
			[thisPropOutputValueSuffix
				appendAttributedString: mutableAttrStrWithAttrs(
					strConcat(@"(", [[task calendar] title], @")", nil),
					getCalNameInTitleStringAttributes()
					)
				];
		}
	}
	else if ([propName isEqualToString:kPropName_notes])
	{
		thisPropOutputName = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameNotes), @":", nil));
		
		if ([task notes] != nil &&
			![[[task notes] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]
			)
		{
			NSString *thisNewlineReplacement;
			if (notesNewlineReplacement == nil)
			{
				NSInteger thisNewlinesIndentModifier = [thisPropOutputName length]+1;
				thisNewlineReplacement = [NSString
					stringWithFormat:@"\n%@",
						WHITESPACE(thisNewlinesIndentModifier)
					];
			}
			else
				thisNewlineReplacement = notesNewlineReplacement;
			
			thisPropOutputValue = M_ATTR_STR((
				[[task notes]
					stringByReplacingOccurrencesOfString:@"\n"
					withString:thisNewlineReplacement
					]
				));
		}
	}
	else if ([propName isEqualToString:kPropName_url])
	{
		thisPropOutputName = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameUrl), @":", nil));
		
		if ([task url] != nil)
			thisPropOutputValue = M_ATTR_STR(([NSString stringWithFormat:@"%@", [task url]]));
	}
	else if ([propName isEqualToString:kPropName_UID])
	{
		thisPropOutputName = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameUID), @":", nil));
		thisPropOutputValue = M_ATTR_STR([task uid]);
	}
	else if ([propName isEqualToString:kPropName_datetime])
	{
		thisPropOutputName = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameDueDate), @":", nil));
		
		if ([task dueDate] != nil && !(printOptions & PRINT_OPTION_SINGLE_DAY))
			thisPropOutputValue = M_ATTR_STR(dateStr([task dueDate], ONLY_DATE));
	}
	else if ([propName isEqualToString:kPropName_priority])
	{
		thisPropOutputName = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNamePriority), @":", nil));
		
		if ([task priority] != CalPriorityNone)
		{
			switch([task priority])
			{
				case CalPriorityHigh:
					thisPropOutputValue = M_ATTR_STR(localizedStr(kL10nKeyPriorityHigh));
					break;
				case CalPriorityMedium:
					thisPropOutputValue = M_ATTR_STR(localizedStr(kL10nKeyPriorityMedium));
					break;
				case CalPriorityLow:
					thisPropOutputValue = M_ATTR_STR(localizedStr(kL10nKeyPriorityLow));
					break;
				default:
					thisPropOutputValue = M_ATTR_STR(([NSString stringWithFormat:@"%d", [task priority]]));
					break;
			}
		}
	}
	
	if (thisPropOutputValue == nil)
		return nil;
	
	if (thisPropOutputName != nil)
	{
		[thisPropOutputName
			setAttributes:getPropNameStringAttributes(propName)
			range:NSMakeRange(0, [thisPropOutputName length])
			];
	}
	
	[thisPropOutputValue
		setAttributes:getPropValueStringAttributes(propName, [thisPropOutputValue string])
		range:NSMakeRange(0, [thisPropOutputValue length])
		];
	
	// if no foreground color for title, use calendar color by default
	if ([propName isEqualToString:kPropName_title]
		&& useCalendarColorsForTitles
		&& ![[[thisPropOutputValue attributesAtIndex:0 effectiveRange:NULL] allKeys] containsObject:NSForegroundColorAttributeName]
		)
		[thisPropOutputValue
			addAttribute:NSForegroundColorAttributeName
			value:getClosestAnsiColorForColor([[task calendar] color], YES)
			range:NSMakeRange(0, [thisPropOutputValue length])
			];
	
	if (thisPropOutputValueSuffix != nil)
		[thisPropOutputValue appendAttributedString:thisPropOutputValueSuffix];
	
	NSMutableAttributedString *retVal = kEmptyMutableAttributedString;
	
	if (thisPropOutputName != nil && !(printOptions & PRINT_OPTION_WITHOUT_PROP_NAMES))
	{
		[thisPropOutputName appendAttributedString:ATTR_STR(@" ")];
		[retVal appendAttributedString:thisPropOutputName];
	}
	
	[retVal appendAttributedString:thisPropOutputValue];
	
	return retVal;
}




// pretty-prints out the specified task
void printCalTask(CalTask *task, int printOptions)
{
	if (maxNumPrintedItems > 0 && maxNumPrintedItems <= numPrintedItems)
		return;
	
	if (task != nil)
	{
		NSUInteger numPrintedProps = 0;
		
		for (NSString *thisProp in propertyOrder)
		{
			if (!shouldPrintProperty(thisProp, includedTaskProperties, excludedTaskProperties))
				continue;
			
			NSMutableAttributedString *thisPropStr = getTaskPropStr(thisProp, task, printOptions);
			if (thisPropStr == nil || [thisPropStr length] <= 0)
				continue;
			
			NSMutableAttributedString *prefixStr;
			if (numPrintedProps == 0)
			{
				BOOL useAlertBullet = 	([task dueDate] != nil &&
										 [now compare:[task dueDate]] == NSOrderedDescending);
				prefixStr = mutableAttrStrWithAttrs(
					((useAlertBullet)?prefixStrBulletAlert:prefixStrBullet),
					getBulletStringAttributes(useAlertBullet)
					);
			}
			else
				prefixStr = M_ATTR_STR(getPropSeparatorStr(numPrintedProps+1));
			
			// if prefixStr contains at least one newline, prefix all newlines in thisPropStr
			// with a number of whitespace characters ("indentation") that matches the
			// length of prefixStr's contents after the last newline
			NSRange prefixStrLastNewlineRange = [[prefixStr string]
				rangeOfString:@"\n"
				options:(NSLiteralSearch|NSBackwardsSearch)
				range:NSMakeRange(0,[prefixStr length])
				];
			if (prefixStrLastNewlineRange.location != NSNotFound)
			{
				replaceInMutableAttrStr(
					thisPropStr,
					@"\n",
					ATTR_STR(
						strConcat(
							@"\n",
							WHITESPACE([prefixStr length]-NSMaxRange(prefixStrLastNewlineRange)),
							nil
							)
						)
					);
			}
			
			NSMutableAttributedString *thisOutput = kEmptyMutableAttributedString;
			[thisOutput appendAttributedString:prefixStr];
			[thisOutput appendAttributedString:thisPropStr];
			
			if (numPrintedProps == 0)
				[thisOutput
					addAttributes:getFirstLineStringAttributes()
					range:NSMakeRange(0,[thisOutput length])
					];
			
			addToOutputBuffer(thisOutput);
			
			numPrintedProps++;
		}
		
		if (numPrintedProps > 0)
			addToOutputBuffer(M_ATTR_STR(@"\n"));
		
		numPrintedItems++;
	}
}





// prints a bunch of sections each of which has a title and some calendar
// items.
// each object in the sections array must be an NSDictionary with keys
// sectionTitle (NSString) and sectionItems (NSArray of CalCalendarItems.)
void printItemSections(NSArray *sections, int printOptions)
{
	BOOL currentIsFirstPrintedSection = YES;
	
	NSDictionary *sectionDict;
	for (sectionDict in sections)
	{
		if (maxNumPrintedItems > 0 && maxNumPrintedItems <= numPrintedItems)
			continue;
		
		NSArray *sectionItems = [sectionDict objectForKey:kSectionDictKey_items];
		
		// print section title
		NSString *sectionTitle = [sectionDict objectForKey:kSectionDictKey_title];
		if (!currentIsFirstPrintedSection)
			addToOutputBuffer(M_ATTR_STR(@"\n"));
		NSMutableAttributedString *thisOutput = M_ATTR_STR(
			strConcat(sectionTitle, @":", sectionSeparatorStr, nil)
			);
		[thisOutput
			addAttributes:getSectionTitleStringAttributes(sectionTitle)
			range:NSMakeRange(0,[thisOutput length])
			];
		
		// if the section title has no foreground color and we're told to
		// use calendar colors for them, do so
		if ((printOptions & PRINT_OPTION_CAL_COLORS_FOR_SECTION_TITLES)
			&& useCalendarColorsForTitles
			&& ![[[thisOutput attributesAtIndex:0 effectiveRange:NULL] allKeys] containsObject:NSForegroundColorAttributeName]
			&& sectionItems != nil && [sectionItems count] > 0
			)
		{
			[thisOutput
				addAttribute:NSForegroundColorAttributeName
				value:getClosestAnsiColorForColor([[((CalCalendarItem *)[sectionItems objectAtIndex:0]) calendar] color], YES)
				range:NSMakeRange(0, [thisOutput length])
				];
		}
		
		addToOutputBuffer(thisOutput);
		addToOutputBuffer(M_ATTR_STR(@"\n"));
		currentIsFirstPrintedSection = NO;
		
		if (sectionItems == nil || [sectionItems count] == 0)
		{
			// print the "no items" text
			NSMutableAttributedString *noItemsTextOutput = M_ATTR_STR(
				strConcat(localizedStr(kL10nKeyNoItemsInSection), @"\n", nil)
				);
			[noItemsTextOutput
				addAttributes:getStringAttributesForKey(kFormatKeyNoItems)
				range:NSMakeRange(0,[noItemsTextOutput length])
				];
			addToOutputBuffer(noItemsTextOutput);
			continue;
		}
		
		// print items in section
		for (CalCalendarItem *item in sectionItems)
		{
			if ([item isKindOfClass:[CalEvent class]])
			{
				NSDate *contextDay = [sectionDict objectForKey:kSectionDictKey_eventsContextDay];
				if (contextDay == nil)
					contextDay = now;
				printCalEvent((CalEvent*)item, printOptions, contextDay);
			}
			else if ([item isKindOfClass:[CalTask class]])
				printCalTask((CalTask*)item, printOptions);
		}
	}
}










NSMutableArray *filterCalendars(NSMutableArray *cals, NSArray *includeCals, NSArray *excludeCals)
{
	if (includeCals != nil)
		[cals filterUsingPredicate:[NSPredicate predicateWithFormat:@"(uid IN %@) OR (title IN %@)", includeCals, includeCals]];
	if (excludeCals != nil)
		[cals filterUsingPredicate:[NSPredicate predicateWithFormat:@"(NOT(uid IN %@)) AND (NOT(title IN %@))", excludeCals, excludeCals]];
	return cals;
}
















int main(int argc, char *argv[])
{
	NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
	
	
	stdoutBuffer = kEmptyMutableAttributedString;
	
	
	// set current datetime and day representations into globals
	now = [NSDate date];
	today = dateForStartOfDay(now);
	
	
	ansiEscapeHelper = [[ANSIEscapeHelper alloc] init];
	
	autoUpdater = [[HGCLIAutoUpdater alloc]
		initWithAppName:@"icalBuddy"
		currentVersionStr:versionNumberStr()
		];
	autoUpdaterDelegate = [[IcalBuddyAutoUpdaterDelegate alloc] init];
	autoUpdater.delegate = autoUpdaterDelegate;
	
	
	// default localization strings (english)
	defaultStringsDict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"title",			kL10nKeyPropNameTitle,
		@"location",		kL10nKeyPropNameLocation,
		@"notes", 			kL10nKeyPropNameNotes,
		@"url", 			kL10nKeyPropNameUrl,
		@"uid",				kL10nKeyPropNameUID,
		@"due",		 		kL10nKeyPropNameDueDate,
		@"no due date",		kL10nKeyNoDueDate,
		@"priority", 		kL10nKeyPropNamePriority,
		@"%@'s Birthday",	kL10nKeySomeonesBirthday,
		@"My Birthday",		kL10nKeyMyBirthday,
		@"today", 					kL10nKeyToday,
		@"tomorrow", 				kL10nKeyTomorrow,
		@"yesterday", 				kL10nKeyYesterday,
		@"day before yesterday",	kL10nKeyDayBeforeYesterday,
		@"day after tomorrow",		kL10nKeyDayAfterTomorrow,
		@"%d days ago",				kL10nKeyXDaysAgo,
		@"%d days from now",		kL10nKeyXDaysFromNow,
		@"this week",				kL10nKeyThisWeek,
		@"last week",				kL10nKeyLastWeek,
		@"next week",				kL10nKeyNextWeek,
		@"%d weeks ago",			kL10nKeyXWeeksAgo,
		@"%d weeks from now",		kL10nKeyXWeeksFromNow,
		@"high",		kL10nKeyPriorityHigh,
		@"medium",		kL10nKeyPriorityMedium,
		@"low",			kL10nKeyPriorityLow,
		@" at ",		kL10nKeyDateTimeSeparator,
		@"Nothing.",	kL10nKeyNoItemsInSection,
		nil
		];
	
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
	
	
	// variables for arguments
	NSString *arg_output = nil;
	BOOL arg_separateByCalendar = NO;
	BOOL arg_separateByDate = NO;
	NSArray *arg_includeCals = nil;
	NSArray *arg_excludeCals = nil;
	BOOL arg_updatesCheck = NO;
	BOOL arg_printVersion = NO;
	BOOL arg_includeOnlyEventsFromNowOn = NO;
	BOOL arg_useFormatting = NO;
	BOOL arg_noCalendarNames = NO;
	BOOL arg_sortTasksByDueDate = NO;
	BOOL arg_sortTasksByDueDateAscending = NO;
	BOOL arg_sectionsForEachDayInSpan = NO;
	BOOL arg_noPropNames = NO;
	NSString *arg_strEncoding = nil;
	NSString *arg_propertyOrderStr = nil;
	NSString *arg_propertySeparatorsStr = nil;
	
	BOOL arg_output_is_uncompletedTasks = NO;
	BOOL arg_output_is_eventsToday = NO;
	BOOL arg_output_is_eventsNow = NO;
	BOOL arg_output_is_eventsFromTo = NO;
	BOOL arg_output_is_tasksDueBefore = NO;
	NSString *arg_eventsFrom = nil;
	NSString *arg_eventsTo = nil;
	
	
	
	NSString *configFilePath = nil;
	NSString *L10nFilePath = nil;
	
	// read user arguments for specifying paths to the config and
	// localization files before reading any other arguments (we
	// want to load the config first and then read the arguments
	// so that the arguments could override whatever is set in
	// the config. the localization stuff is just along for the
	// ride (it's good friends with the config stuff and I don't
	// have the heart to separate them))
	int i;
	for (i = 1; i < argc; i++)
	{
		if (((strcmp(argv[i], "-cf") == 0) || (strcmp(argv[i], "--configFile") == 0)) && (i+1 < argc))
		{
			configFilePath = [[NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding] stringByExpandingTildeInPath];
			if ([configFilePath length] > 0)
			{
				BOOL userSpecifiedConfigFileIsDir;
				BOOL userSpecifiedConfigFileExists = [[NSFileManager defaultManager]
					fileExistsAtPath:configFilePath
					isDirectory:&userSpecifiedConfigFileIsDir
					];
				if (!userSpecifiedConfigFileExists)
				{
					PrintfErr(@"Error: specified configuration file doesn't exist: '%@'\n", configFilePath);
					configFilePath = nil;
				}
				else if (userSpecifiedConfigFileIsDir)
				{
					PrintfErr(@"Error: specified configuration file is a directory: '%@'\n", configFilePath);
					configFilePath = nil;
				}
			}
		}
		else if (((strcmp(argv[i], "-lf") == 0) || (strcmp(argv[i], "--localizationFile") == 0)) && (i+1 < argc))
		{
			L10nFilePath = [[NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding] stringByExpandingTildeInPath];
			if ([L10nFilePath length] > 0)
			{
				BOOL userSpecifiedL10nFileIsDir;
				BOOL userSpecifiedL10nFileExists = [[NSFileManager defaultManager]
					fileExistsAtPath:L10nFilePath
					isDirectory:&userSpecifiedL10nFileIsDir
					];
				if (!userSpecifiedL10nFileExists)
				{
					PrintfErr(@"Error: specified localization file doesn't exist: '%@'\n", L10nFilePath);
					L10nFilePath = nil;
				}
				else if (userSpecifiedL10nFileIsDir)
				{
					PrintfErr(@"Error: specified localization file is a directory: '%@'\n", L10nFilePath);
					L10nFilePath = nil;
				}
			}
		}
	}
	
	
	
	// read and validate general configuration file
	
	configDict = nil;
	if (configFilePath == nil)
		configFilePath = [kConfigFilePath stringByExpandingTildeInPath];
	if (configFilePath != nil && [configFilePath length] > 0)
	{
		BOOL configFileIsDir;
		BOOL configFileExists = [[NSFileManager defaultManager]
			fileExistsAtPath:configFilePath
			isDirectory:&configFileIsDir
			];
		if (configFileExists && !configFileIsDir)
		{
			BOOL configFileIsValid = YES;
			
			configDict = [NSDictionary dictionaryWithContentsOfFile:configFilePath];
			
			if (configDict == nil)
			{
				PrintfErr(@"* Error in configuration file \"%@\":\n", configFilePath);
				PrintfErr(@"  can not recognize file format -- must be a valid property list\n");
				PrintfErr(@"  with a structure specified in the icalBuddyConfig man page.\n");
				configFileIsValid = NO;
			}
			
			if (!configFileIsValid)
			{
				PrintfErr(@"\nTry running \"man icalBuddyConfig\" to read the relevant documentation\n");
				PrintfErr(@"and \"plutil '%@'\" to validate the\nfile's property list syntax.\n\n", configFilePath);
			}
			else
			{
				NSDictionary *constArgsDict = [configDict objectForKey:@"constantArguments"];
				if (constArgsDict != nil)
				{
					NSArray *allArgKeys = [constArgsDict allKeys];
					if ([allArgKeys containsObject:@"bullet"])
						prefixStrBullet = [constArgsDict objectForKey:@"bullet"];
					if ([allArgKeys containsObject:@"alertBullet"])
						prefixStrBulletAlert = [constArgsDict objectForKey:@"alertBullet"];
					if ([allArgKeys containsObject:@"sectionSeparator"])
						sectionSeparatorStr = [constArgsDict objectForKey:@"sectionSeparator"];
					if ([allArgKeys containsObject:@"timeFormat"])
						timeFormatStr = [constArgsDict objectForKey:@"timeFormat"];
					if ([allArgKeys containsObject:@"dateFormat"])
						dateFormatStr = [constArgsDict objectForKey:@"dateFormat"];
					if ([allArgKeys containsObject:@"includeEventProps"])
						includedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"includeEventProps"]);
					if ([allArgKeys containsObject:@"excludeEventProps"])
						excludedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"excludeEventProps"]);
					if ([allArgKeys containsObject:@"includeTaskProps"])
						includedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"includeTaskProps"]);
					if ([allArgKeys containsObject:@"excludeTaskProps"])
						excludedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"excludeTaskProps"]);
					if ([allArgKeys containsObject:@"includeCals"])
						arg_includeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"includeCals"]);
					if ([allArgKeys containsObject:@"excludeCals"])
						arg_excludeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"excludeCals"]);
					if ([allArgKeys containsObject:@"propertyOrder"])
						arg_propertyOrderStr = [constArgsDict objectForKey:@"propertyOrder"];
					if ([allArgKeys containsObject:@"strEncoding"])
						arg_strEncoding = [constArgsDict objectForKey:@"strEncoding"];
					if ([allArgKeys containsObject:@"separateByCalendar"])
						arg_separateByCalendar = [[constArgsDict objectForKey:@"separateByCalendar"] boolValue];
					if ([allArgKeys containsObject:@"separateByDate"])
						arg_separateByDate = [[constArgsDict objectForKey:@"separateByDate"] boolValue];
					if ([allArgKeys containsObject:@"includeOnlyEventsFromNowOn"])
						arg_includeOnlyEventsFromNowOn = [[constArgsDict objectForKey:@"includeOnlyEventsFromNowOn"] boolValue];
					if ([allArgKeys containsObject:@"formatOutput"])
						arg_useFormatting = [[constArgsDict objectForKey:@"formatOutput"] boolValue];
					if ([allArgKeys containsObject:@"noCalendarNames"])
						arg_noCalendarNames = [[constArgsDict objectForKey:@"noCalendarNames"] boolValue];
					if ([allArgKeys containsObject:@"noRelativeDates"])
						displayRelativeDates = ![[constArgsDict objectForKey:@"noRelativeDates"] boolValue];
					if ([allArgKeys containsObject:@"showEmptyDates"])
						arg_sectionsForEachDayInSpan = [[constArgsDict objectForKey:@"showEmptyDates"] boolValue];
					if ([allArgKeys containsObject:@"notesNewlineReplacement"])
						notesNewlineReplacement = [constArgsDict objectForKey:@"notesNewlineReplacement"];
					if ([allArgKeys containsObject:@"limitItems"])
						maxNumPrintedItems = [[constArgsDict objectForKey:@"limitItems"] unsignedIntegerValue];
					if ([allArgKeys containsObject:@"propertySeparators"])
						arg_propertySeparatorsStr = [constArgsDict objectForKey:@"propertySeparators"];
					if ([allArgKeys containsObject:@"excludeEndDates"])
						excludeEndDates = [[constArgsDict objectForKey:@"excludeEndDates"] boolValue];
					if ([allArgKeys containsObject:@"sortTasksByDate"])
						arg_sortTasksByDueDate = [[constArgsDict objectForKey:@"sortTasksByDate"] boolValue];
					if ([allArgKeys containsObject:@"sortTasksByDateAscending"])
						arg_sortTasksByDueDateAscending = [[constArgsDict objectForKey:@"sortTasksByDateAscending"] boolValue];
					if ([allArgKeys containsObject:@"noPropNames"])
						arg_noPropNames = [[constArgsDict objectForKey:@"noPropNames"] boolValue];
					if ([allArgKeys containsObject:@"showUIDs"])
						showUIDs = [[constArgsDict objectForKey:@"showUIDs"] boolValue];
					if ([allArgKeys containsObject:@"debug"])
						debugPrintEnabled = [[constArgsDict objectForKey:@"debug"] boolValue];
				}
			}
		}
	}
	
	
	
	// read and validate localization configuration file
	
	L10nStringsDict = nil;
	if (L10nFilePath == nil)
		L10nFilePath = [kL10nFilePath stringByExpandingTildeInPath];
	if (L10nFilePath != nil && [L10nFilePath length] > 0)
	{
		BOOL L10nFileIsDir;
		BOOL L10nFileExists = [[NSFileManager defaultManager] fileExistsAtPath:L10nFilePath isDirectory:&L10nFileIsDir];
		if (L10nFileExists && !L10nFileIsDir)
		{
			BOOL L10nFileIsValid = YES;
			
			L10nStringsDict = [NSDictionary dictionaryWithContentsOfFile:L10nFilePath];
			
			if (L10nStringsDict == nil)
			{
				PrintfErr(@"* Error in localization file \"%@\":\n", L10nFilePath);
				PrintfErr(@"  can not recognize file format -- must be a valid property list\n");
				PrintfErr(@"  with a structure specified in the icalBuddyLocalization man page.\n");
				L10nFileIsValid = NO;
			}
			
			if (L10nFileIsValid)
			{
				// validate some specific keys in localization config
				NSDictionary *L10nKeysRequiringSubstrings = [NSDictionary dictionaryWithObjectsAndKeys:
					@"%d", kL10nKeyXWeeksFromNow,
					@"%d", kL10nKeyXWeeksAgo,
					@"%d", kL10nKeyXDaysAgo,
					@"%d", kL10nKeyXDaysFromNow,
					@"%@", kL10nKeySomeonesBirthday,
					nil
					];
				NSString *thisKey;
				NSString *thisVal;
				NSString *requiredSubstring;
				for (thisKey in [L10nKeysRequiringSubstrings allKeys])
				{
					requiredSubstring = [L10nKeysRequiringSubstrings objectForKey:thisKey];
					thisVal = [L10nStringsDict objectForKey:thisKey];
					if (thisVal != nil && [thisVal rangeOfString:requiredSubstring].location == NSNotFound)
					{
						PrintfErr(@"* Error in localization file \"%@\"\n", L10nFilePath);
						PrintfErr(@"  (key: \"%@\", value: \"%@\"):\n", thisKey, thisVal);
						PrintfErr(@"  value must include %@ to indicate position for a variable.\n", requiredSubstring);
						L10nFileIsValid = NO;
					}
				}
			}
			
			if (!L10nFileIsValid)
			{
				PrintfErr(@"\nTry running \"man icalBuddyLocalization\" to read the relevant documentation\n");
				PrintfErr(@"and \"plutil '%@'\" to validate the\nfile's property list syntax.\n\n", L10nFilePath);
			}
		}
	}
	
	
	
	
	// get arguments
	
	if (argc > 1)
	{
		arg_output = [NSString stringWithCString: argv[argc-1] encoding: NSASCIIStringEncoding];
		
		arg_output_is_uncompletedTasks = [arg_output isEqualToString:@"uncompletedTasks"];
		arg_output_is_eventsToday = [arg_output hasPrefix:@"eventsToday"];
		arg_output_is_eventsNow = [arg_output isEqualToString:@"eventsNow"];
		arg_output_is_tasksDueBefore = [arg_output hasPrefix:@"tasksDueBefore:"];
		
		if ([arg_output hasPrefix:@"to:"] && argc > 2)
		{
			NSString *secondToLastArg = [NSString stringWithCString: argv[argc-2] encoding: NSASCIIStringEncoding];
			if ([secondToLastArg hasPrefix:@"eventsFrom:"])
			{
				arg_eventsFrom = [secondToLastArg substringFromIndex:11]; // "eventsFrom:" has 11 chars
				arg_eventsTo = [arg_output substringFromIndex:3]; // "to:" has 3 chars
				arg_output_is_eventsFromTo = YES;
			}
		}
	}
	
	
	
	for (i = 1; i < argc; i++)
	{
		if ((strcmp(argv[i], "-sc") == 0) || (strcmp(argv[i], "--separateByCalendar") == 0))
			arg_separateByCalendar = YES;
		else if ((strcmp(argv[i], "-sd") == 0) || (strcmp(argv[i], "--separateByDate") == 0))
			arg_separateByDate = YES;
		else if ((strcmp(argv[i], "-u") == 0) || (strcmp(argv[i], "--checkForUpdates") == 0))
			arg_updatesCheck = YES;
		else if ((strcmp(argv[i], "-V") == 0) || (strcmp(argv[i], "--version") == 0))
			arg_printVersion = YES;
		else if ((strcmp(argv[i], "-d") == 0) || (strcmp(argv[i], "--debug") == 0))
			debugPrintEnabled = YES;
		else if ((strcmp(argv[i], "-n") == 0) || (strcmp(argv[i], "--includeOnlyEventsFromNowOn") == 0))
			arg_includeOnlyEventsFromNowOn = YES;
		else if ((strcmp(argv[i], "-f") == 0) || (strcmp(argv[i], "--formatOutput") == 0))
			arg_useFormatting = YES;
		else if ((strcmp(argv[i], "-nc") == 0) || (strcmp(argv[i], "--noCalendarNames") == 0))
			arg_noCalendarNames = YES;
		else if ((strcmp(argv[i], "-nrd") == 0) || (strcmp(argv[i], "--noRelativeDates") == 0))
			displayRelativeDates = NO;
		else if ((strcmp(argv[i], "-eed") == 0) || (strcmp(argv[i], "--excludeEndDates") == 0))
			excludeEndDates = YES;
		else if ((strcmp(argv[i], "-std") == 0) || (strcmp(argv[i], "--sortTasksByDate") == 0))
			arg_sortTasksByDueDate = YES;
		else if ((strcmp(argv[i], "-stda") == 0) || (strcmp(argv[i], "--sortTasksByDateAscending") == 0))
			arg_sortTasksByDueDateAscending = YES;
		else if ((strcmp(argv[i], "-sed") == 0) || (strcmp(argv[i], "--showEmptyDates") == 0))
			arg_sectionsForEachDayInSpan = YES;
		else if ((strcmp(argv[i], "-uid") == 0) || (strcmp(argv[i], "--showUIDs") == 0))
			showUIDs = YES;
		else if ((strcmp(argv[i], "-npn") == 0) || (strcmp(argv[i], "--noPropNames") == 0))
			arg_noPropNames = YES;
		else if (((strcmp(argv[i], "-b") == 0) || (strcmp(argv[i], "--bullet") == 0)) && (i+1 < argc))
			prefixStrBullet = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-ab") == 0) || (strcmp(argv[i], "--alertBullet") == 0)) && (i+1 < argc))
			prefixStrBulletAlert = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-ss") == 0) || (strcmp(argv[i], "--sectionSeparator") == 0)) && (i+1 < argc))
			sectionSeparatorStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-tf") == 0) || (strcmp(argv[i], "--timeFormat") == 0)) && (i+1 < argc))
			timeFormatStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-df") == 0) || (strcmp(argv[i], "--dateFormat") == 0)) && (i+1 < argc))
			dateFormatStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-iep") == 0) || (strcmp(argv[i], "--includeEventProps") == 0)) && (i+1 < argc))
			includedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-eep") == 0) || (strcmp(argv[i], "--excludeEventProps") == 0)) && (i+1 < argc))
			excludedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-itp") == 0) || (strcmp(argv[i], "--includeTaskProps") == 0)) && (i+1 < argc))
			includedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-etp") == 0) || (strcmp(argv[i], "--excludeTaskProps") == 0)) && (i+1 < argc))
			excludedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-nnr") == 0) || (strcmp(argv[i], "--notesNewlineReplacement") == 0)) && (i+1 < argc))
			notesNewlineReplacement = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-ic") == 0) || (strcmp(argv[i], "--includeCals") == 0)) && (i+1 < argc))
			arg_includeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-ec") == 0) || (strcmp(argv[i], "--excludeCals") == 0)) && (i+1 < argc))
			arg_excludeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-po") == 0) || (strcmp(argv[i], "--propertyOrder") == 0)) && (i+1 < argc))
			arg_propertyOrderStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if ((strcmp(argv[i], "--strEncoding") == 0) && (i+1 < argc))
			arg_strEncoding = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-li") == 0) || (strcmp(argv[i], "--limitItems") == 0)) && (i+1 < argc))
			maxNumPrintedItems = abs([[NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding] integerValue]);
		else if (((strcmp(argv[i], "-ps") == 0) || (strcmp(argv[i], "--propertySeparators") == 0)) && (i+1 < argc))
			arg_propertySeparatorsStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
	}
	
	
	if (arg_propertyOrderStr != nil)
	{
		// if property order is specified, filter out property names that are not allowed (the allowed
		// ones are all included in the NSArray specified by the kDefaultPropertyOrder macro definition)
		// and then add to the list the omitted property names in the default order
		NSArray *specifiedPropertyOrder = arrayFromCommaSeparatedStringTrimmingWhitespace(arg_propertyOrderStr);
		NSMutableArray *tempPropertyOrder = [NSMutableArray arrayWithCapacity:10];
		[tempPropertyOrder
			addObjectsFromArray:[specifiedPropertyOrder
				filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", kDefaultPropertyOrder]
				]
			];
		for (NSString *thisPropertyInDefaultOrder in kDefaultPropertyOrder)
		{
			if (![tempPropertyOrder containsObject:thisPropertyInDefaultOrder])
				[tempPropertyOrder addObject:thisPropertyInDefaultOrder];
		}
		propertyOrder = tempPropertyOrder;
	}
	else
		propertyOrder = kDefaultPropertyOrder;
	
	
	if (arg_propertySeparatorsStr != nil)
	{
		NSError *propertySeparatorsArgParseError = nil;
		propertySeparators = arrayFromArbitrarilySeparatedString(arg_propertySeparatorsStr, YES, &propertySeparatorsArgParseError);
		if (propertySeparators == nil && propertySeparatorsArgParseError != nil)
		{
			PrintfErr(
				@"* Error: invalid value for argument -ps (or --propertySeparators):\n  \"%@\".\n",
				[propertySeparatorsArgParseError localizedDescription]
				);
			PrintfErr(@"  Make sure you start and end the value with the separator character\n  (like this: -ps \"|first|second|third|\")\n");
		}
	}
	if (propertySeparators == nil || [propertySeparators count] == 0)
		propertySeparators = kDefaultPropertySeparators;
	
	
	if (arg_strEncoding != nil)
	{
		// process provided output string encoding argument
		arg_strEncoding = [arg_strEncoding stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSStringEncoding matchedEncoding = 0;
		const NSStringEncoding *availableEncoding = [NSString availableStringEncodings];
		while(*availableEncoding != 0)
		{
			if ([[NSString localizedNameOfStringEncoding: *availableEncoding] isEqualToString:arg_strEncoding])
			{
				matchedEncoding = *availableEncoding;
				break;
			}
			availableEncoding++;
		}
		if (matchedEncoding != 0)
			outputStrEncoding = matchedEncoding;
		else
		{
			PrintfErr(@"* Error: Invalid string encoding argument: \"%@\".\n", arg_strEncoding);
			PrintfErr(@"  Run \"icalBuddy strEncodings\" to see all the possible values.\n");
			PrintfErr(@"  Using default encoding \"%@\".\n\n", [NSString localizedNameOfStringEncoding: outputStrEncoding]);
		}
	}
	
	// interpret/translate escape sequences for values of arguments
	// that take arbitrary strings
	sectionSeparatorStr = translateEscapeSequences(sectionSeparatorStr);
	timeFormatStr = translateEscapeSequences(timeFormatStr);
	dateFormatStr = translateEscapeSequences(dateFormatStr);
	prefixStrBullet = translateEscapeSequences(prefixStrBullet);
	prefixStrBulletAlert = translateEscapeSequences(prefixStrBulletAlert);
	notesNewlineReplacement = translateEscapeSequences(notesNewlineReplacement);
	
	
	
	// ------------------------------------------------------------------
	// ------------------------------------------------------------------
	// print version and exit
	// ------------------------------------------------------------------
	if (arg_printVersion)
	{
		Printf(@"%@\n", versionNumberStr());
	}
	// ------------------------------------------------------------------
	// ------------------------------------------------------------------
	// check for updates
	// ------------------------------------------------------------------
	else if (arg_updatesCheck)
	{
		[autoUpdater checkForUpdatesWithUI];
	}
	// ------------------------------------------------------------------
	// ------------------------------------------------------------------
	// print possible values for the string encoding argument and exit
	// ------------------------------------------------------------------
	else if ([arg_output isEqualToString:@"strEncodings"])
	{
		Printf(@"\nAvailable String encodings (you can use one of these\nas an argument to the --strEncoding option):\n\n");
		const NSStringEncoding *availableEncoding = [NSString availableStringEncodings];
		while(*availableEncoding != 0)
		{
			Printf(@"%@\n", [NSString localizedNameOfStringEncoding: *availableEncoding]);
			availableEncoding++;
		}
		Printf(@"\n");
	}
	// ------------------------------------------------------------------
	// ------------------------------------------------------------------
	// print all calendars
	// ------------------------------------------------------------------
	else if ([arg_output isEqualToString:@"calendars"])
	{
		// get all calendars
		NSMutableArray *allCalendars = [[[CalCalendarStore defaultCalendarStore] calendars] mutableCopy];
		
		// filter calendars based on arguments
		allCalendars = filterCalendars(allCalendars, arg_includeCals, arg_excludeCals);
		
		CalCalendar *cal;
		for (cal in allCalendars)
		{
			Printf(@"* %@\n  uid: %@\n", [cal title], [cal uid]);
		}
	}
	// ------------------------------------------------------------------
	// ------------------------------------------------------------------
	// open config file for editing
	// ------------------------------------------------------------------
	else if ([arg_output hasPrefix:@"editConfig"])
	{
		configFilePath = [kConfigFilePath stringByExpandingTildeInPath];
		BOOL configFileIsDir;
		BOOL configFileExists = [[NSFileManager defaultManager] fileExistsAtPath:configFilePath isDirectory:&configFileIsDir];
		
		if (!configFileExists)
		{
			[kConfigFileStub writeToFile:configFilePath atomically:YES];
			Printf(@"Configuration file did not exist; it has now been created.\n");
		}
		
		if (configFileIsDir)
		{
			PrintfErr(
				@"Error: There seems to be a directory where the configuration\nfile should be: %@\nCan not open configuration file.\n",
				configFilePath
				);
		}
		else
		{
			if ([arg_output hasSuffix:@"CLI"])
			{
				NSString *foundEditorPath = nil;
				
				NSMutableArray *preferredEditors = [NSMutableArray arrayWithObjects:@"vim", @"vi", @"nano", @"pico", @"emacs", @"ed", nil];
				NSString *pathEnvironmentVariable = [[[NSProcessInfo processInfo] environment] objectForKey:@"PATH"];
				NSString *editorEnvironmentVariable = [[[NSProcessInfo processInfo] environment] objectForKey:@"EDITOR"];
				
				if (editorEnvironmentVariable != nil)
				{
					if ([[NSFileManager defaultManager] isExecutableFileAtPath:editorEnvironmentVariable])
						foundEditorPath = editorEnvironmentVariable;
					else
					{
						[preferredEditors removeObject:[editorEnvironmentVariable lastPathComponent]];
						[preferredEditors insertObject:[editorEnvironmentVariable lastPathComponent] atIndex:0];
					}
				}
				
				if (foundEditorPath == nil && pathEnvironmentVariable != nil)
				{
					NSArray *separatePaths = [pathEnvironmentVariable componentsSeparatedByString:@":"];
					NSString *thisFullEditorPathCandidate;
					NSString *thisEditor;
					for (thisEditor in preferredEditors)
					{
						NSString *thisPath;
						for (thisPath in separatePaths)
						{
							thisFullEditorPathCandidate = strConcat(thisPath, @"/", thisEditor, nil);
							if ([[NSFileManager defaultManager] isExecutableFileAtPath:thisFullEditorPathCandidate])
							{
								foundEditorPath = thisFullEditorPathCandidate;
								break;
							}
						}
						if (foundEditorPath != nil)
							break;
					}
				}
				
				if (foundEditorPath != nil)
				{
					Printf(
						@"Opening config file for editing with %@ -- press\nany key to continue or Ctrl-C to cancel.\n",
						foundEditorPath
						);
					if (system("read") == 0)
						system([strConcat(@"'", foundEditorPath, @"' '", configFilePath, @"'", nil) UTF8String]);
				}
				else
				{
					PrintfErr(
						@"Error: Can not find or execute any of the following\neditors in your $PATH: %@\n",
						[preferredEditors componentsJoinedByString:@", "]
						);
				}
			}
			else
			{
				if ([[NSWorkspace sharedWorkspace] fullPathForApplication:kPropertyListEditorAppName] != nil)
				{
					Printf(@"Opening configuration file with the Property List\nEditor application.\n");
					[[NSWorkspace sharedWorkspace] openFile:configFilePath withApplication:kPropertyListEditorAppName];
				}
				else
				{
					Printf(@"Opening configuration file with the default application\nassociated with the property list type.\n");
					[[NSWorkspace sharedWorkspace] openFile:configFilePath];
				}
			}
		}
	}
	// ------------------------------------------------------------------
	// ------------------------------------------------------------------
	// print events or tasks
	// ------------------------------------------------------------------
	else if (arg_output_is_eventsToday || arg_output_is_eventsNow || arg_output_is_eventsFromTo
			 || arg_output_is_uncompletedTasks || arg_output_is_tasksDueBefore)
	{
		BOOL printingEvents = (arg_output_is_eventsToday || arg_output_is_eventsNow || arg_output_is_eventsFromTo);
		BOOL printingAlsoPastEvents = (arg_output_is_eventsFromTo);
		BOOL printingTasks = (arg_output_is_uncompletedTasks || arg_output_is_tasksDueBefore);
		
		// get all calendars
		NSMutableArray *allCalendars = [[[CalCalendarStore defaultCalendarStore] calendars] mutableCopy];
		
		// filter calendars based on arguments
		allCalendars = filterCalendars(allCalendars, arg_includeCals, arg_excludeCals);
		
		int tasks_printOptions = PRINT_OPTION_NONE;
		int events_printOptions = PRINT_OPTION_NONE;
		NSArray *uncompletedTasks = nil;
		NSArray *eventsArr = nil;
		
		NSDate *eventsDateRangeStart = nil;
		NSDate *eventsDateRangeEnd = nil;
		NSUInteger eventsDateRangeDaysSpan = 0;
		
		// prepare to print events
		if (printingEvents)
		{
			// default print options
			events_printOptions = 
				PRINT_OPTION_SINGLE_DAY | 
				(arg_noCalendarNames ? PRINT_OPTION_CALENDAR_AGNOSTIC : PRINT_OPTION_NONE);
			
			// get start and end dates for predicate
			if (arg_output_is_eventsToday)
			{
				eventsDateRangeStart = today;
				eventsDateRangeEnd = dateForEndOfDay(now);
			}
			else if (arg_output_is_eventsNow)
			{
				eventsDateRangeStart = now;
				eventsDateRangeEnd = now;
			}
			else if (arg_output_is_eventsFromTo)
			{
				eventsDateRangeStart = dateFromUserInput(arg_eventsFrom, @"start date");
				eventsDateRangeEnd = dateFromUserInput(arg_eventsTo, @"end date");
				
				if (eventsDateRangeStart == nil || eventsDateRangeEnd == nil)
				{
					printDateFormatInfo();
					return(0);
				}
				
				if ([eventsDateRangeStart compare:eventsDateRangeEnd] == NSOrderedDescending)
				{
					// start date occurs before end date --> swap them
					NSDate *tempSwapDate = eventsDateRangeStart;
					eventsDateRangeStart = eventsDateRangeEnd;
					eventsDateRangeEnd = tempSwapDate;
				}
				
				events_printOptions &= ~PRINT_OPTION_SINGLE_DAY;
			}
			NSCAssert((eventsDateRangeStart != nil && eventsDateRangeEnd != nil), @"start or end date is nil");
			
			// expand end date if NUM in "eventsToday+NUM" is specified
			if (arg_output_is_eventsToday)
			{
				NSRange arg_output_plusSymbolRange = [arg_output rangeOfString:@"+"];
				if (arg_output_plusSymbolRange.location != NSNotFound)
				{
					NSInteger daysToAddToRange = [[arg_output substringFromIndex:(arg_output_plusSymbolRange.location+arg_output_plusSymbolRange.length)] intValue];
					eventsDateRangeEnd = dateByAddingDays(eventsDateRangeEnd, daysToAddToRange);
					events_printOptions &= ~PRINT_OPTION_SINGLE_DAY;
				}
			}
			
			
			eventsDateRangeDaysSpan = getDayDiff(eventsDateRangeStart, eventsDateRangeEnd);
			
			
			NSDate *predicateDateStart = ((arg_includeOnlyEventsFromNowOn)?now:eventsDateRangeStart);
			NSDate *predicateDateEnd = eventsDateRangeEnd;
			DebugPrintf(@"effective query start date: %@\n", predicateDateStart);
			DebugPrintf(@"effective query end date:   %@\n", predicateDateEnd);
			
			// make predicate for getting all events between start and end dates + use it to get the events
			NSPredicate *eventsPredicate = [CalCalendarStore
				eventPredicateWithStartDate:predicateDateStart
				endDate:predicateDateEnd
				calendars:allCalendars
				];
			eventsArr = [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:eventsPredicate];
		}
		// prepare to print tasks
		else if (printingTasks)
		{
			// make predicate for getting the desired tasks
			NSPredicate *tasksPredicate = nil;
			
			if (arg_output_is_tasksDueBefore)
			{
				NSDate *dueBeforeDate = nil;
				
				if ([arg_output hasPrefix:@"tasksDueBefore:today+"])
				{
					// tasksDueBefore:today+NUM
					NSRange arg_output_plusSymbolRange = [arg_output rangeOfString:@"+"];
					NSInteger daysToAdd = [[arg_output substringFromIndex:(arg_output_plusSymbolRange.location+arg_output_plusSymbolRange.length)] integerValue];
					dueBeforeDate = dateByAddingDays(today, daysToAdd);
				}
				else if ([arg_output hasPrefix:@"tasksDueBefore:tomorrow"])
					// tasksDueBefore:tomorrow
					dueBeforeDate = dateByAddingDays(today, 1);
				else
				{
					// tasksDueBefore:"YYYY-MM-DD HH:MM:SS ±HHMM"
					NSString *dueBeforeDateStr = [arg_output substringFromIndex:15]; // "tasksDueBefore:" has 15 chars
					
					dueBeforeDate = dateFromUserInput(dueBeforeDateStr, @"due date");
					
					if (dueBeforeDate == nil)
					{
						printDateFormatInfo();
						return(0);
					}
				}
				
				DebugPrintf(@"effective query 'due before' date: %@\n", dueBeforeDate);
				tasksPredicate = [CalCalendarStore taskPredicateWithUncompletedTasksDueBefore:dueBeforeDate calendars:allCalendars];
			}
			else // all uncompleted tasks
				tasksPredicate = [CalCalendarStore taskPredicateWithUncompletedTasks:allCalendars];
			
			
			// get tasks
			uncompletedTasks = [[CalCalendarStore defaultCalendarStore] tasksWithPredicate:tasksPredicate];
			
			// sort the tasks
			if (arg_sortTasksByDueDate || arg_sortTasksByDueDateAscending)
			{
				uncompletedTasks = [uncompletedTasks
					sortedArrayUsingDescriptors:[NSArray
						arrayWithObjects:
							[[[NSSortDescriptor alloc] initWithKey:@"dueDate" ascending:arg_sortTasksByDueDateAscending] autorelease],
							nil
						]
					];
				
				if (arg_sortTasksByDueDateAscending)
				{
					// put tasks with no due date last
					NSArray *tasksWithNoDueDate = [uncompletedTasks
						filteredArrayUsingPredicate:[NSPredicate
							predicateWithFormat:@"dueDate == nil"
							]
						];
					uncompletedTasks = [uncompletedTasks
						filteredArrayUsingPredicate:[NSPredicate
							predicateWithFormat:@"dueDate != nil"
							]
						];
					uncompletedTasks = [uncompletedTasks arrayByAddingObjectsFromArray:tasksWithNoDueDate];
				}
			}
			else
				uncompletedTasks = [uncompletedTasks sortedArrayUsingFunction:prioritySort context:NULL];
			
			// default print options
			tasks_printOptions = (arg_noCalendarNames ? PRINT_OPTION_CALENDAR_AGNOSTIC : PRINT_OPTION_NONE);
		}
		
		
		// append to print options
		if (arg_noPropNames)
		{
			events_printOptions |= PRINT_OPTION_WITHOUT_PROP_NAMES;
			tasks_printOptions |= PRINT_OPTION_WITHOUT_PROP_NAMES;
		}
		if (arg_separateByCalendar)
		{
			events_printOptions |= PRINT_OPTION_CAL_COLORS_FOR_SECTION_TITLES;
			tasks_printOptions |= PRINT_OPTION_CAL_COLORS_FOR_SECTION_TITLES;
		}
		
		
		// print the items
		if (arg_separateByCalendar)
		{
			NSMutableArray *byCalendarSections = [NSMutableArray arrayWithCapacity:[allCalendars count]];
			
			CalCalendar *cal;
			for (cal in allCalendars)
			{
				NSMutableArray *thisCalendarItems = [NSMutableArray arrayWithCapacity:((printingEvents)?[eventsArr count]:[uncompletedTasks count])];
				
				if (printingEvents)
					[thisCalendarItems addObjectsFromArray:eventsArr];
				else if (printingTasks)
					[thisCalendarItems addObjectsFromArray:uncompletedTasks];
				
				[thisCalendarItems filterUsingPredicate:[NSPredicate predicateWithFormat:@"calendar.uid == %@", [cal uid]]];
				
				if (thisCalendarItems != nil && [thisCalendarItems count] > 0)
					[byCalendarSections addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						thisCalendarItems, kSectionDictKey_items,
						[cal title], kSectionDictKey_title,
						nil
					]];
			}
			
			int thisPrintOptions = (printingEvents) ? events_printOptions : tasks_printOptions;
			printItemSections(byCalendarSections, (thisPrintOptions | PRINT_OPTION_CALENDAR_AGNOSTIC));
		}
		else if (arg_separateByDate)
		{
			// keys: NSDates (representing *days* to use as sections),
			// values: NSArrays of CalCalendarItems that match those days
			NSMutableDictionary *allDays = [NSMutableDictionary dictionaryWithCapacity:[eventsArr count]];
			
			if (printingEvents)
			{
				// fill allDays using event start dates' days and all spanned days thereafter
				// if the event spans multiple days
				CalEvent *anEvent;
				for (anEvent in eventsArr)
				{
					// calculate anEvent's days span and limit it to the range of days we
					// want displayed
					
					NSUInteger anEventDaysSpan = getDayDiff([anEvent startDate], [anEvent endDate]);
					
					// the previous method call returns day spans that are one day too long for
					// all-day events so in those cases we'll subtract one
					if ([anEvent isAllDay] && anEventDaysSpan > 0)
						anEventDaysSpan--;
					
					NSUInteger rangeStartToAnEventStartDaysSpan = getDayDiff(eventsDateRangeStart, [anEvent startDate]);
					
					NSUInteger daySpanLeftInRange = eventsDateRangeDaysSpan - rangeStartToAnEventStartDaysSpan;
					NSUInteger anEventDaysSpanToConsider = MIN(daySpanLeftInRange, anEventDaysSpan);
					
					
					NSDate *thisEventStartDate = [anEvent startDate];
					
					NSUInteger i;
					for (i = 0; i <= anEventDaysSpanToConsider; i++)
					{
						NSDate *thisEventStartDatePlusi = dateByAddingDays(thisEventStartDate, i);
						
						NSDate *dayToAdd = dateForStartOfDay(thisEventStartDatePlusi);
						
						NSComparisonResult dayToAddToNowComparisonResult = [dayToAdd compare:today];
						
						if (printingAlsoPastEvents
							|| dayToAddToNowComparisonResult == NSOrderedDescending
							|| dayToAddToNowComparisonResult == NSOrderedSame
							|| datesRepresentSameDay(now, dayToAdd)
							)
						{
							if (![[allDays allKeys] containsObject:dayToAdd])
								[allDays setObject:[NSMutableArray arrayWithCapacity:20] forKey:dayToAdd];
							
							NSMutableArray *dayToAddEvents = [allDays objectForKey:dayToAdd];
							NSCAssert((dayToAddEvents != nil), @"dayToAddEvents is nil");
							[dayToAddEvents addObject:anEvent];
						}
					}
				}
			}
			else if (printingTasks)
			{
				// fill allDays using task due dates' days
				CalTask *aTask;
				for (aTask in uncompletedTasks)
				{
					id thisDayKey = nil;
					if ([aTask dueDate] != nil)
					{
						NSDate *thisTaskDueDate = [aTask dueDate];
						NSDate *thisDueDay = dateForStartOfDay(thisTaskDueDate);
						thisDayKey = thisDueDay;
					}
					else
						thisDayKey = [NSNull null]; // represents "no due date"
					
					if (![[allDays allKeys] containsObject:thisDayKey])
						[allDays setObject:[NSMutableArray arrayWithCapacity:20] forKey:thisDayKey];
					
					NSMutableArray *thisDayTasks = [allDays objectForKey:thisDayKey];
					NSCAssert((thisDayTasks != nil), @"thisDayTasks is nil");
					[thisDayTasks addObject:aTask];
				}
				
			}
			
			// we'll fill this with dictionaries, each of which will represent a section
			// to be printed, with a title and a list of CalCalendarItems (in the order
			// we want to print them out).
			NSMutableArray *byDateSections = [NSMutableArray arrayWithCapacity:[eventsArr count]];
			
			// remove NSNull ("no due date") if it exists and sort the dates
			NSMutableArray *allDaysArr = [NSMutableArray arrayWithCapacity:[[allDays allKeys] count]];
			[allDaysArr addObjectsFromArray:[allDays allKeys]];
			[allDaysArr removeObjectIdenticalTo:[NSNull null]];
			[allDaysArr sortUsingSelector:@selector(compare:)];
			
			if (arg_sectionsForEachDayInSpan)
			{
				// fill the day span we have so that all days have an entry
				NSDate *earliestDate = nil;
				NSDate *latestDate = nil;
				
				if (arg_output_is_eventsFromTo || arg_output_is_eventsToday || arg_output_is_eventsNow)
				{
					earliestDate = dateForStartOfDay(eventsDateRangeStart);
					latestDate = dateForStartOfDay(eventsDateRangeEnd);
				}
				else
				{
					if ([allDaysArr count] > 1)
					{
						earliestDate = [allDaysArr objectAtIndex:0];
						latestDate = [allDaysArr lastObject];
					}
					else
					{
						earliestDate = today;
						latestDate = today;
					}
				}
				
				NSDate *iterDate = earliestDate;
				do
				{
					if (![allDaysArr containsObject:iterDate])
						[allDaysArr addObject:iterDate];
					iterDate = dateByAddingDays(iterDate, 1);
				}
				while ([iterDate compare:latestDate] != NSOrderedDescending);
				
				[allDaysArr sortUsingSelector:@selector(compare:)];
			}
			
			// reinsert NSNull ("no due date") at the bottom if needed
			if ([allDays objectForKey:[NSNull null]] != nil)
				[allDaysArr addObject:[NSNull null]];
			
			// set the section items and titles as dictionaries into the byDateSections array
			id aDayKey;
			for (aDayKey in allDaysArr)
			{
				NSArray *thisSectionItems = [allDays objectForKey:aDayKey];
				if (thisSectionItems == nil)
					thisSectionItems = [NSArray array];
				NSMutableDictionary *thisSectionDict = [NSMutableDictionary
					dictionaryWithObject:thisSectionItems
					forKey:kSectionDictKey_items
					];
				
				if (printingEvents && [aDayKey isKindOfClass:[NSDate class]])
					[thisSectionDict setObject:aDayKey forKey:kSectionDictKey_eventsContextDay];
				
				NSString *thisSectionTitle = nil;
				if ([aDayKey isKindOfClass:[NSDate class]])
					thisSectionTitle = dateStr(aDayKey, ONLY_DATE);
				else if ([aDayKey isEqual:[NSNull null]])
					thisSectionTitle = strConcat(@"(", localizedStr(kL10nKeyNoDueDate), @")", nil);
				[thisSectionDict setObject:thisSectionTitle forKey:kSectionDictKey_title];
				
				[byDateSections addObject:thisSectionDict];
			}
			
			int thisPrintOptions = (printingEvents) ? events_printOptions : tasks_printOptions;
			printItemSections(byDateSections, (thisPrintOptions | PRINT_OPTION_SINGLE_DAY));
		}
		else // no separation
		{
			if (printingEvents)
			{
				CalEvent *event;
				for (event in eventsArr)
				{
					printCalEvent(event, events_printOptions, now);
				}
			}
			else if (printingTasks)
			{
				CalTask *task;
				for (task in uncompletedTasks)
				{
					printCalTask(task, tasks_printOptions);
				}
			}
		}
	}
	// ------------------------------------------------------------------
	// ------------------------------------------------------------------
	else
	{
		Printf(@"\n");
		Printf(@"USAGE: %@ [options] <command>\n", [[NSString stringWithCString:argv[0] encoding:NSUTF8StringEncoding] lastPathComponent]);
		Printf(@"\n");
		Printf(@"<command> specifies the general action icalBuddy should take:\n");
		Printf(@"\n");
		Printf(@"  'eventsToday'      Print events occurring today\n");
		Printf(@"  'eventsToday+NUM'  Print events occurring between today and NUM days into\n");
		Printf(@"                     the future\n");
		Printf(@"  'eventsNow'        Print events occurring at present time\n");
		Printf(@"  'eventsFrom:START to:END'\n");
		Printf(@"                     Print events occurring between the two specified dates\n");
		Printf(@"  'uncompletedTasks' Print uncompleted tasks\n");
		Printf(@"  'tasksDueBefore:DATE'\n");
		Printf(@"                     Print uncompleted tasks that are due before the given\n");
		Printf(@"                     date, which can be 'today+NUM' or any regular date\n");
		Printf(@"  'calendars'        Print all calendars\n");
		Printf(@"  'strEncodings'     Print all the possible string encodings\n");
		Printf(@"  'editConfig'       Open the configuration file for editing in a GUI editor\n");
		Printf(@"  'editConfigCLI'    Open the configuration file for editing in a CLI editor\n");
		Printf(@"\n");
		Printf(@"Some of the [options] you can use are:\n");
		Printf(@"\n");
		Printf(@"-V         Print version number (no <command> needed)\n");
		Printf(@"-u         Check for updates to self online (no <command> needed)\n");
		Printf(@"-sc,-sd    Separate by calendar or date\n");
		Printf(@"-f         Format output\n");
		Printf(@"-nc        No calendar names\n");
		Printf(@"-nrd       No relative dates\n");
		Printf(@"-npn       No property names\n");
		Printf(@"-n         Include only events from now on\n");
		Printf(@"-sed       Show empty dates\n");
		Printf(@"-uid       Show event/task UIDs\n");
		Printf(@"-eed       Exclude end datetimes\n");
		Printf(@"-li        Limit items (value required)\n");
		Printf(@"-std,-stda Sort tasks by due date (stda = ascending)\n");
		Printf(@"-tf,-df    Set time or date format (value required)\n");
		Printf(@"-po        Set property order (value required)\n");
		Printf(@"-ps        Set property separators (value required)\n");
		Printf(@"-b         Set bullet point (value required)\n");
		Printf(@"-ab        Set alert bullet point (value required)\n");
		Printf(@"-ss        Set section separator (value required)\n");
		Printf(@"-ic,-ec    Include or exclude calendars (value required)\n");
		Printf(@"-iep,-eep  Include or exclude event properties (value required)\n");
		Printf(@"-itp,-etp  Include or exclude task properties (value required)\n");
		Printf(@"-cf,-lf    Set config or localization file path (value required)\n");
		Printf(@"-nnr       Set replacement for newlines within notes (value required)\n");
		Printf(@"\n");
		Printf(@"See the icalBuddy man page for more info.\n");
		Printf(@"\n");
		Printf(@"Version %@\n", versionNumberStr());
		Printf(@"Copyright 2008-2010 Ali Rantakari, http://hasseg.org/icalBuddy\n");
		Printf(@"\n");
	}
	
	
	// we've been buffering the output for stdout into an attributed string,
	// now's the time to print out that buffer.
	if ((arg_useFormatting && configDict != nil) &&
		(arg_output_is_eventsToday || arg_output_is_eventsNow ||
		arg_output_is_eventsFromTo || arg_output_is_uncompletedTasks)
		)
	{
		NSDictionary *formattedKeywords = [configDict objectForKey:@"formattedKeywords"];
		if (formattedKeywords != nil)
		{
			// it seems we need to do some search & replace for the output
			// before pushing the buffer to stdout.
			
			NSString *keyword;
			for (keyword in [formattedKeywords allKeys])
			{
				NSDictionary* thisKeywordFormattingAttrs = formattingConfigToStringAttributes([formattedKeywords objectForKey:keyword]);
				
				NSString *cleanStdoutBuffer = [stdoutBuffer string];
				NSRange searchRange = NSMakeRange(0,[stdoutBuffer length]);
				NSRange foundRange;
				do
				{
					foundRange = [cleanStdoutBuffer rangeOfString:keyword options:NSLiteralSearch range:searchRange];
					if (foundRange.location != NSNotFound)
					{
						[stdoutBuffer addAttributes:thisKeywordFormattingAttrs range:foundRange];
						searchRange.location = NSMaxRange(foundRange);
						searchRange.length = [stdoutBuffer length]-searchRange.location;
					}
				}
				while (foundRange.location != NSNotFound);
			}
		}
	}
	
	NSString *finalOutput;
	
	if (arg_useFormatting)
	{
		processCustomStringAttributes(&stdoutBuffer);
		finalOutput = [ansiEscapeHelper ansiEscapedStringWithAttributedString:stdoutBuffer];
	}
	else
		finalOutput = [stdoutBuffer string];
	
	Print(finalOutput);
	
	
	[autoReleasePool release];
	return(0);
}
