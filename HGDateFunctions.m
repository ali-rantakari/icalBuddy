// Date utility functions
// 
// http://hasseg.org/
//

/*
The MIT License

Copyright (c) 2010 Ali Rantakari

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



#import "HGDateFunctions.h"
#import "HGCLIUtils.h"


NSDate *dateForStartOfDay(NSDate *date)
{
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
	return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

NSDate *dateForEndOfDay(NSDate *date)
{
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
	[comps setHour:23];
	[comps setMinute:59];
	[comps setSecond:59];
	return [[NSCalendar currentCalendar] dateFromComponents:comps];
}


NSDate *dateByAddingDays(NSDate *date, NSInteger days)
{
	NSDateComponents *addDaysComponents = [[[NSDateComponents alloc] init] autorelease];
    [addDaysComponents setDay:days];
    return [[NSCalendar currentCalendar]
		dateByAddingComponents:addDaysComponents
		toDate:date
		options:0
		];
}


// whether the two specified dates represent the same calendar day
BOOL datesRepresentSameDay(NSDate *date1, NSDate *date2)
{
	NSUInteger dateUnitFlags = NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit;
	NSDateComponents *comps1 = [[NSCalendar currentCalendar] components:dateUnitFlags fromDate:date1];
	NSDateComponents *comps2 = [[NSCalendar currentCalendar] components:dateUnitFlags fromDate:date2];
	
	return ([comps1 year] == [comps2 year]
			&& [comps1 month] == [comps2 month]
			&& [comps1 day] == [comps2 day]
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


NSInteger getDayDiff(NSDate *date1, NSDate *date2)
{
	if (date1 == nil || date2 == nil)
		return 0;
	
	NSDate *d1 = dateForStartOfDay([date1 dateWithCalendarFormat:nil timeZone:nil]);
	NSDate *d2 = dateForStartOfDay([date2 dateWithCalendarFormat:nil timeZone:nil]);
	
	NSTimeInterval ti = [d2 timeIntervalSinceDate:d1];
	return abs(ti / (60*60*24));
}

NSDate *dateFromUserInput(NSString *input, NSString *inputName)
{
	NSDate *result = [NSDate dateWithString:input];
	
	if (result == nil)
		result = [NSDate dateWithNaturalLanguageString:input];
	
	NSString *inputDateName = (inputName == nil) ? @"date" : inputName;
	if (result == nil)
		PrintfErr(@"Error: invalid %@: '%@'\n", inputDateName, input);
	else
		DebugPrintf(@"%@ interpreted as: %@\n", inputDateName, result);
	
	return result;
}

void printDateFormatInfo()
{
	PrintfErr(@"You can use some natural language (primarily english) and common date formats when\n");
	PrintfErr(@"specifying dates but the safest format is: \"YYYY-MM-DD HH:MM:SS ±HHMM\"\n\n");
}



