//  icalBuddy.m
//
//  Created by Ali Rantakari on 17 June 2008
//  http://hasseg.org
//

/*
The MIT License

Copyright (c) 2008-2009 Ali Rantakari

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


#define kAppSiteURLPrefix @"http://hasseg.org/icalBuddy/"
#define kVersionCheckURL [NSURL URLWithString:@"http://hasseg.org/icalBuddy/?versioncheck=y"]


#define kANSIEscapeReset 	@"\033[0m"
#define kANSIEscapeBold 	@"\033[01m"
#define kANSIEscapeRed 		@"\033[31m"
#define kANSIEscapeGreen 	@"\033[32m"
#define kANSIEscapeYellow 	@"\033[33m"
#define kANSIEscapeBlue 	@"\033[34m"
#define kANSIEscapeMagenta 	@"\033[35m"
#define kANSIEscapeCyan		@"\033[36m"

#define kSectionTitleANSIEscape kANSIEscapeBlue

// custom date-formatting specifier ("relative week")
#define kRelativeWeekFormatSpecifier @"%RW"

// keys for the "sections" dictionary (see printItemSections())
#define kSectionDictKey_title 				@"sectionTitle"
#define kSectionDictKey_items 				@"sectionItems"
#define kSectionDictKey_eventsContextDay 	@"eventsContextDay"


// property names
#define kPropName_title 	@"title"
#define kPropName_location 	@"location"
#define kPropName_notes 	@"notes"
#define kPropName_url 		@"url"
#define kPropName_datetime 	@"datetime"
#define kPropName_priority 	@"priority"

// human-readable priority values
#define kPriorityStr_high 	@"high"
#define kPriorityStr_medium @"medium"
#define kPriorityStr_low 	@"low"

// default item property order + list of allowed property names (i.e. these must be in
// the default order and include all of the allowed property names)
#define kDefaultPropertyOrder [NSArray arrayWithObjects:kPropName_title, kPropName_location, kPropName_notes, kPropName_url, kPropName_datetime, kPropName_priority, nil]

// configuration file path
#define kL10nFilePath @"~/.icalBuddyLocalization.plist"



const int VERSION_MAJOR = 1;
const int VERSION_MINOR = 5;
const int VERSION_BUILD = 0;







// printOptions for calendar item printing functions
enum calItemPrintOption
{
	PRINT_OPTION_NONE = 				0,
	PRINT_OPTION_SINGLE_DAY = 			(1 << 0),	// in the contex of a single day (for events) (i.e. don't print out full dates)
	PRINT_OPTION_CALENDAR_AGNOSTIC = 	(1 << 1),	// calendar-agnostic (i.e. don't print out the calendar name)
	PRINT_OPTION_FORMAT_OUTPUT = 		(1 << 2)	// whether to use formatting in the output via ANSI escape sequences
} CalItemPrintOption;





// the string encoding to use for output
NSStringEncoding outputStrEncoding = NSUTF8StringEncoding; // default

// the order of properties in the output
NSArray *propertyOrder;

// the prefix strings
NSString *prefixStrBullet = 		@"* ";
NSString *prefixStrBulletAlert = 	@"! ";
NSString *prefixStrIndent = 		@"    ";
NSString *sectionSeparatorStr = 	@"------------------------";

NSString *timeFormatStr = 			@"%H:%M";
NSString *dateFormatStr = 			@"%Y-%m-%d";
NSString *dateTimeSeparatorStr = 	@" at ";
NSSet *includedEventProperties = 	nil;
NSSet *excludedEventProperties = 	nil;
NSSet *includedTaskProperties = 	nil;
NSSet *excludedTaskProperties = 	nil;

BOOL displayRelativeDates = YES;


NSCalendarDate *now;
NSCalendarDate *today;


// dictionary for localization values
NSDictionary *l10nStringsDict;

// default version of l10nStringsDict
NSDictionary *defaultStringsDict;





// helper method
NSString* versionNumber()
{
	return [NSString stringWithFormat:@"%d.%d.%d", VERSION_MAJOR, VERSION_MINOR, VERSION_BUILD];
}


// helper methods
// 		from: http://www.sveinbjorn.org/objectivec_stdout
// 		(modified to use non-deprecated version of writeToFile:...)
void NSPrint(NSString *aStr, ...)
{
	va_list argList;
	va_start(argList, aStr);
	NSString *str = [
		[[NSString alloc]
			initWithFormat:aStr
			locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
			arguments:argList
		] autorelease
	];
	va_end(argList);
	
	[str writeToFile:@"/dev/stdout" atomically:NO encoding:outputStrEncoding error:NULL];
}

void NSPrintErr(NSString *aStr, ...)
{
	va_list argList;
	va_start(argList, aStr);
	NSString *str = [
		[[NSString alloc]
			initWithFormat:aStr
			locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
			arguments:argList
		] autorelease
	];
	va_end(argList);
	
	[str writeToFile:@"/dev/stderr" atomically:NO encoding:outputStrEncoding error:NULL];
}





// helper method: compare three-part version number strings (e.g. "1.12.3")
NSComparisonResult versionNumberCompare(NSString *first, NSString *second)
{
	if (first != nil && second != nil)
	{
		int i;
		
		NSMutableArray *firstComponents = [NSMutableArray arrayWithCapacity:3];
		[firstComponents addObjectsFromArray:[first componentsSeparatedByString:@"."]];
		
		NSMutableArray *secondComponents = [NSMutableArray arrayWithCapacity:3];
		[secondComponents addObjectsFromArray:[second componentsSeparatedByString:@"."]];
		
		if ([firstComponents count] != [secondComponents count])
		{
			NSMutableArray *shorter;
			NSMutableArray *longer;
			if ([firstComponents count] > [secondComponents count])
			{
				shorter = secondComponents;
				longer = firstComponents;
			}
			else
			{
				shorter = firstComponents;
				longer = secondComponents;
			}
			
			NSUInteger countDiff = [longer count] - [shorter count];
			
			for (i = 0; i < countDiff; i++)
				[shorter addObject:@"0"];
		}
		
		for (i = 0; i < [firstComponents count]; i++)
		{
			int firstComponentIntVal = [[firstComponents objectAtIndex:i] intValue];
			int secondComponentIntVal = [[secondComponents objectAtIndex:i] intValue];
			if (firstComponentIntVal < secondComponentIntVal)
				return NSOrderedAscending;
			else if (firstComponentIntVal > secondComponentIntVal)
				return NSOrderedDescending;
		}
		return NSOrderedSame;
	}
	else
		return NSOrderedSame;
}



// returns localized, human-readable string corresponding to the
// specified localization dictionary key
NSString* localizedStr(NSString *str)
{
	if (str == nil)
		return nil;
	
	if (l10nStringsDict != nil)
	{
		NSString *localizedStr = [l10nStringsDict objectForKey:str];
		if (localizedStr != nil)
			return localizedStr;
	}
	
	NSString *defaultStr = [defaultStringsDict objectForKey:str];
	NSCAssert((defaultStr != nil), @"defaultStr is nil");
	return defaultStr;
}



// returns a string filled with specified number of spaces
NSString* getWhitespace(NSUInteger length)
{
	if (length == 0)
		return @"";
	
	NSString *ret = @" ";
	NSUInteger i;
	for (i = 0; i < length-1; i++)
	{
		ret = [ret stringByAppendingString:@" "];
	}
	
	return ret;
}



// create an NSSet from a comma-separated string,
// trimming whitespace from around each string component
NSSet* setFromCommaSeparatedStringTrimmingWhitespace(NSString *str)
{
	if (str != nil)
	{
		NSMutableSet *set = [NSMutableSet setWithCapacity:10];
		NSArray *arr = [str componentsSeparatedByString:@","];
		NSString *component;
		for (component in arr)
			[set addObject:[component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
		return set;
	}
	return [NSSet set];
}


// create an NSArray from a comma-separated string,
// trimming whitespace from around each string component
NSArray* arrayFromCommaSeparatedStringTrimmingWhitespace(NSString *str)
{
	if (str != nil)
	{
		NSMutableArray *retArr = [NSMutableArray arrayWithCapacity:10];
		NSArray *arr = [str componentsSeparatedByString:@","];
		NSString *component;
		for (component in arr)
			[retArr addObject:[component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
		return retArr;
	}
	return [NSArray array];
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
		if ([task1 dueDate] != nil)
			if ([now compare:[task1 dueDate]] == NSOrderedDescending)
				task1late = YES;
		if ([task2 dueDate] != nil)
			if ([now compare:[task2 dueDate]] == NSOrderedDescending)
				task2late = YES;
		
		if (task1late && !task2late)
			return NSOrderedAscending;
		else if (task2late && !task1late)
			return NSOrderedDescending;
		
		// neither task is, or both tasks are late -> order alphabetically by title
        return [[task1 title] compare:[task2 title]];
	}
}





// whether the two specified dates represent the same calendar day
BOOL datesRepresentSameDay(NSCalendarDate *date1, NSCalendarDate *date2)
{
	return ([date1 yearOfCommonEra] == [date2 yearOfCommonEra] &&
			[date1 monthOfYear] == [date2 monthOfYear] &&
			[date1 dayOfMonth] == [date2 dayOfMonth]
			);
}






// returns the total number of ISO weeks in a given year
NSInteger getNumWeeksInYear(NSInteger year)
{
	// have to check both December 31 and December 24 (a week before the 31st)
	// because the 31st may have week n:o 1 (of the following year) and the 24th
	// may have week n:o (max-1) -- we want whichever is higher
	
	NSDateComponents *lastDayOfYearComponents = [[[NSDateComponents alloc] init] autorelease];
	[lastDayOfYearComponents setYear:year];
	[lastDayOfYearComponents setMonth:12];
	[lastDayOfYearComponents setDay:31];
	NSDate *lastDayOfYear = [[NSCalendar currentCalendar] dateFromComponents:lastDayOfYearComponents];
	
	NSInteger lastDayWeek = [[[NSCalendar currentCalendar]
		components:NSWeekCalendarUnit
		fromDate:lastDayOfYear
	] week];
	
	NSDateComponents *weekBeforeLastDayOfYearComponents = [[[NSDateComponents alloc] init] autorelease];
	[weekBeforeLastDayOfYearComponents setYear:year];
	[weekBeforeLastDayOfYearComponents setMonth:12];
	[weekBeforeLastDayOfYearComponents setDay:24];
	NSDate *weekBeforeLastDayOfYear = [[NSCalendar currentCalendar] dateFromComponents:weekBeforeLastDayOfYearComponents];
	
	NSInteger weekBeforeLastDayWeek = [[[NSCalendar currentCalendar]
		components:NSWeekCalendarUnit
		fromDate:weekBeforeLastDayOfYear
	] week];
	
	return (lastDayWeek > weekBeforeLastDayWeek) ? lastDayWeek : weekBeforeLastDayWeek;
}


// get number representing the absolute value of the
// difference between two dates in logical weeks (e.g. would
// return 1 if given this sunday and next week's monday,
// assuming (for the sake of this example) that the week
// starts on monday)
NSInteger getWeekDiff(NSDate *date1, NSDate *date2)
{
	if (date1 == nil || date2 == nil)
		return 0;
	
	NSDateComponents *components1 = [[NSCalendar currentCalendar]
		components:NSWeekCalendarUnit|NSYearCalendarUnit
		fromDate:date1
	];
	NSDateComponents *components2 = [[NSCalendar currentCalendar]
		components:NSWeekCalendarUnit|NSYearCalendarUnit
		fromDate:date2
	];
	
	NSInteger week1 = [components1 week];
	NSInteger week2 = [components2 week];
	NSInteger year1 = [components1 year];
	NSInteger year2 = [components2 year];
	
	NSInteger earlierDateYear;
	NSInteger earlierDateWeek;
	NSInteger laterDateYear;
	NSInteger laterDateWeek;
	if (year1 < year2)
	{
		earlierDateYear = year1;
		earlierDateWeek = week1;
		laterDateYear = year2;
		laterDateWeek = week2;
	}
	else
	{
		earlierDateYear = year2;
		earlierDateWeek = week2;
		laterDateYear = year1;
		laterDateWeek = week1;
	}
	
	// check if week numbers are from the same year (the week number
	// of the last days in a year is often week #1 of the next
	// year) -- if so, they are directly comparable
	if ((year1 == year2) ||
		(abs(year1-year2)==1 && earlierDateWeek==1))
		return abs(week2-week1);
	
	// if there is more than one year between the dates, get the
	// total number of weeks in the years between
	NSInteger numWeeksInYearsBetween = 0;
	if (abs(year1-year2) > 1)
	{
		NSInteger i;
		for (i = earlierDateYear+1; i < laterDateYear; i++)
		{
			numWeeksInYearsBetween += getNumWeeksInYear(i);
		}
	}
	
	NSInteger numWeeksInEarlierDatesYear = getNumWeeksInYear(earlierDateYear);
	
	return (laterDateWeek+(numWeeksInEarlierDatesYear-earlierDateWeek))+numWeeksInYearsBetween;
}










// whether propertyName is ok to be printed, based on a set of property
// names to be included and a set of property names to be excluded
BOOL shouldPrintProperty(NSString *propertyName, NSSet *inclusionsSet, NSSet *exclusionsSet)
{
	if (propertyName == nil || (inclusionsSet == nil && exclusionsSet == nil))
		return YES;
	
	BOOL retVal = YES;
	
	if (inclusionsSet != nil)
		if (![inclusionsSet containsObject:propertyName])
			retVal = NO;
	
	if (retVal == YES && exclusionsSet != nil)
		if ([exclusionsSet containsObject:propertyName] || [exclusionsSet containsObject:@"*"])
			retVal = NO;
	
	return retVal;
}






// returns a formatted date+time
NSString* dateStr(NSDate *date, BOOL includeDate, BOOL includeTime)
{
	if (date == nil || (!includeDate && !includeTime))
		return @"";
	
	NSCalendarDate *calDate = [date dateWithCalendarFormat:nil timeZone:nil];
	
	NSString *outputDate = nil;
	NSString *outputTime = nil;
	
	if (includeDate)
	{
		if (displayRelativeDates &&
			datesRepresentSameDay(calDate, now))
			outputDate = localizedStr(@"today");
		else if (displayRelativeDates &&
				datesRepresentSameDay(calDate, [now dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0]))
			outputDate = localizedStr(@"tomorrow");
		else if (displayRelativeDates &&
				datesRepresentSameDay(calDate, [now dateByAddingYears:0 months:0 days:2 hours:0 minutes:0 seconds:0]))
			outputDate = localizedStr(@"dayAfterTomorrow");
		else if (displayRelativeDates &&
				datesRepresentSameDay(calDate, [now dateByAddingYears:0 months:0 days:-1 hours:0 minutes:0 seconds:0]))
			outputDate = localizedStr(@"yesterday");
		else if (displayRelativeDates &&
				datesRepresentSameDay(calDate, [now dateByAddingYears:0 months:0 days:-2 hours:0 minutes:0 seconds:0]))
			outputDate = localizedStr(@"dayBeforeYesterday");
		else
		{
			NSString *useDateFormatStr = dateFormatStr;
			
			// implement the "relative week" date format specifier
			NSRange relativeWeekFormatSpecifierRange = [useDateFormatStr rangeOfString:kRelativeWeekFormatSpecifier];
			if (relativeWeekFormatSpecifierRange.location != NSNotFound)
			{
				NSInteger weekDiff = getWeekDiff(now, date);
				if ([now compare:date] == NSOrderedDescending)
					weekDiff *= -1; // in the past
				
				NSString *weekDiffStr = nil;
				if (weekDiff < -1)
					weekDiffStr = [NSString stringWithFormat:localizedStr(@"xWeeksAgo"), abs(weekDiff)];
				else if (weekDiff == -1)
					weekDiffStr = localizedStr(@"lastWeek");
				else if (weekDiff == 0)
					weekDiffStr = localizedStr(@"thisWeek");
				else if (weekDiff == 1)
					weekDiffStr = localizedStr(@"nextWeek");
				else if (weekDiff > 1)
					weekDiffStr = [NSString stringWithFormat:localizedStr(@"xWeeksFromNow"), weekDiff];
				
				if (weekDiffStr != nil)
					useDateFormatStr = [useDateFormatStr
						stringByReplacingCharactersInRange:relativeWeekFormatSpecifierRange
						withString:weekDiffStr
					];
			}
			
			outputDate = [date
				descriptionWithCalendarFormat:useDateFormatStr
				timeZone:nil
				locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
			];
		}
	}
	
	if (includeTime)
		outputTime = [date
			descriptionWithCalendarFormat:timeFormatStr
			timeZone:nil
			locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
		];
	
	if (outputDate != nil && outputTime == nil)
		return outputDate;
	else if (outputDate == nil && outputTime != nil)
		return outputTime;
	else
		return [NSString stringWithFormat:@"%@%@%@", outputDate, dateTimeSeparatorStr, outputTime];
}





// returns the ANSI escape string for formatting a property name,
// or an empty string for no formatting
NSString* getPropNameANSIEscapeStr(NSString *propName)
{
	if (propName == nil)
		return @"";
	
	return kANSIEscapeCyan;
}



// returns the ANSI escape string for formatting a property value,
// or an empty string for no formatting
NSString* getPropValueANSIEscapeStr(NSString *propName, NSString *propValue)
{
	if (propName == nil)
		return @"";
	else if (propName == kPropName_datetime)
		return kANSIEscapeYellow;
	else if (propName == kPropName_priority)
	{
		if (propValue != nil)
		{
			if ([propValue isEqual:localizedStr(kPriorityStr_high)])
				return kANSIEscapeRed;
			else if ([propValue isEqual:localizedStr(kPriorityStr_medium)])
				return kANSIEscapeYellow;
			else if ([propValue isEqual:localizedStr(kPriorityStr_low)])
				return kANSIEscapeGreen;
		}
	}
	
	return @"";
}






// returns a pretty-printed string representation of the specified event property
NSString* getEventPropStr(NSString *propName, CalEvent *event, int printOptions, NSCalendarDate *contextDay)
{
	if (event != nil)
	{
		BOOL formatOutput = (printOptions & PRINT_OPTION_FORMAT_OUTPUT);
		NSString *thisPropOutputName = nil;
		NSString *thisPropOutputValue = nil;
		
		if ([propName isEqualToString:kPropName_title])
		{
			if ([[[event calendar] type] isEqualToString:CalCalendarTypeBirthday])
			{
				// special case for events in the Birthdays calendar (they don't seem to have titles
				// so we have to use the URI to find the ABPerson from the Address Book
				// and print their name from there)
				
				NSString *personId = [[NSString stringWithFormat:@"%@", [event url]] stringByReplacingOccurrencesOfString:@"addressbook://" withString:@""];
				ABRecord *person = [[ABAddressBook sharedAddressBook] recordForUniqueId:personId];
				
				if (person != nil)
				{
					if ([person isMemberOfClass: [ABPerson class]])
					{
						NSString *contactFullName = [[[person valueForProperty:kABFirstNameProperty] stringByAppendingString:@" "] stringByAppendingString:[person valueForProperty:kABLastNameProperty]];
						NSString *thisTitle = [NSString stringWithFormat:localizedStr(@"someonesBirthday"), contactFullName];
						if (printOptions & PRINT_OPTION_CALENDAR_AGNOSTIC)
							thisPropOutputValue = thisTitle;
						else
							thisPropOutputValue = [NSString stringWithFormat: @"%@ (%@)", thisTitle, [[event calendar] title]];
					}
				}
			}
			else
			{
				if (printOptions & PRINT_OPTION_CALENDAR_AGNOSTIC)
					thisPropOutputValue = [event title];
				else
					thisPropOutputValue = [NSString stringWithFormat: @"%@ (%@)", [event title], [[event calendar] title]];
			}
		}
		else if ([propName isEqualToString:kPropName_location])
		{
			thisPropOutputName = [localizedStr(@"location") stringByAppendingString:@":"];
			
			if ([event location] != nil && ![[[event location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
				thisPropOutputValue = [event location];
		}
		else if ([propName isEqualToString:kPropName_notes])
		{
			thisPropOutputName = [localizedStr(@"notes") stringByAppendingString:@":"];
			
			if ([event notes] != nil && ![[[event notes] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
				thisPropOutputValue = [[event notes]
					stringByReplacingOccurrencesOfString:@"\n"
					withString:[NSString stringWithFormat:@"\n%@ %@",prefixStrIndent,getWhitespace([thisPropOutputName length])]
				];
		}
		else if ([propName isEqualToString:kPropName_url])
		{
			thisPropOutputName = [localizedStr(@"url") stringByAppendingString:@":"];
			
			if ([event url] != nil &&
				![[[event calendar] type] isEqualToString:CalCalendarTypeBirthday])
				thisPropOutputValue = [NSString stringWithFormat: @"%@", [event url]];
		}
		else if ([propName isEqualToString:kPropName_datetime])
		{
			if ([[[event calendar] type] isEqualToString:CalCalendarTypeBirthday])
			{
				if (!(printOptions & PRINT_OPTION_SINGLE_DAY))
					thisPropOutputValue = dateStr([event startDate], true, false);
			}
			else
			{
				BOOL singleDayContext = (printOptions & PRINT_OPTION_SINGLE_DAY);
				
				if ( !singleDayContext || (singleDayContext && ![event isAllDay]) )
				{
					if ([[event startDate] isEqualToDate:[event endDate]])
						thisPropOutputValue = dateStr([event startDate], (!(printOptions & PRINT_OPTION_SINGLE_DAY)), true);
					else
					{
						if (printOptions & PRINT_OPTION_SINGLE_DAY)
						{
							BOOL startsOnContextDay = datesRepresentSameDay(contextDay, [[event startDate] dateWithCalendarFormat:nil timeZone:nil]);
							BOOL endsOnContextDay = datesRepresentSameDay(contextDay, [[event endDate] dateWithCalendarFormat:nil timeZone:nil]);
							if (startsOnContextDay && endsOnContextDay)
								thisPropOutputValue = [NSString stringWithFormat: @"%@ - %@",
										dateStr([event startDate], false, true),
										dateStr([event endDate], false, true)
										];
							else if (startsOnContextDay)
								thisPropOutputValue = [NSString stringWithFormat: @"%@ - ...",
										dateStr([event startDate], false, true)
										];
							else if (endsOnContextDay)
								thisPropOutputValue = [NSString stringWithFormat: @"... - %@",
										dateStr([event endDate], false, true)
										];
						}
						else
						{
							if ([event isAllDay])
							{
								NSInteger daysDiff;
								[[[event endDate] dateWithCalendarFormat:nil timeZone:nil]
									years:NULL months:NULL days:&daysDiff hours:NULL minutes:NULL seconds:NULL
									sinceDate:[[event startDate] dateWithCalendarFormat:nil timeZone:nil]
								];
								
								if (daysDiff > 1)
								{
									// all-day events technically span from <start day> at 00:00 to <end day+1> at 00:00 even though
									// we want them displayed as only spanning from <start day> to <end day>
									NSCalendarDate *endDateMinusOneDay = [[[event endDate] dateWithCalendarFormat:nil timeZone:nil] dateByAddingYears:0 months:0 days:-1 hours:0 minutes:0 seconds:0];
									thisPropOutputValue = [NSString stringWithFormat: @"%@ - %@",
											dateStr([event startDate], true, false),
											dateStr(endDateMinusOneDay, true, false)
											];
								}
								else
									thisPropOutputValue = dateStr([event startDate], true, false);
							}
							else
							{
								NSString *startDateFormattedStr = dateStr([event startDate], true, true);
								NSString *endDateFormattedStr;
								if (datesRepresentSameDay([[event startDate] dateWithCalendarFormat:nil timeZone:nil], [[event endDate] dateWithCalendarFormat:nil timeZone:nil]))
									endDateFormattedStr = dateStr([event endDate], false, true);
								else
									endDateFormattedStr = dateStr([event endDate], true, true);
								thisPropOutputValue = [NSString stringWithFormat: @"%@ - %@", startDateFormattedStr, endDateFormattedStr];
							}
						}
					}
				}
			}
		}
		
		
		if (thisPropOutputName != nil && formatOutput)
			thisPropOutputName = [NSString stringWithFormat:@"%@%@%@", getPropNameANSIEscapeStr(propName), thisPropOutputName, kANSIEscapeReset];
		
		if (thisPropOutputValue != nil)
		{
			if (formatOutput)
				thisPropOutputValue = [[getPropValueANSIEscapeStr(propName, thisPropOutputValue) stringByAppendingString:thisPropOutputValue] stringByAppendingString:kANSIEscapeReset];
			thisPropOutputValue = [thisPropOutputValue stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
		}
		
		if (thisPropOutputName == nil && thisPropOutputValue != nil)
			return [NSString stringWithFormat: @"%@\n", thisPropOutputValue];
		else if (thisPropOutputName != nil && thisPropOutputValue != nil)
			return [NSString stringWithFormat: @"%@ %@\n", thisPropOutputName, thisPropOutputValue];
	}
	return nil;
}




// pretty-prints out the specified event
void printCalEvent(CalEvent *event, int printOptions, NSCalendarDate *contextDay)
{
	if (event != nil)
	{
		BOOL formatOutput = (printOptions & PRINT_OPTION_FORMAT_OUTPUT);
		
		BOOL firstPrintedProperty = YES;
		
		for (NSString *thisProp in propertyOrder)
		{
			if (shouldPrintProperty(thisProp, includedEventProperties, excludedEventProperties))
			{
				NSString *thisPropStr = getEventPropStr(thisProp, event, printOptions, contextDay);
				if (thisPropStr != nil && ![thisPropStr isEqualToString:@""])
				{
					if (formatOutput && firstPrintedProperty)
						NSPrint(kANSIEscapeBold);
					
					NSString *prefixStr = (firstPrintedProperty) ? prefixStrBullet : prefixStrIndent;
					
					NSPrint(prefixStr);
					NSPrint(thisPropStr);
					
					if (formatOutput && firstPrintedProperty)
						NSPrint(kANSIEscapeReset);
					
					firstPrintedProperty = NO;
				}
			}
		}
	}
}










// returns a pretty-printed string representation of the specified task property
NSString* getTaskPropStr(NSString *propName, CalTask *task, int printOptions)
{
	if (task != nil)
	{
		BOOL formatOutput = (printOptions & PRINT_OPTION_FORMAT_OUTPUT);
		NSString *thisPropOutputName = nil;
		NSString *thisPropOutputValue = nil;
		
		if ([propName isEqualToString:kPropName_title])
		{
			if (printOptions & PRINT_OPTION_CALENDAR_AGNOSTIC)
				thisPropOutputValue = [task title];
			else
				thisPropOutputValue = [NSString stringWithFormat: @"%@ (%@)", [task title], [[task calendar] title]];
		}
		else if ([propName isEqualToString:kPropName_notes])
		{
			thisPropOutputName = [localizedStr(@"notes") stringByAppendingString:@":"];
			
			if ([task notes] != nil && ![[[task notes] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
				thisPropOutputValue = [[task notes]
					stringByReplacingOccurrencesOfString:@"\n"
					withString:[NSString stringWithFormat:@"\n%@ %@",prefixStrIndent,getWhitespace([thisPropOutputName length])]
				];
		}
		else if ([propName isEqualToString:kPropName_url])
		{
			thisPropOutputName = [localizedStr(@"url") stringByAppendingString:@":"];
			
			if ([task url] != nil)
				thisPropOutputValue = [NSString stringWithFormat:@"%@", [task url]];
		}
		else if ([propName isEqualToString:kPropName_datetime])
		{
			thisPropOutputName = [localizedStr(@"dueDate") stringByAppendingString:@":"];
			
			if ([task dueDate] != nil && !(printOptions & PRINT_OPTION_SINGLE_DAY))
				thisPropOutputValue = dateStr([task dueDate], true, false);
		}
		else if ([propName isEqualToString:kPropName_priority])
		{
			thisPropOutputName = [localizedStr(@"priority") stringByAppendingString:@":"];
			
			if ([task priority] != CalPriorityNone)
			{
				switch([task priority])
				{
					case CalPriorityHigh:
						thisPropOutputValue = localizedStr(kPriorityStr_high);
						break;
					case CalPriorityMedium:
						thisPropOutputValue = localizedStr(kPriorityStr_medium);
						break;
					case CalPriorityLow:
						thisPropOutputValue = localizedStr(kPriorityStr_low);
						break;
					default:
						thisPropOutputValue = [NSString stringWithFormat:@"%d", [task priority]];
						break;
				}
			}
		}
		
		
		if (thisPropOutputName != nil && formatOutput)
			thisPropOutputName = [NSString stringWithFormat:@"%@%@%@", getPropNameANSIEscapeStr(propName), thisPropOutputName, kANSIEscapeReset];
		
		if (thisPropOutputValue != nil)
		{
			if (formatOutput)
				thisPropOutputValue = [[getPropValueANSIEscapeStr(propName, thisPropOutputValue) stringByAppendingString:thisPropOutputValue] stringByAppendingString:kANSIEscapeReset];
			thisPropOutputValue = [thisPropOutputValue stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
		}
		
		if (thisPropOutputName == nil && thisPropOutputValue != nil)
			return [NSString stringWithFormat: @"%@\n", thisPropOutputValue];
		else if (thisPropOutputName != nil && thisPropOutputValue != nil)
			return [NSString stringWithFormat: @"%@ %@\n", thisPropOutputName, thisPropOutputValue];
	}
	return nil;
}




// pretty-prints out the specified task
void printCalTask(CalTask *task, int printOptions)
{
	if (task != nil)
	{
		BOOL formatOutput = (printOptions & PRINT_OPTION_FORMAT_OUTPUT);
		
		BOOL firstPrintedProperty = YES;
		
		for (NSString *thisProp in propertyOrder)
		{
			if (shouldPrintProperty(thisProp, includedTaskProperties, excludedTaskProperties))
			{
				NSString *thisPropStr = getTaskPropStr(thisProp, task, printOptions);
				if (thisPropStr != nil && ![thisPropStr isEqualToString:@""])
				{
					if (formatOutput && firstPrintedProperty)
						NSPrint(kANSIEscapeBold);
					
					NSString *prefixStr = (firstPrintedProperty) ? prefixStrBullet : prefixStrIndent;
					// if task's due date is in the past, use ! in place of the bullet point (*)
					if (firstPrintedProperty && [task dueDate] != nil &&
						[now compare:[task dueDate]] == NSOrderedDescending)
						prefixStr = prefixStrBulletAlert;
					
					NSPrint(prefixStr);
					NSPrint(thisPropStr);
					
					if (formatOutput && firstPrintedProperty)
						NSPrint(kANSIEscapeReset);
					
					firstPrintedProperty = NO;
				}
			}
		}
	}
}





// prints a bunch of sections each of which has a title and some calendar
// items.
// each object in the sections array must be an NSDictionary with keys
// sectionTitle (NSString) and sectionItems (NSArray of CalCalendarItems.)
void printItemSections(NSArray *sections, int printOptions)
{
	BOOL formatOutput = (printOptions & PRINT_OPTION_FORMAT_OUTPUT);
	BOOL titlePrintedForCurrentSection;
	BOOL currentIsFirstPrintedSection = YES;
	
	NSDictionary *sectionDict;
	for (sectionDict in sections)
	{
		titlePrintedForCurrentSection = NO;
		
		NSString *sectionTitle = [sectionDict objectForKey:kSectionDictKey_title];
		NSArray *sectionItems = [sectionDict objectForKey:kSectionDictKey_items];
		
		CalCalendarItem *item;
		for (item in sectionItems)
		{
			if (!titlePrintedForCurrentSection)
			{
				if (!currentIsFirstPrintedSection)
					NSPrint(@"\n");
				
				if (formatOutput)
					NSPrint(kSectionTitleANSIEscape);
				
				NSPrint(@"%@:\n%@\n", sectionTitle, sectionSeparatorStr);
				
				if (formatOutput)
					NSPrint(kANSIEscapeReset);
				
				titlePrintedForCurrentSection = YES;
				currentIsFirstPrintedSection = NO;
			}
			
			if ([item isKindOfClass:[CalEvent class]])
			{
				NSCalendarDate *contextDay = [sectionDict objectForKey:kSectionDictKey_eventsContextDay];
				if (contextDay == nil)
					contextDay = now;
				printCalEvent((CalEvent*)item, printOptions, contextDay);
			}
			else if ([item isKindOfClass:[CalTask class]])
				printCalTask((CalTask*)item, printOptions);
		}
	}
}













int main(int argc, char *argv[])
{
	NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
	
	
	// set current datetime and day representations into globals
	now = [NSCalendarDate calendarDate];
	today = [NSCalendarDate
		dateWithYear:[now yearOfCommonEra]
		month:[now monthOfYear]
		day:[now dayOfMonth]
		hour:0 minute:0 second:0
		timeZone:[now timeZone]
	];
	
	
	// set default strings
	defaultStringsDict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"title",			@"title",
		@"location",		@"location",
		@"notes", 			@"notes",
		@"url", 			@"url",
		@"due",		 		@"dueDate",
		@"no due date",		@"noDueDate",
		@"priority", 		@"priority",
		@"%@'s Birthday",	@"someonesBirthday",
		@"today", 					@"today",
		@"tomorrow", 				@"tomorrow",
		@"yesterday", 				@"yesterday",
		@"day before yesterday",	@"dayBeforeYesterday",
		@"day after tomorrow",		@"dayAfterTomorrow",
		@"%d days ago",				@"xDaysAgo",
		@"%d days from now",		@"xDaysFromNow",
		@"this week",				@"thisWeek",
		@"last week",				@"lastWeek",
		@"next week",				@"nextWeek",
		@"%d weeks ago",			@"xWeeksAgo",
		@"%d weeks from now",		@"xWeeksFromNow",
		@"high",		@"high",
		@"medium",		@"medium",
		@"low",			@"low",
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
	NSString *arg_strEncoding = nil;
	
	BOOL arg_output_is_uncompletedTasks = NO;
	BOOL arg_output_is_eventsToday = NO;
	BOOL arg_output_is_eventsNow = NO;
	BOOL arg_output_is_eventsFromTo = NO;
	NSString *arg_eventsFrom = nil;
	NSString *arg_eventsTo = nil;
	
	
	
	// read localization configuration file
	
	l10nStringsDict = nil;
	NSString *l10nFilePath = [kL10nFilePath stringByExpandingTildeInPath];
	BOOL l10nFileIsDir;
	BOOL l10nFileExists = [[NSFileManager defaultManager] fileExistsAtPath:l10nFilePath isDirectory:&l10nFileIsDir];
	if (l10nFileExists && !l10nFileIsDir)
	{
		l10nStringsDict = [NSDictionary dictionaryWithContentsOfFile:l10nFilePath];
		
		if (l10nStringsDict == nil)
		{
			NSPrintErr(@"* Error in localization file \"%@\":\ncan not recognize file format -- must be a valid property list\nwith a structure specified in the icalBuddyLocalization man page.\nTry running \"man icalBuddyLocalization\" to read the relevant documentation\nand \"plutil '%@'\" to validate the\nfile's property list syntax.\n", l10nFilePath, l10nFilePath);
			return(10);
		}
		
		// validate some specific keys in localization config
		BOOL l10nFileIsValid = YES;
		NSDictionary *l10nKeysRequiringSubstrings = [NSDictionary dictionaryWithObjectsAndKeys:
			@"%d", @"xWeeksFromNow",
			@"%d", @"xWeeksAgo",
			@"%d", @"xDaysAgo",
			@"%d", @"xDaysFromNow",
			@"%@", @"someonesBirthday",
			nil
		];
		NSString *thisKey;
		NSString *thisVal;
		NSString *requiredSubstring;
		for (thisKey in [l10nKeysRequiringSubstrings allKeys])
		{
			requiredSubstring = [l10nKeysRequiringSubstrings objectForKey:thisKey];
			thisVal = [l10nStringsDict objectForKey:thisKey];
			if (thisVal != nil && [thisVal rangeOfString:requiredSubstring].location == NSNotFound)
			{
				NSPrintErr(@"* Error in localization file \"%@\"\n  (key: \"%@\", value: \"%@\"):\n  value must include %@ to indicate position for a variable.\n", l10nFilePath, thisKey, thisVal, requiredSubstring);
				l10nFileIsValid = NO;
			}
		}
		if (!l10nFileIsValid)
			return(10);
	}
	
	
	
	
	// get arguments
	
	if (argc > 1)
	{
		arg_output = [NSString stringWithCString: argv[argc-1] encoding: NSASCIIStringEncoding];
		
		arg_output_is_uncompletedTasks = [arg_output isEqualToString:@"uncompletedTasks"];
		arg_output_is_eventsToday = [arg_output hasPrefix:@"eventsToday"];
		arg_output_is_eventsNow = [arg_output isEqualToString:@"eventsNow"];
		
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
	
	
	int i;
	for (i = 0; i < argc; i++)
	{
		if ((strcmp(argv[i], "-sc") == 0) || (strcmp(argv[i], "--separateByCalendar") == 0))
			arg_separateByCalendar = YES;
		else if ((strcmp(argv[i], "-sd") == 0) || (strcmp(argv[i], "--separateByDate") == 0))
			arg_separateByDate = YES;
		else if ((strcmp(argv[i], "-u") == 0) || (strcmp(argv[i], "--checkForUpdates") == 0))
			arg_updatesCheck = YES;
		else if ((strcmp(argv[i], "-V") == 0) || (strcmp(argv[i], "--version") == 0))
			arg_printVersion = YES;
		else if ((strcmp(argv[i], "-n") == 0) || (strcmp(argv[i], "--includeOnlyEventsFromNowOn") == 0))
			arg_includeOnlyEventsFromNowOn = YES;
		else if ((strcmp(argv[i], "-f") == 0) || (strcmp(argv[i], "--formatOutput") == 0))
			arg_useFormatting = YES;
		else if ((strcmp(argv[i], "-nc") == 0) || (strcmp(argv[i], "--noCalendarNames") == 0))
			arg_noCalendarNames = YES;
		else if ((strcmp(argv[i], "-nrd") == 0) || (strcmp(argv[i], "--noRelativeDates") == 0))
			displayRelativeDates = NO;
		else if (((strcmp(argv[i], "-i") == 0) || (strcmp(argv[i], "--indent") == 0)) && (i+1 < argc))
			prefixStrIndent = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
		else if (((strcmp(argv[i], "-b") == 0) || (strcmp(argv[i], "--bullet") == 0)) && (i+1 < argc))
			prefixStrBullet = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
		else if (((strcmp(argv[i], "-ab") == 0) || (strcmp(argv[i], "--alertBullet") == 0)) && (i+1 < argc))
			prefixStrBulletAlert = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
		else if (((strcmp(argv[i], "-ss") == 0) || (strcmp(argv[i], "--sectionSeparator") == 0)) && (i+1 < argc))
			sectionSeparatorStr = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
		else if (((strcmp(argv[i], "-tf") == 0) || (strcmp(argv[i], "--timeFormat") == 0)) && (i+1 < argc))
			timeFormatStr = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
		else if (((strcmp(argv[i], "-df") == 0) || (strcmp(argv[i], "--dateFormat") == 0)) && (i+1 < argc))
			dateFormatStr = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
		else if (((strcmp(argv[i], "-dts") == 0) || (strcmp(argv[i], "--dateTimeSeparator") == 0)) && (i+1 < argc))
			dateTimeSeparatorStr = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
		else if (((strcmp(argv[i], "-iep") == 0) || (strcmp(argv[i], "--includeEventProps") == 0)) && (i+1 < argc))
			includedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding]);
		else if (((strcmp(argv[i], "-eep") == 0) || (strcmp(argv[i], "--excludeEventProps") == 0)) && (i+1 < argc))
			excludedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding]);
		else if (((strcmp(argv[i], "-itp") == 0) || (strcmp(argv[i], "--includeTaskProps") == 0)) && (i+1 < argc))
			includedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding]);
		else if (((strcmp(argv[i], "-etp") == 0) || (strcmp(argv[i], "--excludeTaskProps") == 0)) && (i+1 < argc))
			excludedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding]);
	}
	
	NSString *includeCalsStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"ic"];
	if (includeCalsStr == nil)
		includeCalsStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"-includeCals"];
	if (includeCalsStr != nil)
		arg_includeCals = arrayFromCommaSeparatedStringTrimmingWhitespace(includeCalsStr);
	
	NSString *excludeCalsStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"ec"];
	if (excludeCalsStr == nil)
		excludeCalsStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"-excludeCals"];
	if (excludeCalsStr != nil)
		arg_excludeCals = arrayFromCommaSeparatedStringTrimmingWhitespace(excludeCalsStr);
	
	NSString *propertyOrderStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"po"];
	if (propertyOrderStr == nil)
		propertyOrderStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"-propertyOrder"];
	if (propertyOrderStr != nil)
	{
		// if property order is specified, filter out property names that are not allowed (the allowed
		// ones are all included in the NSArray specified by the kDefaultPropertyOrder macro definition)
		// and then add to the list the omitted property names in the default order
		NSArray *specifiedPropertyOrder = arrayFromCommaSeparatedStringTrimmingWhitespace(propertyOrderStr);
		NSMutableArray *tempPropertyOrder = [NSMutableArray arrayWithCapacity:10];
		[tempPropertyOrder addObjectsFromArray:[specifiedPropertyOrder filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", kDefaultPropertyOrder]]];
		for (NSString *thisPropertyInDefaultOrder in kDefaultPropertyOrder)
		{
			if (![tempPropertyOrder containsObject:thisPropertyInDefaultOrder])
				[tempPropertyOrder addObject:thisPropertyInDefaultOrder];
		}
		propertyOrder = tempPropertyOrder;
	}
	else
		propertyOrder = kDefaultPropertyOrder;
	
	
	arg_strEncoding = [[NSUserDefaults standardUserDefaults] stringForKey:@"-strEncoding"];
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
			NSPrintErr(
				@"\nError: Invalid string encoding argument: \"%@\". Run \"icalBuddy strEncodings\" to see all the possible values. Using default encoding \"%@\".\n\n",
				arg_strEncoding,
				[NSString localizedNameOfStringEncoding: outputStrEncoding]
			);
	}
	
	
	
	// ------------------------------------------------------------------
	// ------------------------------------------------------------------
	// print version and exit
	// ------------------------------------------------------------------
	if (arg_printVersion)
	{
		NSPrint(@"%@\n", versionNumber());
	}
	// ------------------------------------------------------------------
	// ------------------------------------------------------------------
	// check for updates
	// ------------------------------------------------------------------
	else if (arg_updatesCheck)
	{
		NSPrint(@"Checking for updates... ");
		
		NSURL *url = kVersionCheckURL;
		NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
		
		NSHTTPURLResponse *response;
		NSError *error;
		[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		
		if (error == nil && response != nil)
		{
			NSInteger statusCode = [response statusCode];
			if (statusCode >= 400)
			{
				NSPrint(@"...HTTP connection failed.\n\nStatus code %d: \"%@\"\n\n",
						statusCode, [NSHTTPURLResponse localizedStringForStatusCode:statusCode]);
			}
			else
			{
				NSString *latestVersionString = [[response allHeaderFields] valueForKey:@"Orghassegsoftwarelatestversion"];
				NSString *currentVersionString = versionNumber();
				
				if (latestVersionString == nil)
					NSPrintErr(@"...failed.\n\nError reading latest version number from HTTP header field.\n\n");
				else
				{
					if (versionNumberCompare(currentVersionString, latestVersionString) == NSOrderedAscending)
					{
						NSPrint(@"...update found! (latest: %@  current: %@)\n\n", latestVersionString, currentVersionString);
						NSPrint(@"Navigate to the following URL to see the release notes and download the latest version:\n\n%@?currentversion=%@\n\n", kAppSiteURLPrefix, currentVersionString);
						char inputChar;
						while(inputChar != 'y' && inputChar != 'n' && inputChar != 'Y' && inputChar != 'N' && inputChar != '\n')
						{
							NSPrint(@"Do you want to navigate to this URL now? [y/n] ");
							scanf("%s&*c",&inputChar);
						}
						
						if (inputChar == 'y' || inputChar == 'Y')
							[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@?currentversion=%@", kAppSiteURLPrefix, currentVersionString]]];
					}
					else
						NSPrint(@"...you're up to date! (latest: %@  current: %@)\n\n", latestVersionString, currentVersionString);
				}
			}
		}
		else
		{
			NSPrintErr(@"...connection failed.\n\nError: - %@ %@\n\n",
				[error localizedDescription],
				[[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
		}
	}
	// ------------------------------------------------------------------
	// ------------------------------------------------------------------
	// print possible values for the string encoding argument and exit
	// ------------------------------------------------------------------
	else if ([arg_output isEqualToString:@"strEncodings"])
	{
		NSPrint(@"\nAvailable String encodings (you can use one of these\nas an argument to the --strEncoding option):\n\n");
		const NSStringEncoding *availableEncoding = [NSString availableStringEncodings];
		while(*availableEncoding != 0)
		{
			NSPrint(@"%@\n", [NSString localizedNameOfStringEncoding: *availableEncoding]);
			availableEncoding++;
		}
		NSPrint(@"\n");
	}
	// ------------------------------------------------------------------
	// ------------------------------------------------------------------
	// print all calendars
	// ------------------------------------------------------------------
	else if ([arg_output isEqualToString:@"calendars"])
	{
		NSArray *allCalendars = [[CalCalendarStore defaultCalendarStore] calendars];
		
		CalCalendar *cal;
		for (cal in allCalendars)
		{
			NSPrint(@"* %@\n  uid: %@\n", [cal title], [cal uid]);
		}
	}
	// ------------------------------------------------------------------
	// ------------------------------------------------------------------
	// print events or tasks
	// ------------------------------------------------------------------
	else if (arg_output_is_eventsToday || arg_output_is_eventsNow || arg_output_is_eventsFromTo || arg_output_is_uncompletedTasks)
	{
		BOOL printingEvents = (arg_output_is_eventsToday || arg_output_is_eventsNow || arg_output_is_eventsFromTo);
		BOOL printingAlsoPastEvents = (arg_output_is_eventsFromTo);
		BOOL printingTasks = arg_output_is_uncompletedTasks;
		
		// get all calendars
		NSMutableArray *allCalendars = [NSMutableArray arrayWithCapacity:10];
		[allCalendars addObjectsFromArray: [[CalCalendarStore defaultCalendarStore] calendars]];
		
		// filter calendars to use:
		// - first include what has been specified to be included,
		// - then exclude what has been specified to be excluded
		if (arg_includeCals != nil)
			[allCalendars filterUsingPredicate: [NSPredicate predicateWithFormat:@"(uid IN %@) OR (title IN %@)", arg_includeCals, arg_includeCals]];
		if (arg_excludeCals != nil)
			[allCalendars filterUsingPredicate: [NSPredicate predicateWithFormat:@"(NOT(uid IN %@)) AND (NOT(title IN %@))", arg_excludeCals, arg_excludeCals]];
		
		int tasks_printOptions = PRINT_OPTION_NONE;
		int events_printOptions = PRINT_OPTION_NONE;
		NSArray *uncompletedTasks = nil;
		NSArray *eventsArr = nil;
		
		// prepare to print events
		if (printingEvents)
		{
			// default print options
			events_printOptions = 
				PRINT_OPTION_SINGLE_DAY | 
				(arg_useFormatting ? PRINT_OPTION_FORMAT_OUTPUT : PRINT_OPTION_NONE) |
				(arg_noCalendarNames ? PRINT_OPTION_CALENDAR_AGNOSTIC : PRINT_OPTION_NONE);
			
			// get start and end dates for predicate
			NSCalendarDate *eventsDateRangeStart = nil;
			NSCalendarDate *eventsDateRangeEnd = nil;
			if (arg_output_is_eventsToday)
			{
				eventsDateRangeStart = [NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:0 minute:0 second:0 timeZone:[now timeZone]];
				eventsDateRangeEnd = [NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:23 minute:59 second:59 timeZone:[now timeZone]];
			}
			else if (arg_output_is_eventsNow)
			{
				eventsDateRangeStart = now;
				eventsDateRangeEnd = now;
			}
			else if (arg_output_is_eventsFromTo)
			{
				eventsDateRangeStart = [NSCalendarDate dateWithString:arg_eventsFrom];
				eventsDateRangeEnd = [NSCalendarDate dateWithString:arg_eventsTo];
				
				if (eventsDateRangeStart == nil)
				{
					NSPrintErr(@"Error: invalid start date: '%@'\nDates must be specified in the format: \"YYYY-MM-DD HH:MM:SS ±HHMM\"\n\n", arg_eventsFrom);
					return(0);
				}
				else if (eventsDateRangeEnd == nil)
				{
					NSPrintErr(@"Error: invalid end date: '%@'\nDates must be specified in the format: \"YYYY-MM-DD HH:MM:SS ±HHMM\"\n\n", arg_eventsTo);
					return(0);
				}
				
				if ([eventsDateRangeStart compare:eventsDateRangeEnd] == NSOrderedDescending)
				{
					// start date occurs before end date --> swap them
					NSCalendarDate *tempSwapDate = eventsDateRangeStart;
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
					eventsDateRangeEnd = [eventsDateRangeEnd dateByAddingYears:0 months:0 days:daysToAddToRange hours:0 minutes:0 seconds:0];
					events_printOptions &= ~PRINT_OPTION_SINGLE_DAY;
				}
			}
			
			// make predicate for getting all events between start and end dates + use it to get the events
			NSPredicate *eventsPredicate = [CalCalendarStore
				eventPredicateWithStartDate:((arg_includeOnlyEventsFromNowOn)?now:eventsDateRangeStart)
				endDate:eventsDateRangeEnd
				calendars:allCalendars
			];
			eventsArr = [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:eventsPredicate];
		}
		// prepare to print tasks
		else if (printingTasks)
		{
			// make predicate for uncompleted tasks in all calendars and use it to get the tasks
			NSPredicate *uncompletedTasksPredicate = [CalCalendarStore taskPredicateWithUncompletedTasks:allCalendars];
			uncompletedTasks = [[CalCalendarStore defaultCalendarStore] tasksWithPredicate:uncompletedTasksPredicate];
			
			// sort the tasks by priority
			uncompletedTasks = [uncompletedTasks sortedArrayUsingFunction:prioritySort context:NULL];
			
			// default print options
			tasks_printOptions = 
				(arg_useFormatting ? PRINT_OPTION_FORMAT_OUTPUT : PRINT_OPTION_NONE) |
				(arg_noCalendarNames ? PRINT_OPTION_CALENDAR_AGNOSTIC : PRINT_OPTION_NONE);
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
			NSMutableArray *byDateSections = [NSMutableArray arrayWithCapacity:[eventsArr count]];
			
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
					NSUInteger daysSpan = [[[NSCalendar currentCalendar]
						components:NSDayCalendarUnit
						fromDate:[anEvent startDate]
						toDate:[anEvent endDate]
						options:0
					] day];
					
					// the previous method call returns day spans that are one day too long for all-day events
					if ([anEvent isAllDay] && daysSpan > 0)
						daysSpan--;
					
					NSCalendarDate *thisEventStartDate = [[anEvent startDate] dateWithCalendarFormat:nil timeZone:nil];
					
					NSUInteger i;
					for (i = 0; i <= daysSpan; i++)
					{
						NSCalendarDate *thisEventStartDatePlusi = [thisEventStartDate
							dateByAddingYears:0 months:0 days:i hours:0 minutes:0 seconds:0
						];
						
						NSCalendarDate *dayToAdd = [NSCalendarDate
							dateWithYear:[thisEventStartDatePlusi yearOfCommonEra]
							month:[thisEventStartDatePlusi monthOfYear]
							day:[thisEventStartDatePlusi dayOfMonth]
							hour:0 minute:0 second:0
							timeZone:[thisEventStartDatePlusi timeZone]
						];
						
						NSComparisonResult dayToAddToNowComparisonResult = [dayToAdd compare:today];
						
						if (printingAlsoPastEvents ||
							dayToAddToNowComparisonResult == NSOrderedDescending ||
							dayToAddToNowComparisonResult == NSOrderedSame ||
							datesRepresentSameDay(now, dayToAdd)
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
						NSCalendarDate *thisTaskDueDate = [[aTask dueDate] dateWithCalendarFormat:nil timeZone:nil];
						NSCalendarDate *thisDueDay = [NSCalendarDate
							dateWithYear:[thisTaskDueDate yearOfCommonEra]
							month:[thisTaskDueDate monthOfYear]
							day:[thisTaskDueDate dayOfMonth]
							hour:0 minute:0 second:0
							timeZone:[thisTaskDueDate timeZone]
						];
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
			
			// sort the dates and leave NSNull ("no due date") at the bottom if it exists
			NSMutableArray *allDaysArr = [NSMutableArray arrayWithCapacity:[[allDays allKeys] count]];
			[allDaysArr addObjectsFromArray:[allDays allKeys]];
			[allDaysArr removeObjectIdenticalTo:[NSNull null]];
			[allDaysArr sortUsingSelector:@selector(compare:)];
			if ([allDays objectForKey:[NSNull null]] != nil)
				[allDaysArr addObject:[NSNull null]];
			
			id aDayKey;
			for (aDayKey in allDaysArr)
			{
				NSArray *thisSectionItems = [allDays objectForKey:aDayKey];
				NSCAssert((thisSectionItems != nil), @"thisSectionItems is nil");
				NSMutableDictionary *thisSectionDict = [NSMutableDictionary
					dictionaryWithObject:thisSectionItems
					forKey:kSectionDictKey_items
				];
				
				if (printingEvents && [aDayKey isKindOfClass:[NSCalendarDate class]])
					[thisSectionDict setObject:aDayKey forKey:kSectionDictKey_eventsContextDay];
				
				NSString *thisSectionTitle = nil;
				if ([aDayKey isKindOfClass:[NSCalendarDate class]])
					thisSectionTitle = dateStr(aDayKey, true, false);
				else if ([aDayKey isEqual:[NSNull null]])
					thisSectionTitle = [NSString stringWithFormat:@"(%@)", localizedStr(@"noDueDate")];
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
		NSPrint(@"\n");
		NSPrint(@"USAGE: %s <options> <output_type>\n", argv[0]);
		NSPrint(@"\n");
		NSPrint(@"<output_type> specifies what to output.\n");
		NSPrint(@"Possible values for it are:\n");
		NSPrint(@"  'eventsToday'      (events occurring today)\n");
		NSPrint(@"  'eventsToday+NUM'  (events occurring between today\n");
		NSPrint(@"                      and NUM days into the future (where\n");
		NSPrint(@"                      NUM is an integer value))\n");
		NSPrint(@"  'eventsNow'        (events occurring at present time)\n");
		NSPrint(@"  'eventsFrom:START to:END'\n");
		NSPrint(@"                     (events occurring between the two\n");
		NSPrint(@"                      specified dates (START and END), where\n");
		NSPrint(@"                      both are specified in the format:\n");
		NSPrint(@"                      YYYY-MM-DD HH:MM:SS ±HHMM)\n");
		NSPrint(@"  'uncompletedTasks' (uncompleted tasks)\n");
		NSPrint(@"  'calendars'        (all calendars)\n");
		NSPrint(@"  'strEncodings'     (all the possible string encodings)\n");
		NSPrint(@"\n");
		NSPrint(@"Options:\n");
		NSPrint(@"\n");
		NSPrint(@"  -V    (or: --version) Print version number and exit.\n");
		NSPrint(@"\n");
		NSPrint(@"  -u    (or: --checkForUpdates) Check for updates.\n");
		NSPrint(@"\n");
		NSPrint(@"  -sc   (or: --separateByCalendar) Separate events/tasks\n");
		NSPrint(@"        by calendar.\n");
		NSPrint(@"\n");
		NSPrint(@"  -sd   (or: --separateByDate) Separate events/tasks\n");
		NSPrint(@"        by date.\n");
		NSPrint(@"\n");
		NSPrint(@"  -f    (or: --formatOutput)\n");
		NSPrint(@"        Format the output with ANSI escape sequences.\n");
		NSPrint(@"\n");
		NSPrint(@"  -nc   (or: --noCalendarNames) Omit calendar names from the\n");
		NSPrint(@"        output (does not apply if the -sc argument is used.)\n");
		NSPrint(@"\n");
		NSPrint(@"  -nrd  (or: --noRelativeDates) Do not use 'natural language\n");
		NSPrint(@"        relative dates' when displaying dates (e.g. 'today'\n");
		NSPrint(@"        or 'tomorrow'.)\n");
		NSPrint(@"\n");
		NSPrint(@"  -n    (or: --includeOnlyEventsFromNowOn)\n");
		NSPrint(@"        If the output_type value 'eventsToday' is\n");
		NSPrint(@"        used, only output events that occur between the\n");
		NSPrint(@"        current date and the end of the day (as opposed to\n");
		NSPrint(@"        events that occur between the start and end of the\n");
		NSPrint(@"        day, as by default.)\n");
		NSPrint(@"\n");
		NSPrint(@"  --strEncoding\n");
		NSPrint(@"        Use the specified string encoding for the output.\n");
		NSPrint(@"        Run the app once with the 'strEncodings' output_type\n");
		NSPrint(@"        value to see all the possible values you can use here.\n");
		NSPrint(@"\n");
		NSPrint(@"  -tf   (or: --timeFormat)\n");
		NSPrint(@"        Specify the formatting of times in the output.\n");
		NSPrint(@"        See http://tinyurl.com/b9mgyp [apple.com] for\n");
		NSPrint(@"        documentation on the syntax to use.\n");
		NSPrint(@"\n");
		NSPrint(@"  -df   (or: --dateFormat)\n");
		NSPrint(@"        Specify the formatting of dates in the output.\n");
		NSPrint(@"        See http://tinyurl.com/b9mgyp [apple.com] for\n");
		NSPrint(@"        documentation on the syntax to use.\n");
		NSPrint(@"\n");
		NSPrint(@"  -dts  (or: --dateTimeSeparator)\n");
		NSPrint(@"        Specify the separator string to use between\n");
		NSPrint(@"        dates and times in the output. The default is\n");
		NSPrint(@"        \" at \".\n");
		NSPrint(@"\n");
		NSPrint(@"  -po   (or: --propertyOrder)\n");
		NSPrint(@"        The order in which to print event/task properties. Must be\n");
		NSPrint(@"        a comma-separated list property names. Allowed property names\n");
		NSPrint(@"        are: title, location, notes, url, datetime, priority.\n");
		NSPrint(@"\n");
		NSPrint(@"  -b    (or: --bullet)\n");
		NSPrint(@"        Specify the string to use as the bullet point.\n");
		NSPrint(@"        The default is \"* \".\n");
		NSPrint(@"\n");
		NSPrint(@"  -ab   (or: --alertBullet)\n");
		NSPrint(@"        Specify the string to use as the \"alert\" bullet point.\n");
		NSPrint(@"        The default is \"! \".\n");
		NSPrint(@"\n");
		NSPrint(@"  -i    (or: --indent)\n");
		NSPrint(@"        Specify the string to use as the indentation for non-bulleted.\n");
		NSPrint(@"        lines. The default is four spaces (\"    \").\n");
		NSPrint(@"\n");
		NSPrint(@"  -ss   (or: --segmentSeparator)\n");
		NSPrint(@"        Specify the string to use as the separator between segment\n");
		NSPrint(@"        titles and the items belonging to the segments. The default\n");
		NSPrint(@"        is a bunch of minus/dash characters (-).\n");
		NSPrint(@"\n");
		NSPrint(@"  -ic   (or: --includeCals) Which calendars to include.\n");
		NSPrint(@"        Must be a comma-separated list of calendar UIDs (which\n");
		NSPrint(@"        you can find out by using the 'calendars' output parameter.)\n");
		NSPrint(@"        You can also use titles, but remember that they may not be\n");
		NSPrint(@"        unique (as opposed to UIDs.)\n");
		NSPrint(@"        The -i and -e parameters will be handled in the order of\n");
		NSPrint(@"        first include, then exclude.\n");
		NSPrint(@"\n");
		NSPrint(@"  -ec   (or: --excludeCals) Which calendars to exclude.\n");
		NSPrint(@"        Must be a comma-separated list of calendar UIDs (which\n");
		NSPrint(@"        you can find out by using the 'calendars' output parameter.)\n");
		NSPrint(@"        You can also use titles, but remember that they may not be\n");
		NSPrint(@"        unique (as opposed to UIDs.)\n");
		NSPrint(@"        The -i and -e parameters will be handled in the order of\n");
		NSPrint(@"        first include, then exclude.\n");
		NSPrint(@"\n");
		NSPrint(@"  -iep  (or: --includeEventProps)\n");
		NSPrint(@"        Which event properties to include in the output. Must be\n");
		NSPrint(@"        a comma-separated list property names. Possible\n");
		NSPrint(@"        property names are: location, url, notes, startDate\n");
		NSPrint(@"        and endDate.\n");
		NSPrint(@"\n");
		NSPrint(@"  -eep  (or: --excludeEventProps)\n");
		NSPrint(@"        Which event properties to exclude from the output. Must be\n");
		NSPrint(@"        a comma-separated list property names. A value of \"*\"\n");
		NSPrint(@"        will exclude all properties and make sure just the title\n");
		NSPrint(@"        is printed.\n");
		NSPrint(@"\n");
		NSPrint(@"  -itp  (or: --includeTaskProps)\n");
		NSPrint(@"        Which task properties to include in the output. Must be\n");
		NSPrint(@"        a comma-separated list property names. Possible\n");
		NSPrint(@"        property names are: url, notes, dueDate and priority.\n");
		NSPrint(@"\n");
		NSPrint(@"  -etp  (or: --excludeTaskProps)\n");
		NSPrint(@"        Which task properties to exclude from the output. Must be\n");
		NSPrint(@"        a comma-separated list property names. A value of \"*\"\n");
		NSPrint(@"        will exclude all properties and make sure just the title\n");
		NSPrint(@"        is printed.\n");
		NSPrint(@"\n");
		NSPrint(@"Version %@\n", versionNumber());
		NSPrint(@"(c) 2008-2009 Ali Rantakari, http://hasseg.org\n");
		NSPrint(@"\n");
	}
	
	
	[autoReleasePool release];
	return(0);
}