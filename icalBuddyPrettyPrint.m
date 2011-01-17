// icalBuddy pretty printing functions
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

#import <AddressBook/AddressBook.h>

#import "icalBuddyPrettyPrint.h"
#import "icalBuddyMacros.h"
#import "icalBuddyL10N.h"
#import "icalBuddyFormatting.h"
#import "HGUtils.h"
#import "HGDateFunctions.h"
#import "icalBuddyFunctions.h" // today, now


PrettyPrintOptions prettyPrintOptions;

NSMutableAttributedString *outputBuffer;

#define ADD_TO_OUTPUT_BUFFER(x)	[outputBuffer appendAttributedString:(x)]



void initPrettyPrint(NSMutableAttributedString *aOutputBuffer, PrettyPrintOptions opts)
{
	outputBuffer = aOutputBuffer;
	prettyPrintOptions = opts;
}


PrettyPrintOptions getDefaultPrettyPrintOptions()
{
	PrettyPrintOptions opts;
	
	// the prefix strings
	opts.prefixStrBullet = 			@"• ";
	opts.prefixStrBulletAlert = 	@"! ";
	opts.sectionSeparatorStr = 		@"\n------------------------";
	
	opts.timeFormatStr = nil;
	opts.dateFormatStr = nil;
	opts.includedEventProperties = nil;
	opts.excludedEventProperties = nil;
	opts.includedTaskProperties = nil;
	opts.excludedTaskProperties = nil;
	opts.notesNewlineReplacement = nil;
	
	opts.displayRelativeDates = YES;
	opts.excludeEndDates = NO;
	opts.useCalendarColorsForTitles = YES;
	opts.showUIDs = NO;
	opts.maxNumPrintedItems = 0; // 0 = no limit
	opts.numPrintedItems = 0;
	
	// the order of properties in the output
	opts.propertyOrder = nil;
	
	return opts;
}



// whether propertyName is ok to be printed, based on a set of property
// names to be included and a set of property names to be excluded
BOOL shouldPrintProperty(NSString *propertyName, NSSet *inclusionsSet, NSSet *exclusionsSet)
{
	if (propertyName == kPropName_UID)
		return prettyPrintOptions.showUIDs;
	
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
		if (prettyPrintOptions.displayRelativeDates &&
			datesRepresentSameDay(date, now)
			)
			outputDateStr = localizedStr(kL10nKeyToday);
		else if (prettyPrintOptions.displayRelativeDates &&
				datesRepresentSameDay(date, dateByAddingDays(now, 1))
				)
			outputDateStr = localizedStr(kL10nKeyTomorrow);
		else if (prettyPrintOptions.displayRelativeDates &&
				datesRepresentSameDay(date, dateByAddingDays(now, 2))
				)
			outputDateStr = localizedStr(kL10nKeyDayAfterTomorrow);
		else if (prettyPrintOptions.displayRelativeDates &&
				datesRepresentSameDay(date, dateByAddingDays(now, -1))
				)
			outputDateStr = localizedStr(kL10nKeyYesterday);
		else if (prettyPrintOptions.displayRelativeDates &&
				datesRepresentSameDay(date, dateByAddingDays(now, -2))
				)
			outputDateStr = localizedStr(kL10nKeyDayBeforeYesterday);
		else
		{
			NSString *useDateFormatStr = prettyPrintOptions.dateFormatStr;
			
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
		if (prettyPrintOptions.timeFormatStr != nil)
		{
			// use user-specified time format
			outputTimeStr = [date
				descriptionWithCalendarFormat:prettyPrintOptions.timeFormatStr
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
			if (prettyPrintOptions.notesNewlineReplacement == nil)
			{
				NSInteger thisNewlinesIndentModifier = [thisPropOutputName length]+1;
				thisNewlineReplacement = [NSString
					stringWithFormat:@"\n%@",
						WHITESPACE(thisNewlinesIndentModifier)
					];
			}
			else
				thisNewlineReplacement = prettyPrintOptions.notesNewlineReplacement;
			
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
				if (prettyPrintOptions.excludeEndDates || [[event startDate] isEqualToDate:[event endDate]])
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
		&& prettyPrintOptions.useCalendarColorsForTitles
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
	if (prettyPrintOptions.maxNumPrintedItems > 0 && prettyPrintOptions.maxNumPrintedItems <= prettyPrintOptions.numPrintedItems)
		return;
	
	if (event != nil)
	{
		NSUInteger numPrintedProps = 0;
		
		for (NSString *thisProp in prettyPrintOptions.propertyOrder)
		{
			if (!shouldPrintProperty(thisProp, prettyPrintOptions.includedEventProperties, prettyPrintOptions.excludedEventProperties))
				continue;
			
			NSMutableAttributedString *thisPropStr = getEventPropStr(thisProp, event, printOptions, contextDay);
			if (thisPropStr == nil || [thisPropStr length] <= 0)
				continue;
			
			NSMutableAttributedString *prefixStr;
			if (numPrintedProps == 0)
				prefixStr = mutableAttrStrWithAttrs(prettyPrintOptions.prefixStrBullet, getBulletStringAttributes(NO));
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
			
			ADD_TO_OUTPUT_BUFFER(thisOutput);
			
			numPrintedProps++;
		}
		
		if (numPrintedProps > 0)
			ADD_TO_OUTPUT_BUFFER(M_ATTR_STR(@"\n"));
		
		prettyPrintOptions.numPrintedItems++;
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
			if (prettyPrintOptions.notesNewlineReplacement == nil)
			{
				NSInteger thisNewlinesIndentModifier = [thisPropOutputName length]+1;
				thisNewlineReplacement = [NSString
					stringWithFormat:@"\n%@",
						WHITESPACE(thisNewlinesIndentModifier)
					];
			}
			else
				thisNewlineReplacement = prettyPrintOptions.notesNewlineReplacement;
			
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
		&& prettyPrintOptions.useCalendarColorsForTitles
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
	if (prettyPrintOptions.maxNumPrintedItems > 0 && prettyPrintOptions.maxNumPrintedItems <= prettyPrintOptions.numPrintedItems)
		return;
	
	if (task != nil)
	{
		NSUInteger numPrintedProps = 0;
		
		for (NSString *thisProp in prettyPrintOptions.propertyOrder)
		{
			if (!shouldPrintProperty(thisProp, prettyPrintOptions.includedTaskProperties, prettyPrintOptions.excludedTaskProperties))
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
					((useAlertBullet)?prettyPrintOptions.prefixStrBulletAlert:prettyPrintOptions.prefixStrBullet),
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
			
			ADD_TO_OUTPUT_BUFFER(thisOutput);
			
			numPrintedProps++;
		}
		
		if (numPrintedProps > 0)
			ADD_TO_OUTPUT_BUFFER(M_ATTR_STR(@"\n"));
		
		prettyPrintOptions.numPrintedItems++;
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
		if (prettyPrintOptions.maxNumPrintedItems > 0 && prettyPrintOptions.maxNumPrintedItems <= prettyPrintOptions.numPrintedItems)
			continue;
		
		NSArray *sectionItems = [sectionDict objectForKey:kSectionDictKey_items];
		
		// print section title
		NSString *sectionTitle = [sectionDict objectForKey:kSectionDictKey_title];
		if (!currentIsFirstPrintedSection)
			ADD_TO_OUTPUT_BUFFER(M_ATTR_STR(@"\n"));
		NSMutableAttributedString *thisOutput = M_ATTR_STR(
			strConcat(sectionTitle, @":", prettyPrintOptions.sectionSeparatorStr, nil)
			);
		[thisOutput
			addAttributes:getSectionTitleStringAttributes(sectionTitle)
			range:NSMakeRange(0,[thisOutput length])
			];
		
		// if the section title has no foreground color and we're told to
		// use calendar colors for them, do so
		if ((printOptions & PRINT_OPTION_CAL_COLORS_FOR_SECTION_TITLES)
			&& prettyPrintOptions.useCalendarColorsForTitles
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
		
		ADD_TO_OUTPUT_BUFFER(thisOutput);
		ADD_TO_OUTPUT_BUFFER(M_ATTR_STR(@"\n"));
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
			ADD_TO_OUTPUT_BUFFER(noItemsTextOutput);
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






