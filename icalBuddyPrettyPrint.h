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

#import <Foundation/Foundation.h>
#import <CalendarStore/CalendarStore.h>
#import "icalBuddyDefines.h"


typedef struct
{
	// the order of properties in the output
	NSArray *propertyOrder;
	
	// the prefix strings
	NSString *prefixStrBullet;
	NSString *prefixStrBulletAlert;
	NSString *sectionSeparatorStr;
	
	NSString *timeFormatStr;
	NSString *dateFormatStr;
	NSSet *includedEventProperties;
	NSSet *excludedEventProperties;
	NSSet *includedTaskProperties;
	NSSet *excludedTaskProperties;
	NSString *notesNewlineReplacement;
	
	BOOL displayRelativeDates;
	BOOL excludeEndDates;
	BOOL useCalendarColorsForTitles;
	BOOL showUIDs;
	NSUInteger maxNumPrintedItems; // 0 = no limit
	NSUInteger numPrintedItems;
} PrettyPrintOptions;


#define SECTION_TO_NSVALUE(x)		[NSValue valueWithBytes:&(x) objCType:@encode(PrintSection)]
#define NSVALUE_TO_SECTION(x, y)	[(x) getValue:&(y)]

typedef struct
{
	NSString *title;
	NSArray *items;
	NSDate *eventsContextDay;
} PrintSection;


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


void initPrettyPrint(NSMutableAttributedString *aOutputBuffer, PrettyPrintOptions opts);
PrettyPrintOptions getDefaultPrettyPrintOptions();

NSString* dateStr(NSDate *date, DatePrintOption printOption);

NSMutableAttributedString* getEventPropStr(NSString *propName, CalEvent *event, int printOptions, NSDate *contextDay);
NSMutableAttributedString* getTaskPropStr(NSString *propName, CalTask *task, int printOptions);

void printCalEvent(CalEvent *event, int printOptions, NSDate *contextDay);
void printCalTask(CalTask *task, int printOptions);
void printItemSections(NSArray *sections, int printOptions);

void flushOutputBuffer(NSMutableAttributedString *buffer, Arguments *args, NSDictionary *formattedKeywords);

