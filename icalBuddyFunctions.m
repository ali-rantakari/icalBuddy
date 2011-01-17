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

#import "icalBuddyFunctions.h"
#import "icalBuddyMacros.h"
#import "HGCLIUtils.h"
#import "HGDateFunctions.h"
#import "icalBuddyPrettyPrint.h"



// todo: the right place for these?
NSDate *now;
NSDate *today;





BOOL areWePrintingEvents(Arguments *args)
{
	return (args->output_is_eventsToday || args->output_is_eventsNow || args->output_is_eventsFromTo);
}

BOOL areWePrintingTasks(Arguments *args)
{
	return (args->output_is_uncompletedTasks || args->output_is_tasksDueBefore);
}

BOOL areWePrintingAlsoPastEvents(Arguments *args)
{
	return (args->output_is_eventsFromTo);
}


NSArray *getEvents(Arguments *args, NSArray *calendars)
{
	NSDate *dateRangeStart = nil;
	NSDate *dateRangeEnd = nil;
	
	// get start and end dates for predicate
	if (args->output_is_eventsToday)
	{
		dateRangeStart = today;
		dateRangeEnd = dateForEndOfDay(now);
	}
	else if (args->output_is_eventsNow)
	{
		dateRangeStart = now;
		dateRangeEnd = now;
	}
	else if (args->output_is_eventsFromTo)
	{
		dateRangeStart = dateFromUserInput(args->eventsFrom, @"start date");
		dateRangeEnd = dateFromUserInput(args->eventsTo, @"end date");
		
		if (dateRangeStart == nil || dateRangeEnd == nil)
		{
			PrintfErr(@"\n");
			printDateFormatInfo();
			return nil;
		}
		
		if ([dateRangeStart compare:dateRangeEnd] == NSOrderedDescending)
		{
			// start date occurs before end date --> swap them
			NSDate *tempSwapDate = dateRangeStart;
			dateRangeStart = dateRangeEnd;
			dateRangeEnd = tempSwapDate;
		}
	}
	NSCAssert((dateRangeStart != nil && dateRangeEnd != nil), @"start or end date is nil");
	
	// expand end date if NUM in "eventsToday+NUM" is specified
	if (args->output_is_eventsToday)
	{
		NSRange arg_output_plusSymbolRange = [args->output rangeOfString:@"+"];
		if (arg_output_plusSymbolRange.location != NSNotFound)
		{
			NSInteger daysToAddToRange = [[args->output substringFromIndex:(arg_output_plusSymbolRange.location+arg_output_plusSymbolRange.length)] integerValue];
			dateRangeEnd = dateByAddingDays(dateRangeEnd, daysToAddToRange);
		}
	}
	
	NSDate *predicateDateStart = ((args->includeOnlyEventsFromNowOn)?now:dateRangeStart);
	NSDate *predicateDateEnd = dateRangeEnd;
	DebugPrintf(@"effective query start date: %@\n", predicateDateStart);
	DebugPrintf(@"effective query end date:   %@\n", predicateDateEnd);
	
	// make predicate for getting all events between start and end dates + use it to get the events
	NSPredicate *eventsPredicate = [CalCalendarStore
		eventPredicateWithStartDate:predicateDateStart
		endDate:predicateDateEnd
		calendars:calendars
		];
	return [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:eventsPredicate];
}


NSArray *getTasks(Arguments *args, NSArray *calendars)
{
	NSPredicate *tasksPredicate = nil;
	
	if (args->output_is_tasksDueBefore)
	{
		NSDate *dueBeforeDate = nil;
		
		NSString *dueBeforeDateStr = [args->output substringFromIndex:15]; // "tasksDueBefore:" has 15 chars
		dueBeforeDate = dateFromUserInput(dueBeforeDateStr, @"due date");
		
		if (dueBeforeDate == nil)
		{
			PrintfErr(@"\n");
			printDateFormatInfo();
			return nil;
		}
		
		DebugPrintf(@"effective query 'due before' date: %@\n", dueBeforeDate);
		tasksPredicate = [CalCalendarStore taskPredicateWithUncompletedTasksDueBefore:dueBeforeDate calendars:calendars];
	}
	else // all uncompleted tasks
		tasksPredicate = [CalCalendarStore taskPredicateWithUncompletedTasks:calendars];
	
	return [[CalCalendarStore defaultCalendarStore] tasksWithPredicate:tasksPredicate];
}


NSArray *getCalItems(Arguments *args)
{
	NSMutableArray *calendars = [[[[CalCalendarStore defaultCalendarStore] calendars] mutableCopy] autorelease];
	calendars = filterCalendars(calendars, args->includeCals, args->excludeCals);
	
	BOOL printingEvents = areWePrintingEvents(args);
	BOOL printingTasks = areWePrintingTasks(args);
	
	if (printingEvents)
		return getEvents(args, calendars);
	else if (printingTasks)
		return getTasks(args, calendars);
	
	return nil;
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



NSArray *sortCalItems(Arguments *args, NSArray *calItems)
{
	NSArray *retCalItems = nil;
	
	BOOL printingTasks = areWePrintingTasks(args);
	
	if (printingTasks)
	{
		if (args->sortTasksByDueDate || args->sortTasksByDueDateAscending)
		{
			retCalItems = [calItems
				sortedArrayUsingDescriptors:[NSArray
					arrayWithObjects:
						[[[NSSortDescriptor alloc] initWithKey:@"dueDate" ascending:args->sortTasksByDueDateAscending] autorelease],
						nil
					]
				];
			
			if (args->sortTasksByDueDateAscending)
			{
				// put tasks with no due date last
				NSArray *tasksWithNoDueDate = [retCalItems
					filteredArrayUsingPredicate:[NSPredicate
						predicateWithFormat:@"dueDate == nil"
						]
					];
				retCalItems = [retCalItems
					filteredArrayUsingPredicate:[NSPredicate
						predicateWithFormat:@"dueDate != nil"
						]
					];
				retCalItems = [retCalItems arrayByAddingObjectsFromArray:tasksWithNoDueDate];
			}
		}
		else
			retCalItems = [calItems sortedArrayUsingFunction:prioritySort context:NULL];
	}
	
	return (retCalItems == nil) ? calItems : retCalItems;
}


int getPrintOptions(Arguments *args)
{
	BOOL printingEvents = areWePrintingEvents(args);
	BOOL printingTasks = areWePrintingTasks(args);
	
	int printOptions = PRINT_OPTION_NONE;
	
	if (printingEvents)
	{
		// default print options
		printOptions = 
			PRINT_OPTION_SINGLE_DAY | 
			(args->noCalendarNames ? PRINT_OPTION_CALENDAR_AGNOSTIC : PRINT_OPTION_NONE);
		
		if (args->output_is_eventsFromTo)
			printOptions &= ~PRINT_OPTION_SINGLE_DAY;
		else if (args->output_is_eventsToday)
		{
			NSRange arg_output_plusSymbolRange = [args->output rangeOfString:@"+"];
			if (arg_output_plusSymbolRange.location != NSNotFound)
				printOptions &= ~PRINT_OPTION_SINGLE_DAY;
		}
	}
	else if (printingTasks)
	{
		printOptions = (args->noCalendarNames ? PRINT_OPTION_CALENDAR_AGNOSTIC : PRINT_OPTION_NONE);
	}
	
	if (args->noPropNames)
		printOptions |= PRINT_OPTION_WITHOUT_PROP_NAMES;
	
	if (args->separateByCalendar)
		printOptions |= PRINT_OPTION_CAL_COLORS_FOR_SECTION_TITLES | PRINT_OPTION_CALENDAR_AGNOSTIC;
	else if (args->separateByDate)
		printOptions |= PRINT_OPTION_SINGLE_DAY;
	
	return printOptions;
}




NSMutableArray *filterCalendars(NSMutableArray *cals, NSArray *includeCals, NSArray *excludeCals)
{
	if (includeCals != nil)
		[cals filterUsingPredicate:[NSPredicate predicateWithFormat:@"(uid IN %@) OR (title IN %@)", includeCals, includeCals]];
	if (excludeCals != nil)
		[cals filterUsingPredicate:[NSPredicate predicateWithFormat:@"(NOT(uid IN %@)) AND (NOT(title IN %@))", excludeCals, excludeCals]];
	return cals;
}


void printAllCalendars(Arguments *args)
{
	// get all calendars
	NSMutableArray *allCalendars = [[[[CalCalendarStore defaultCalendarStore] calendars] mutableCopy] autorelease];
	
	// filter calendars based on arguments
	allCalendars = filterCalendars(allCalendars, args->includeCals, args->excludeCals);
	
	for (CalCalendar *cal in allCalendars)
	{
		Printf(@"* %@\n  uid: %@\n", [cal title], [cal uid]);
	}
}


void printAvailableStringEncodings()
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


void openConfigFileInEditor(NSString *configFilePath, BOOL openInCLIEditor)
{
	NSString *path = configFilePath;
	if (path == nil)
		path = [kConfigFilePath stringByExpandingTildeInPath];
	
	BOOL configFileIsDir;
	BOOL configFileExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&configFileIsDir];
	
	if (!configFileExists)
	{
		[kConfigFileStub writeToFile:path atomically:YES];
		Printf(@"Configuration file did not exist; it has now been created.\n");
	}
	
	if (configFileIsDir)
	{
		PrintfErr(
			@"Error: There seems to be a directory where the configuration\nfile should be: %@\nCan not open configuration file.\n",
			path
			);
		return;
	}
	
	if (openInCLIEditor)
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
				system([strConcat(@"'", foundEditorPath, @"' '", path, @"'", nil) UTF8String]);
		}
		else
		{
			PrintfErr(
				@"Error: Can not find or execute any of the following\neditors in your $PATH: %@\n",
				[preferredEditors componentsJoinedByString:@", "]
				);
		}
	}
	else // GUI editor
	{
		if ([[NSWorkspace sharedWorkspace] fullPathForApplication:kPropertyListEditorAppName] != nil)
		{
			Printf(@"Opening configuration file with the Property List\nEditor application.\n");
			[[NSWorkspace sharedWorkspace] openFile:path withApplication:kPropertyListEditorAppName];
		}
		else
		{
			Printf(@"Opening configuration file with the default application\nassociated with the property list type.\n");
			[[NSWorkspace sharedWorkspace] openFile:path];
		}
	}
}


