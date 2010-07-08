


#import "HGDateFunctions.h"
#import "HGCLIUtils.h"


NSCalendarDate *dateForStartOfDay(NSCalendarDate *date)
{
	return [NSCalendarDate
		dateWithYear:[date yearOfCommonEra]
		month:[date monthOfYear]
		day:[date dayOfMonth]
		hour:0
		minute:0
		second:0
		timeZone:[date timeZone]
		];
}

NSCalendarDate *dateByAddingDays(NSCalendarDate *date, NSInteger days)
{
	return [date dateByAddingYears:0 months:0 days:days hours:0 minutes:0 seconds:0];
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


NSInteger getDayDiff(NSDate *date1, NSDate *date2)
{
	if (date1 == nil || date2 == nil)
		return 0;
	
	NSCalendarDate *d1 = dateForStartOfDay([date1 dateWithCalendarFormat:nil timeZone:nil]);
	NSCalendarDate *d2 = dateForStartOfDay([date2 dateWithCalendarFormat:nil timeZone:nil]);
	
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

NSCalendarDate *calDateFromUserInput(NSString *input, NSString *inputName)
{
	return [dateFromUserInput(input, inputName) dateWithCalendarFormat:nil timeZone:nil];
}

void printDateFormatInfo()
{
	PrintfErr(@"You can use some natural language (primarily english) and common date formats when\n");
	PrintfErr(@"specifying dates but the safest format is: \"YYYY-MM-DD HH:MM:SS ±HHMM\"\n\n");
}



