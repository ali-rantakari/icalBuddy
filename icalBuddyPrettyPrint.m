// icalBuddy pretty printing functions
//
// http://hasseg.org/icalBuddy
//

/*
The MIT License

Copyright (c) 2008-2011 Ali Rantakari

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
#import "icalBuddyDefines.h"

#import "icalBuddyL10N.h"
#import "icalBuddyFormatting.h"
#import "HGUtils.h"
#import "HGCLIUtils.h"
#import "HGDateFunctions.h"
#import "icalBuddyFunctions.h" // today, now
#import "ABRecord+HGAdditions.h"


PrettyPrintOptions prettyPrintOptions;

NSMutableAttributedString *outputBuffer;

#define ADD_TO_OUTPUT_BUFFER(x) [outputBuffer appendAttributedString:(x)]



void initPrettyPrint(NSMutableAttributedString *aOutputBuffer, PrettyPrintOptions opts)
{
    outputBuffer = aOutputBuffer;
    prettyPrintOptions = opts;
}


PrettyPrintOptions getDefaultPrettyPrintOptions()
{
    PrettyPrintOptions opts;

    // the prefix strings
    opts.prefixStrBullet =          @"• ";
    opts.prefixStrBulletAlert =     @"! ";
    opts.sectionSeparatorStr =      @"\n------------------------";

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




@interface PropertyPresentationElements : NSObject
{
    NSMutableAttributedString *name;
    NSMutableAttributedString *value;
    NSMutableAttributedString *valueSuffix;
}
@property(retain) NSMutableAttributedString *name;
@property(retain) NSMutableAttributedString *value;
@property(retain) NSMutableAttributedString *valueSuffix;
@end

@implementation PropertyPresentationElements
@synthesize name;
@synthesize value;
@synthesize valueSuffix;
@end



PropertyPresentationElements *getEventTitlePresentation(CalEvent *event, CalItemPrintOption printOptions, NSDate *contextDay)
{
    PropertyPresentationElements *elements = [PropertyPresentationElements new];

    NSString *thisPropTempValue = nil;

    if ([[[event calendar] type] isEqualToString:CalCalendarTypeBirthday])
    {
        ABAddressBook *addressBook = [ABAddressBook sharedAddressBook];

        // If the user has Mountain Lion or later, and has denied icalBuddy access to their
        // contacts, then -sharedAddressBook will return nil.
        if (addressBook == nil)
        {
            thisPropTempValue = [event title];
        }
        else
        {
            // special case for events in the Birthdays calendar (they don't seem to have titles
            // so we have to use the URI to find the ABPerson from the Address Book
            // and print their name from there)

            NSString *personId = [[NSString stringWithFormat:@"%@", [event url]]
                stringByReplacingOccurrencesOfString:@"addressbook://"
                withString:@""
                ];
            ABRecord *person = [[ABAddressBook sharedAddressBook] recordForUniqueId:personId];

            if (person != nil && [person isMemberOfClass: [ABPerson class]])
            {
                NSString *thisTitle = nil;
                if ([person isEqual:[[ABAddressBook sharedAddressBook] me]])
                    thisTitle = localizedStr(kL10nKeyMyBirthday);
                else
                {
                    NSString *contactFullName = [person hg_fullName];
                    NSInteger contactAge = [person hg_ageOnDate:[event startDate]];
                    NSString *birthdayFormat = localizedStr(kL10nKeySomeonesBirthday);
                    if ([birthdayFormat rangeOfString:@"%i"].location != NSNotFound)
                        thisTitle = [NSString stringWithFormat:birthdayFormat, contactFullName, contactAge];
                    else
                        thisTitle = [NSString stringWithFormat:birthdayFormat, contactFullName];
                }
                thisPropTempValue = thisTitle;
            }
        }
    }
    else
        thisPropTempValue = [event title];

    if (thisPropTempValue != nil)
        elements.value = M_ATTR_STR(thisPropTempValue);

    if (!printOptions.calendarAgnostic)
    {
        elements.valueSuffix = M_ATTR_STR(@" ");
        [elements.valueSuffix
            appendAttributedString: mutableAttrStrWithAttrs(
                strConcat(@"(", [[event calendar] title], @")", nil),
                getCalNameInTitleStringAttributes(event)
                )
            ];
    }

    return elements;
}

PropertyPresentationElements *getEventLocationPresentation(CalEvent *event, CalItemPrintOption printOptions, NSDate *contextDay)
{
    PropertyPresentationElements *elements = [PropertyPresentationElements new];

    elements.name = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameLocation), @":", nil));

    if ([event location] != nil &&
        ![[[event location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]
        )
        elements.value = M_ATTR_STR([event location]);

    return elements;
}

PropertyPresentationElements *getEventNotesPresentation(CalEvent *event, CalItemPrintOption printOptions, NSDate *contextDay)
{
    PropertyPresentationElements *elements = [PropertyPresentationElements new];

    elements.name = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameNotes), @":", nil));

    if ([event notes] != nil &&
        ![[[event notes] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]
        )
    {
        NSString *thisNewlineReplacement = nil;
        if (prettyPrintOptions.notesNewlineReplacement == nil)
        {
            NSInteger thisNewlinesIndentModifier = [elements.name length]+1;
            thisNewlineReplacement = strConcat(@"\n", WHITESPACE(thisNewlinesIndentModifier), nil);
        }
        else
            thisNewlineReplacement = prettyPrintOptions.notesNewlineReplacement;

        elements.value = M_ATTR_STR(
            [[event notes]
                stringByReplacingOccurrencesOfString:@"\n"
                withString:thisNewlineReplacement
                ]
            );
    }

    return elements;
}

PropertyPresentationElements *getEventURLPresentation(CalEvent *event, CalItemPrintOption printOptions, NSDate *contextDay)
{
    PropertyPresentationElements *elements = [PropertyPresentationElements new];

    elements.name = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameUrl), @":", nil));

    if ([event url] != nil &&
        ![[[event calendar] type] isEqualToString:CalCalendarTypeBirthday]
        )
        elements.value = M_ATTR_STR(([NSString stringWithFormat: @"%@", [event url]]));

    return elements;
}

PropertyPresentationElements *getEventUIDPresentation(CalEvent *event, CalItemPrintOption printOptions, NSDate *contextDay)
{
    PropertyPresentationElements *elements = [PropertyPresentationElements new];

    elements.name = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameUID), @":", nil));
    elements.value = M_ATTR_STR([event uid]);

    return elements;
}

PropertyPresentationElements *getEventAttendeesPresentation(CalEvent *event, CalItemPrintOption printOptions, NSDate *contextDay)
{
    PropertyPresentationElements *elements = [PropertyPresentationElements new];

    elements.name = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameAttendees), @":", nil));

    if ([event attendees] != nil && ![[[event calendar] type] isEqualToString:CalCalendarTypeBirthday])
    {
        NSMutableArray *attendeeNames = [NSMutableArray array];
        for (CalAttendee *attendee in [event attendees])
        {
            [attendeeNames addObject:[attendee commonName]];
        }
        if (0 < printOptions.maxNumPrintedAttendees && printOptions.maxNumPrintedAttendees < attendeeNames.count)
        {
            attendeeNames = [[attendeeNames subarrayWithRange:NSMakeRange(0, printOptions.maxNumPrintedAttendees)]
                             arrayByAddingObject:@"..."].mutableCopy;
        }
        elements.value = M_ATTR_STR(([attendeeNames componentsJoinedByString:@", "]));
    }
    return elements;
}

PropertyPresentationElements *getEventDatetimePresentation(CalEvent *event, CalItemPrintOption printOptions, NSDate *contextDay)
{
    PropertyPresentationElements *elements = [PropertyPresentationElements new];

    if ([[[event calendar] type] isEqualToString:CalCalendarTypeBirthday])
    {
        if (!printOptions.singleDay)
            elements.value = M_ATTR_STR(dateStr([event startDate], ONLY_DATE));
        return elements;
    }

    BOOL startsOnContextDay = NO;
    BOOL endsOnContextDay = NO;
    if (contextDay != nil)
    {
        startsOnContextDay = datesRepresentSameDay(contextDay, [event startDate]);
        endsOnContextDay = datesRepresentSameDay(contextDay, [event endDate]);
    }

    BOOL printDatetime = (!printOptions.singleDay || (printOptions.singleDay && ![event isAllDay]));

    if (!printDatetime)
        return elements;

    BOOL printOnlyStartDatetime = (prettyPrintOptions.excludeEndDates
                                   || [[event startDate] isEqualToDate:[event endDate]]);
    if (printOnlyStartDatetime)
    {
        if (printOptions.singleDay && !startsOnContextDay)
            elements.value = M_ATTR_STR(@"...");
        else
        {
            DatePrintOption datePrintOpt = DATE_PRINT_OPTION_NONE;
            BOOL printDate = !printOptions.singleDay;
            BOOL printTime = ![event isAllDay];

            if (printDate && printTime)
                datePrintOpt = DATE_AND_TIME;
            else if (printDate)
                datePrintOpt = ONLY_DATE;
            else if (printTime)
                datePrintOpt = ONLY_TIME;

            if (datePrintOpt != DATE_PRINT_OPTION_NONE)
                elements.value = M_ATTR_STR(
                    dateStr([event startDate], datePrintOpt)
                    );
        }

        return elements;
    }

    if (printOptions.singleDay)
    {
        if (startsOnContextDay && endsOnContextDay)
            elements.value = M_ATTR_STR((
                strConcat(
                    dateStr([event startDate], ONLY_TIME),
                    @" - ",
                    dateStr([event endDate], ONLY_TIME),
                    nil
                    )
                ));
        else if (startsOnContextDay)
            elements.value = M_ATTR_STR((
                strConcat(dateStr([event startDate], ONLY_TIME), @" - ...", nil)
                ));
        else if (endsOnContextDay)
            elements.value = M_ATTR_STR((
                strConcat(@"... - ", dateStr([event endDate], ONLY_TIME), nil)
                ));
        else
            elements.value = M_ATTR_STR(@"... - ...");

        return elements;
    }

    if ([event isAllDay])
    {
        // all-day events technically span from <start day> at 00:00 to <end day+1> at 00:00 even though
        // we want them displayed as only spanning from <start day> to <end day>
        NSDate *endDateMinusOneDay = dateByAddingDays([event endDate], -1);
        NSInteger daysDiff = getDayDiff([event startDate], endDateMinusOneDay);

        if (daysDiff > 0)
        {
            elements.value = M_ATTR_STR((
                strConcat(
                    dateStr([event startDate], ONLY_DATE),
                    @" - ",
                    dateStr(endDateMinusOneDay, ONLY_DATE),
                    nil
                    )
                ));
        }
        else
            elements.value = M_ATTR_STR(dateStr([event startDate], ONLY_DATE));

        return elements;
    }

    NSString *startDateFormattedStr = dateStr([event startDate], DATE_AND_TIME);

    DatePrintOption datePrintOpt = datesRepresentSameDay([event startDate], [event endDate]) ? ONLY_TIME : DATE_AND_TIME;
    NSString *endDateFormattedStr = dateStr([event endDate], datePrintOpt);

    elements.value = M_ATTR_STR(strConcat(startDateFormattedStr, @" - ", endDateFormattedStr, nil));

    return elements;
}


// returns a pretty-printed string representation of the specified event property
NSMutableAttributedString* getEventPropStr(NSString *propName, CalEvent *event, CalItemPrintOption printOptions, NSDate *contextDay)
{
    if (event == nil)
        return nil;

    PropertyPresentationElements *elements = nil;

    if ([propName isEqualToString:kPropName_title])
    {
        elements = getEventTitlePresentation(event, printOptions, contextDay);
    }
    else if ([propName isEqualToString:kPropName_location])
    {
        elements = getEventLocationPresentation(event, printOptions, contextDay);
    }
    else if ([propName isEqualToString:kPropName_notes])
    {
        elements = getEventNotesPresentation(event, printOptions, contextDay);
    }
    else if ([propName isEqualToString:kPropName_url])
    {
        elements = getEventURLPresentation(event, printOptions, contextDay);
    }
    else if ([propName isEqualToString:kPropName_UID])
    {
        elements = getEventUIDPresentation(event, printOptions, contextDay);
    }
    else if ([propName isEqualToString:kPropName_attendees])
    {
        elements = getEventAttendeesPresentation(event, printOptions, contextDay);
    }
    else if ([propName isEqualToString:kPropName_datetime])
    {
        elements = getEventDatetimePresentation(event, printOptions, contextDay);
    }
    else
        return nil;


    if (elements.value == nil || [elements.value length] == 0)
        return nil;

    if (elements.name != nil && [elements.name length] > 0)
    {
        [elements.name
            setAttributes:getPropNameStringAttributes(propName, event)
            range:NSMakeRange(0, [elements.name length])
            ];
    }

    [elements.value
        setAttributes:getPropValueStringAttributes(propName, [elements.value string], event)
        range:NSMakeRange(0, [elements.value length])
        ];

    // if no foreground color for title, use calendar color by default
    if ([propName isEqualToString:kPropName_title]
        && prettyPrintOptions.useCalendarColorsForTitles
        && ![[[elements.value attributesAtIndex:0 effectiveRange:NULL] allKeys] containsObject:NSForegroundColorAttributeName]
        )
        [elements.value
            addAttribute:NSForegroundColorAttributeName
            value:getClosestAnsiColorForColor([[event calendar] color], YES)
            range:NSMakeRange(0, [elements.value length])
            ];

    if (elements.valueSuffix != nil)
        [elements.value appendAttributedString:elements.valueSuffix];

    NSMutableAttributedString *retVal = kEmptyMutableAttributedString;

    if (elements.name != nil && !printOptions.withoutPropNames)
    {
        [elements.name appendAttributedString:ATTR_STR(@" ")];
        [retVal appendAttributedString:elements.name];
    }

    [retVal appendAttributedString:elements.value];

    return retVal;
}




// pretty-prints out the specified event
void printCalEvent(CalEvent *event, CalItemPrintOption printOptions, NSDate *contextDay)
{
    if (prettyPrintOptions.maxNumPrintedItems > 0 && prettyPrintOptions.maxNumPrintedItems <= prettyPrintOptions.numPrintedItems)
        return;

    if (event == nil)
        return;

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
            prefixStr = mutableAttrStrWithAttrs(prettyPrintOptions.prefixStrBullet, getBulletStringAttributes(NO, event));
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
                addAttributes:getFirstLineStringAttributes(event)
                range:NSMakeRange(0,[thisOutput length])
                ];

        ADD_TO_OUTPUT_BUFFER(thisOutput);

        numPrintedProps++;
    }

    if (numPrintedProps > 0)
        ADD_TO_OUTPUT_BUFFER(M_ATTR_STR(@"\n"));

    prettyPrintOptions.numPrintedItems++;
}





PropertyPresentationElements *getTaskTitlePresentation(CalTask *task, CalItemPrintOption printOptions)
{
    PropertyPresentationElements *elements = [PropertyPresentationElements new];

    elements.value = M_ATTR_STR([task title]);

    if (!printOptions.calendarAgnostic)
    {
        elements.valueSuffix = M_ATTR_STR(@" ");
        [elements.valueSuffix
            appendAttributedString: mutableAttrStrWithAttrs(
                strConcat(@"(", [[task calendar] title], @")", nil),
                getCalNameInTitleStringAttributes(task)
                )
            ];
    }

    return elements;
}

PropertyPresentationElements *getTaskNotesPresentation(CalTask *task, CalItemPrintOption printOptions)
{
    PropertyPresentationElements *elements = [PropertyPresentationElements new];

    elements.name = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameNotes), @":", nil));

    if ([task notes] == nil
        || [[[task notes] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0
        )
        return elements;

    NSString *thisNewlineReplacement;
    if (prettyPrintOptions.notesNewlineReplacement == nil)
    {
        NSInteger thisNewlinesIndentModifier = [elements.name length]+1;
        thisNewlineReplacement = [NSString
            stringWithFormat:@"\n%@",
                WHITESPACE(thisNewlinesIndentModifier)
            ];
    }
    else
        thisNewlineReplacement = prettyPrintOptions.notesNewlineReplacement;

    elements.value = M_ATTR_STR((
        [[task notes]
            stringByReplacingOccurrencesOfString:@"\n"
            withString:thisNewlineReplacement
            ]
        ));

    return elements;
}

PropertyPresentationElements *getTaskURLPresentation(CalTask *task, CalItemPrintOption printOptions)
{
    PropertyPresentationElements *elements = [PropertyPresentationElements new];

    elements.name = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameUrl), @":", nil));

    if ([task url] != nil)
        elements.value = M_ATTR_STR(([NSString stringWithFormat:@"%@", [task url]]));

    return elements;
}

PropertyPresentationElements *getTaskUIDPresentation(CalTask *task, CalItemPrintOption printOptions)
{
    PropertyPresentationElements *elements = [PropertyPresentationElements new];

    elements.name = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameUID), @":", nil));
    elements.value = M_ATTR_STR([task uid]);

    return elements;
}

PropertyPresentationElements *getTaskDatetimePresentation(CalTask *task, CalItemPrintOption printOptions)
{
    PropertyPresentationElements *elements = [PropertyPresentationElements new];

    elements.name = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNameDueDate), @":", nil));

    if ([task dueDate] != nil && !printOptions.singleDay)
        elements.value = M_ATTR_STR(dateStr([task dueDate], ONLY_DATE));

    return elements;
}

NSString *localizedPriority(CalPriority priority)
{
    switch(priority)
    {
        case CalPriorityHigh:
            return localizedStr(kL10nKeyPriorityHigh);
            break;
        case CalPriorityMedium:
            return localizedStr(kL10nKeyPriorityMedium);
            break;
        case CalPriorityLow:
            return localizedStr(kL10nKeyPriorityLow);
            break;
        case CalPriorityNone:
            return localizedStr(kL10nKeyPriorityNone);
            break;
    }
    return [NSString stringWithFormat:@"%d", priority];
}

NSString *localizedPriorityTitle(CalPriority priority)
{
    if (priority == CalPriorityNone)
        return localizedStr(kL10nKeyPriorityTitleNone);

    // If we have a specific translation for this priority title:
    if (priority == CalPriorityLow && localizedStr(kL10nKeyPriorityTitleLow) != nil)
        return localizedStr(kL10nKeyPriorityTitleLow);
    else if (priority == CalPriorityMedium && localizedStr(kL10nKeyPriorityTitleMedium) != nil)
        return localizedStr(kL10nKeyPriorityTitleMedium);
    else if (priority == CalPriorityHigh && localizedStr(kL10nKeyPriorityTitleHigh) != nil)
        return localizedStr(kL10nKeyPriorityTitleHigh);

    // Otherwise use the default, generic one:
    return [[NSString stringWithFormat:localizedStr(kL10nKeyPriorityTitle),
             localizedPriority(priority)] capitalizedString];
}

PropertyPresentationElements *getTaskPriorityPresentation(CalTask *task, CalItemPrintOption printOptions)
{
    PropertyPresentationElements *elements = [PropertyPresentationElements new];

    elements.name = M_ATTR_STR(strConcat(localizedStr(kL10nKeyPropNamePriority), @":", nil));

    if ([task priority] == CalPriorityNone)
        return elements;

    elements.value = M_ATTR_STR(localizedPriority([task priority]));
    return elements;
}




// returns a pretty-printed string representation of the specified task property
NSMutableAttributedString* getTaskPropStr(NSString *propName, CalTask *task, CalItemPrintOption printOptions)
{
    if (task == nil)
        return nil;

    PropertyPresentationElements *elements = nil;

    if ([propName isEqualToString:kPropName_title])
    {
        elements = getTaskTitlePresentation(task, printOptions);
    }
    else if ([propName isEqualToString:kPropName_notes])
    {
        elements = getTaskNotesPresentation(task, printOptions);
    }
    else if ([propName isEqualToString:kPropName_url])
    {
        elements = getTaskURLPresentation(task, printOptions);
    }
    else if ([propName isEqualToString:kPropName_UID])
    {
        elements = getTaskUIDPresentation(task, printOptions);
    }
    else if ([propName isEqualToString:kPropName_datetime])
    {
        elements = getTaskDatetimePresentation(task, printOptions);
    }
    else if ([propName isEqualToString:kPropName_priority])
    {
        if (!printOptions.priorityAgnostic)
            elements = getTaskPriorityPresentation(task, printOptions);
    }
    else
        return nil;

    if (elements.value == nil || [elements.value length] == 0)
        return nil;

    if (elements.name != nil && [elements.name length] > 0)
    {
        [elements.name
            setAttributes:getPropNameStringAttributes(propName, task)
            range:NSMakeRange(0, [elements.name length])
            ];
    }

    [elements.value
        setAttributes:getPropValueStringAttributes(propName, [elements.value string], task)
        range:NSMakeRange(0, [elements.value length])
        ];

    // if no foreground color for title, use calendar color by default
    if ([propName isEqualToString:kPropName_title]
        && prettyPrintOptions.useCalendarColorsForTitles
        && ![[[elements.value attributesAtIndex:0 effectiveRange:NULL] allKeys] containsObject:NSForegroundColorAttributeName]
        )
        [elements.value
            addAttribute:NSForegroundColorAttributeName
            value:getClosestAnsiColorForColor([[task calendar] color], YES)
            range:NSMakeRange(0, [elements.value length])
            ];

    if (elements.valueSuffix != nil)
        [elements.value appendAttributedString:elements.valueSuffix];

    NSMutableAttributedString *retVal = kEmptyMutableAttributedString;

    if (elements.name != nil && !printOptions.withoutPropNames)
    {
        [elements.name appendAttributedString:ATTR_STR(@" ")];
        [retVal appendAttributedString:elements.name];
    }

    [retVal appendAttributedString:elements.value];

    return retVal;
}




// pretty-prints out the specified task
void printCalTask(CalTask *task, CalItemPrintOption printOptions)
{
    if (prettyPrintOptions.maxNumPrintedItems > 0 && prettyPrintOptions.maxNumPrintedItems <= prettyPrintOptions.numPrintedItems)
        return;

    if (task == nil)
        return;

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
            BOOL useAlertBullet =   ([task dueDate] != nil &&
                                     [now compare:[task dueDate]] == NSOrderedDescending);
            prefixStr = mutableAttrStrWithAttrs(
                ((useAlertBullet)?prettyPrintOptions.prefixStrBulletAlert:prettyPrintOptions.prefixStrBullet),
                getBulletStringAttributes(useAlertBullet, task)
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
                addAttributes:getFirstLineStringAttributes(task)
                range:NSMakeRange(0,[thisOutput length])
                ];

        ADD_TO_OUTPUT_BUFFER(thisOutput);

        numPrintedProps++;
    }

    if (numPrintedProps > 0)
        ADD_TO_OUTPUT_BUFFER(M_ATTR_STR(@"\n"));

    prettyPrintOptions.numPrintedItems++;
}





void printItemSections(NSArray *sections, CalItemPrintOption printOptions)
{
    BOOL currentIsFirstPrintedSection = YES;

    for (NSValue *nsValue in sections)
    {
        if (prettyPrintOptions.maxNumPrintedItems > 0 && prettyPrintOptions.maxNumPrintedItems <= prettyPrintOptions.numPrintedItems)
            break;

        PrintSection section;
        NSVALUE_TO_SECTION(nsValue, section);

        // print section title
        if (!currentIsFirstPrintedSection)
            ADD_TO_OUTPUT_BUFFER(M_ATTR_STR(@"\n"));
        NSMutableAttributedString *thisOutput = M_ATTR_STR(
            strConcat(section.title, @":", prettyPrintOptions.sectionSeparatorStr, nil)
            );
        [thisOutput
            addAttributes:getSectionTitleStringAttributes(section.title)
            range:NSMakeRange(0,[thisOutput length])
            ];

        // if the section title has no foreground color and we're told to
        // use calendar colors for them, do so
        if (printOptions.calendarColorsForSectionTitles
            && prettyPrintOptions.useCalendarColorsForTitles
            && ![[[thisOutput attributesAtIndex:0 effectiveRange:NULL] allKeys] containsObject:NSForegroundColorAttributeName]
            && section.items != nil && [section.items count] > 0
            )
        {
            [thisOutput
                addAttribute:NSForegroundColorAttributeName
                value:getClosestAnsiColorForColor([[((CalCalendarItem *)[section.items objectAtIndex:0]) calendar] color], YES)
                range:NSMakeRange(0, [thisOutput length])
                ];
        }

        ADD_TO_OUTPUT_BUFFER(thisOutput);
        ADD_TO_OUTPUT_BUFFER(M_ATTR_STR(@"\n"));
        currentIsFirstPrintedSection = NO;

        if (section.items == nil || [section.items count] == 0)
        {
            // print the "no items" text
            NSMutableAttributedString *noItemsTextOutput = M_ATTR_STR(
                strConcat(localizedStr(kL10nKeyNoItemsInSection), @"\n", nil)
                );
            [noItemsTextOutput
                addAttributes:getStringAttributesForKey(kFormatKeyNoItems, nil)
                range:NSMakeRange(0,[noItemsTextOutput length])
                ];
            ADD_TO_OUTPUT_BUFFER(noItemsTextOutput);
            continue;
        }

        // print items in section
        for (CalCalendarItem *item in section.items)
        {
            if ([item isKindOfClass:[CalEvent class]])
            {
                NSDate *contextDay = section.eventsContextDay;
                if (contextDay == nil)
                    contextDay = now;
                printCalEvent((CalEvent*)item, printOptions, contextDay);
            }
            else if ([item isKindOfClass:[CalTask class]])
                printCalTask((CalTask*)item, printOptions);
        }
    }
}



void printAllCalendars(AppOptions *opts)
{
    NSArray *calendars = getCalendars(opts);

    for (CalCalendar *cal in calendars)
    {
        ADD_TO_OUTPUT_BUFFER(ATTR_STR(@"• "));
        NSMutableAttributedString *calendarName = M_ATTR_STR([cal title]);
        [calendarName addAttribute:NSForegroundColorAttributeName value:[cal color] range:NSMakeRange(0, [calendarName length])];
        ADD_TO_OUTPUT_BUFFER(calendarName);
        ADD_TO_OUTPUT_BUFFER(ATTR_STR(@"\n"));
        ADD_TO_OUTPUT_BUFFER(ATTR_STR(([NSString stringWithFormat:@"  type: %@\n", [cal type]])));
        ADD_TO_OUTPUT_BUFFER(ATTR_STR(([NSString stringWithFormat:@"  UID: %@\n", [cal uid]])));
    }
}



void flushOutputBuffer(NSMutableAttributedString *buffer, AppOptions *opts, NSDictionary *formattedKeywords)
{
    if (opts->useFormatting
        && formattedKeywords != nil
        && areWePrintingItems(opts)
        )
    {
        // it seems we need to do some search & replace for the output
        // before pushing the buffer to stdout.

        for (NSString *keyword in [formattedKeywords allKeys])
        {
            NSDictionary* thisKeywordFormattingAttrs = formattingConfigToStringAttributes([formattedKeywords objectForKey:keyword], nil);

            NSString *cleanStdoutBuffer = [buffer string];
            NSRange searchRange = NSMakeRange(0,[buffer length]);
            NSRange foundRange;
            do
            {
                foundRange = [cleanStdoutBuffer rangeOfString:keyword options:NSLiteralSearch range:searchRange];
                if (foundRange.location != NSNotFound)
                {
                    [buffer addAttributes:thisKeywordFormattingAttrs range:foundRange];
                    searchRange.location = NSMaxRange(foundRange);
                    searchRange.length = [buffer length]-searchRange.location;
                }
            }
            while (foundRange.location != NSNotFound);
        }
    }

    NSString *finalOutput = nil;

    if (opts->useFormatting)
    {
        processCustomStringAttributes(&buffer);
        finalOutput = ansiEscapedStringWithAttributedString(buffer);
    }
    else
        finalOutput = [buffer string];

    Print(finalOutput);
}



