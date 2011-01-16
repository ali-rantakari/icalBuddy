// icalBuddy arguments handling functions
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
#import "icalBuddyPrettyPrint.h"


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


void readArgsFromConfigFile(Arguments *args, PrettyPrintOptions *prettyPrintOptions, NSString *filePath, NSMutableDictionary **retConfigDict);

void readProgramArgs(Arguments *args, PrettyPrintOptions *prettyPrintOptions, int argc, char *argv[]);

void readConfigAndL10NFilePathArgs(int argc, char *argv[], NSString **retConfigFilePath, NSString **retL10NConfigFilePath);

void processArgs(Arguments *args, PrettyPrintOptions *prettyPrintOptions, NSArray **retPropertySeparators);

