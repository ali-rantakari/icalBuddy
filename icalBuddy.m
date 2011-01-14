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

#import "icalBuddyMacros.h"
#import "icalBuddyL10N.h"
#import "icalBuddyFormatting.h"

#import "IcalBuddyAutoUpdaterDelegate.h"







const int VERSION_MAJOR = 1;
const int VERSION_MINOR = 7;
const int VERSION_BUILD = 14;

NSString* versionNumberStr()
{
	return [NSString stringWithFormat:@"%d.%d.%d", VERSION_MAJOR, VERSION_MINOR, VERSION_BUILD];
}






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

HGCLIAutoUpdater *autoUpdater;
IcalBuddyAutoUpdaterDelegate *autoUpdaterDelegate;


// the output buffer string where we add everything we
// want to print out, and right before terminating
// convert to an ANSI-escaped string and push it to
// the standard output. this way we can easily modify
// the formatting of the output right up until the
// last minute.
NSMutableAttributedString *stdoutBuffer;


// adds the specified attributed string to the output buffer.
void addToOutputBuffer(NSAttributedString *aStr)
{
	[stdoutBuffer appendAttributedString:aStr];
}




//-------------------------------------------------------------------
//-------------------------------------------------------------------
// BEGIN: Misc. helper functions







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
	
	
	autoUpdater = [[HGCLIAutoUpdater alloc]
		initWithAppName:@"icalBuddy"
		currentVersionStr:versionNumberStr()
		];
	autoUpdaterDelegate = [[IcalBuddyAutoUpdaterDelegate alloc] init];
	autoUpdater.delegate = autoUpdaterDelegate;
	
	
	// variables for arguments
	typedef struct {
		BOOL separateByCalendar;
		BOOL separateByDate;
		BOOL updatesCheck;
		BOOL printVersion;
		BOOL includeOnlyEventsFromNowOn;
		BOOL useFormatting;
		BOOL noCalendarNames;
		BOOL sortTasksByDueDate;
		BOOL sortTasksByDueDateAscending;
		BOOL sectionsForEachDayInSpan;
		BOOL noPropNames;
		
		BOOL output_is_uncompletedTasks;
		BOOL output_is_eventsToday;
		BOOL output_is_eventsNow;
		BOOL output_is_eventsFromTo;
		BOOL output_is_tasksDueBefore;
		
		NSString *output;
		NSArray *includeCals;
		NSArray *excludeCals;
		NSString *strEncoding;
		NSString *propertyOrderStr;
		NSString *propertySeparatorsStr;
		NSString *eventsFrom;
		NSString *eventsTo;
	} Arguments;
	
	Arguments args = {NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,nil,nil,nil,nil,nil,nil,nil,nil};
	
	
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
	
	NSDictionary *userSuppliedFormattingConfigDict = nil;
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
				userSuppliedFormattingConfigDict = [configDict objectForKey:@"formatting"];
				
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
						args.includeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"includeCals"]);
					if ([allArgKeys containsObject:@"excludeCals"])
						args.excludeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"excludeCals"]);
					if ([allArgKeys containsObject:@"propertyOrder"])
						args.propertyOrderStr = [constArgsDict objectForKey:@"propertyOrder"];
					if ([allArgKeys containsObject:@"strEncoding"])
						args.strEncoding = [constArgsDict objectForKey:@"strEncoding"];
					if ([allArgKeys containsObject:@"separateByCalendar"])
						args.separateByCalendar = [[constArgsDict objectForKey:@"separateByCalendar"] boolValue];
					if ([allArgKeys containsObject:@"separateByDate"])
						args.separateByDate = [[constArgsDict objectForKey:@"separateByDate"] boolValue];
					if ([allArgKeys containsObject:@"includeOnlyEventsFromNowOn"])
						args.includeOnlyEventsFromNowOn = [[constArgsDict objectForKey:@"includeOnlyEventsFromNowOn"] boolValue];
					if ([allArgKeys containsObject:@"formatOutput"])
						args.useFormatting = [[constArgsDict objectForKey:@"formatOutput"] boolValue];
					if ([allArgKeys containsObject:@"noCalendarNames"])
						args.noCalendarNames = [[constArgsDict objectForKey:@"noCalendarNames"] boolValue];
					if ([allArgKeys containsObject:@"noRelativeDates"])
						displayRelativeDates = ![[constArgsDict objectForKey:@"noRelativeDates"] boolValue];
					if ([allArgKeys containsObject:@"showEmptyDates"])
						args.sectionsForEachDayInSpan = [[constArgsDict objectForKey:@"showEmptyDates"] boolValue];
					if ([allArgKeys containsObject:@"notesNewlineReplacement"])
						notesNewlineReplacement = [constArgsDict objectForKey:@"notesNewlineReplacement"];
					if ([allArgKeys containsObject:@"limitItems"])
						maxNumPrintedItems = [[constArgsDict objectForKey:@"limitItems"] unsignedIntegerValue];
					if ([allArgKeys containsObject:@"propertySeparators"])
						args.propertySeparatorsStr = [constArgsDict objectForKey:@"propertySeparators"];
					if ([allArgKeys containsObject:@"excludeEndDates"])
						excludeEndDates = [[constArgsDict objectForKey:@"excludeEndDates"] boolValue];
					if ([allArgKeys containsObject:@"sortTasksByDate"])
						args.sortTasksByDueDate = [[constArgsDict objectForKey:@"sortTasksByDate"] boolValue];
					if ([allArgKeys containsObject:@"sortTasksByDateAscending"])
						args.sortTasksByDueDateAscending = [[constArgsDict objectForKey:@"sortTasksByDateAscending"] boolValue];
					if ([allArgKeys containsObject:@"noPropNames"])
						args.noPropNames = [[constArgsDict objectForKey:@"noPropNames"] boolValue];
					if ([allArgKeys containsObject:@"showUIDs"])
						showUIDs = [[constArgsDict objectForKey:@"showUIDs"] boolValue];
					if ([allArgKeys containsObject:@"debug"])
						debugPrintEnabled = [[constArgsDict objectForKey:@"debug"] boolValue];
				}
			}
		}
	}
	
	
	// initialize localization
	initL10N(L10nFilePath);
	
	
	// get arguments
	
	if (argc > 1)
	{
		args.output = [NSString stringWithCString: argv[argc-1] encoding: NSASCIIStringEncoding];
		
		args.output_is_uncompletedTasks = [args.output isEqualToString:@"uncompletedTasks"];
		args.output_is_eventsToday = [args.output hasPrefix:@"eventsToday"];
		args.output_is_eventsNow = [args.output isEqualToString:@"eventsNow"];
		args.output_is_tasksDueBefore = [args.output hasPrefix:@"tasksDueBefore:"];
		
		if ([args.output hasPrefix:@"to:"] && argc > 2)
		{
			NSString *secondToLastArg = [NSString stringWithCString: argv[argc-2] encoding: NSASCIIStringEncoding];
			if ([secondToLastArg hasPrefix:@"eventsFrom:"])
			{
				args.eventsFrom = [secondToLastArg substringFromIndex:11]; // "eventsFrom:" has 11 chars
				args.eventsTo = [args.output substringFromIndex:3]; // "to:" has 3 chars
				args.output_is_eventsFromTo = YES;
			}
		}
	}
	
	
	
	for (i = 1; i < argc; i++)
	{
		if ((strcmp(argv[i], "-sc") == 0) || (strcmp(argv[i], "--separateByCalendar") == 0))
			args.separateByCalendar = YES;
		else if ((strcmp(argv[i], "-sd") == 0) || (strcmp(argv[i], "--separateByDate") == 0))
			args.separateByDate = YES;
		else if ((strcmp(argv[i], "-u") == 0) || (strcmp(argv[i], "--checkForUpdates") == 0))
			args.updatesCheck = YES;
		else if ((strcmp(argv[i], "-V") == 0) || (strcmp(argv[i], "--version") == 0))
			args.printVersion = YES;
		else if ((strcmp(argv[i], "-d") == 0) || (strcmp(argv[i], "--debug") == 0))
			debugPrintEnabled = YES;
		else if ((strcmp(argv[i], "-n") == 0) || (strcmp(argv[i], "--includeOnlyEventsFromNowOn") == 0))
			args.includeOnlyEventsFromNowOn = YES;
		else if ((strcmp(argv[i], "-f") == 0) || (strcmp(argv[i], "--formatOutput") == 0))
			args.useFormatting = YES;
		else if ((strcmp(argv[i], "-nc") == 0) || (strcmp(argv[i], "--noCalendarNames") == 0))
			args.noCalendarNames = YES;
		else if ((strcmp(argv[i], "-nrd") == 0) || (strcmp(argv[i], "--noRelativeDates") == 0))
			displayRelativeDates = NO;
		else if ((strcmp(argv[i], "-eed") == 0) || (strcmp(argv[i], "--excludeEndDates") == 0))
			excludeEndDates = YES;
		else if ((strcmp(argv[i], "-std") == 0) || (strcmp(argv[i], "--sortTasksByDate") == 0))
			args.sortTasksByDueDate = YES;
		else if ((strcmp(argv[i], "-stda") == 0) || (strcmp(argv[i], "--sortTasksByDateAscending") == 0))
			args.sortTasksByDueDateAscending = YES;
		else if ((strcmp(argv[i], "-sed") == 0) || (strcmp(argv[i], "--showEmptyDates") == 0))
			args.sectionsForEachDayInSpan = YES;
		else if ((strcmp(argv[i], "-uid") == 0) || (strcmp(argv[i], "--showUIDs") == 0))
			showUIDs = YES;
		else if ((strcmp(argv[i], "-npn") == 0) || (strcmp(argv[i], "--noPropNames") == 0))
			args.noPropNames = YES;
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
			args.includeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-ec") == 0) || (strcmp(argv[i], "--excludeCals") == 0)) && (i+1 < argc))
			args.excludeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-po") == 0) || (strcmp(argv[i], "--propertyOrder") == 0)) && (i+1 < argc))
			args.propertyOrderStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if ((strcmp(argv[i], "--strEncoding") == 0) && (i+1 < argc))
			args.strEncoding = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-li") == 0) || (strcmp(argv[i], "--limitItems") == 0)) && (i+1 < argc))
			maxNumPrintedItems = abs([[NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding] integerValue]);
		else if (((strcmp(argv[i], "-ps") == 0) || (strcmp(argv[i], "--propertySeparators") == 0)) && (i+1 < argc))
			args.propertySeparatorsStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
	}
	
	
	if (args.propertyOrderStr != nil)
	{
		// if property order is specified, filter out property names that are not allowed (the allowed
		// ones are all included in the NSArray specified by the kDefaultPropertyOrder macro definition)
		// and then add to the list the omitted property names in the default order
		NSArray *specifiedPropertyOrder = arrayFromCommaSeparatedStringTrimmingWhitespace(args.propertyOrderStr);
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
	
	
	NSArray *propertySeparators = nil;
	if (args.propertySeparatorsStr != nil)
	{
		NSError *propertySeparatorsArgParseError = nil;
		propertySeparators = arrayFromArbitrarilySeparatedString(args.propertySeparatorsStr, YES, &propertySeparatorsArgParseError);
		if (propertySeparators == nil && propertySeparatorsArgParseError != nil)
		{
			PrintfErr(
				@"* Error: invalid value for argument -ps (or --propertySeparators):\n  \"%@\".\n",
				[propertySeparatorsArgParseError localizedDescription]
				);
			PrintfErr(@"  Make sure you start and end the value with the separator character\n  (like this: -ps \"|first|second|third|\")\n");
		}
	}
	
	// initialize formatting
	initFormatting(userSuppliedFormattingConfigDict, propertySeparators);
	
	
	if (args.strEncoding != nil)
	{
		// process provided output string encoding argument
		args.strEncoding = [args.strEncoding stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSStringEncoding matchedEncoding = 0;
		const NSStringEncoding *availableEncoding = [NSString availableStringEncodings];
		while(*availableEncoding != 0)
		{
			if ([[NSString localizedNameOfStringEncoding: *availableEncoding] isEqualToString:args.strEncoding])
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
			PrintfErr(@"* Error: Invalid string encoding argument: \"%@\".\n", args.strEncoding);
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
	if (args.printVersion)
	{
		Printf(@"%@\n", versionNumberStr());
	}
	// ------------------------------------------------------------------
	// ------------------------------------------------------------------
	// check for updates
	// ------------------------------------------------------------------
	else if (args.updatesCheck)
	{
		[autoUpdater checkForUpdatesWithUI];
	}
	// ------------------------------------------------------------------
	// ------------------------------------------------------------------
	// print possible values for the string encoding argument and exit
	// ------------------------------------------------------------------
	else if ([args.output isEqualToString:@"strEncodings"])
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
	else if ([args.output isEqualToString:@"calendars"])
	{
		// get all calendars
		NSMutableArray *allCalendars = [[[CalCalendarStore defaultCalendarStore] calendars] mutableCopy];
		
		// filter calendars based on arguments
		allCalendars = filterCalendars(allCalendars, args.includeCals, args.excludeCals);
		
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
	else if ([args.output hasPrefix:@"editConfig"])
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
			if ([args.output hasSuffix:@"CLI"])
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
	else if (args.output_is_eventsToday || args.output_is_eventsNow || args.output_is_eventsFromTo
			 || args.output_is_uncompletedTasks || args.output_is_tasksDueBefore)
	{
		BOOL printingEvents = (args.output_is_eventsToday || args.output_is_eventsNow || args.output_is_eventsFromTo);
		BOOL printingAlsoPastEvents = (args.output_is_eventsFromTo);
		BOOL printingTasks = (args.output_is_uncompletedTasks || args.output_is_tasksDueBefore);
		
		// get all calendars
		NSMutableArray *allCalendars = [[[CalCalendarStore defaultCalendarStore] calendars] mutableCopy];
		
		// filter calendars based on arguments
		allCalendars = filterCalendars(allCalendars, args.includeCals, args.excludeCals);
		
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
				(args.noCalendarNames ? PRINT_OPTION_CALENDAR_AGNOSTIC : PRINT_OPTION_NONE);
			
			// get start and end dates for predicate
			if (args.output_is_eventsToday)
			{
				eventsDateRangeStart = today;
				eventsDateRangeEnd = dateForEndOfDay(now);
			}
			else if (args.output_is_eventsNow)
			{
				eventsDateRangeStart = now;
				eventsDateRangeEnd = now;
			}
			else if (args.output_is_eventsFromTo)
			{
				eventsDateRangeStart = dateFromUserInput(args.eventsFrom, @"start date");
				eventsDateRangeEnd = dateFromUserInput(args.eventsTo, @"end date");
				
				if (eventsDateRangeStart == nil || eventsDateRangeEnd == nil)
				{
					PrintfErr(@"\n");
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
			if (args.output_is_eventsToday)
			{
				NSRange arg_output_plusSymbolRange = [args.output rangeOfString:@"+"];
				if (arg_output_plusSymbolRange.location != NSNotFound)
				{
					NSInteger daysToAddToRange = [[args.output substringFromIndex:(arg_output_plusSymbolRange.location+arg_output_plusSymbolRange.length)] integerValue];
					eventsDateRangeEnd = dateByAddingDays(eventsDateRangeEnd, daysToAddToRange);
					events_printOptions &= ~PRINT_OPTION_SINGLE_DAY;
				}
			}
			
			
			eventsDateRangeDaysSpan = getDayDiff(eventsDateRangeStart, eventsDateRangeEnd);
			
			
			NSDate *predicateDateStart = ((args.includeOnlyEventsFromNowOn)?now:eventsDateRangeStart);
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
			
			if (args.output_is_tasksDueBefore)
			{
				NSDate *dueBeforeDate = nil;
				
				NSString *dueBeforeDateStr = [args.output substringFromIndex:15]; // "tasksDueBefore:" has 15 chars
				dueBeforeDate = dateFromUserInput(dueBeforeDateStr, @"due date");
				
				if (dueBeforeDate == nil)
				{
					PrintfErr(@"\n");
					printDateFormatInfo();
					return(0);
				}
				
				DebugPrintf(@"effective query 'due before' date: %@\n", dueBeforeDate);
				tasksPredicate = [CalCalendarStore taskPredicateWithUncompletedTasksDueBefore:dueBeforeDate calendars:allCalendars];
			}
			else // all uncompleted tasks
				tasksPredicate = [CalCalendarStore taskPredicateWithUncompletedTasks:allCalendars];
			
			
			// get tasks
			uncompletedTasks = [[CalCalendarStore defaultCalendarStore] tasksWithPredicate:tasksPredicate];
			
			// sort the tasks
			if (args.sortTasksByDueDate || args.sortTasksByDueDateAscending)
			{
				uncompletedTasks = [uncompletedTasks
					sortedArrayUsingDescriptors:[NSArray
						arrayWithObjects:
							[[[NSSortDescriptor alloc] initWithKey:@"dueDate" ascending:args.sortTasksByDueDateAscending] autorelease],
							nil
						]
					];
				
				if (args.sortTasksByDueDateAscending)
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
			tasks_printOptions = (args.noCalendarNames ? PRINT_OPTION_CALENDAR_AGNOSTIC : PRINT_OPTION_NONE);
		}
		
		
		// append to print options
		if (args.noPropNames)
		{
			events_printOptions |= PRINT_OPTION_WITHOUT_PROP_NAMES;
			tasks_printOptions |= PRINT_OPTION_WITHOUT_PROP_NAMES;
		}
		if (args.separateByCalendar)
		{
			events_printOptions |= PRINT_OPTION_CAL_COLORS_FOR_SECTION_TITLES;
			tasks_printOptions |= PRINT_OPTION_CAL_COLORS_FOR_SECTION_TITLES;
		}
		
		
		// print the items
		if (args.separateByCalendar)
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
		else if (args.separateByDate)
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
			
			if (args.sectionsForEachDayInSpan)
			{
				// fill the day span we have so that all days have an entry
				NSDate *earliestDate = nil;
				NSDate *latestDate = nil;
				
				if (args.output_is_eventsFromTo || args.output_is_eventsToday || args.output_is_eventsNow)
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
	if ((args.useFormatting && configDict != nil) &&
		(args.output_is_eventsToday || args.output_is_eventsNow ||
		args.output_is_eventsFromTo || args.output_is_uncompletedTasks)
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
	
	if (args.useFormatting)
	{
		processCustomStringAttributes(&stdoutBuffer);
		finalOutput = ansiEscapedStringWithAttributedString(stdoutBuffer);
	}
	else
		finalOutput = [stdoutBuffer string];
	
	Print(finalOutput);
	
	
	[autoReleasePool release];
	return(0);
}
