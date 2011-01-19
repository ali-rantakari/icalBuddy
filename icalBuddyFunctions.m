// icalBuddy
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
#import "calendarStoreImport.h"

#import "icalBuddyFunctions.h"
#import "icalBuddyDefines.h"

#import "HGCLIUtils.h"
#import "HGDateFunctions.h"
#import "icalBuddyPrettyPrint.h"
#import "icalBuddyL10N.h"



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

BOOL areWePrintingItems(Arguments *args)
{
	return (areWePrintingEvents(args) || areWePrintingTasks(args));
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
		dateRangeStart = dateFromUserInput(args->eventsFrom, @"start date", NO);
		dateRangeEnd = dateFromUserInput(args->eventsTo, @"end date", YES);
		
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
	
	args->startDate = ((args->includeOnlyEventsFromNowOn) ? now : dateRangeStart);
	args->endDate = dateRangeEnd;
	DebugPrintf(@"effective query start date: %@\n", args->startDate);
	DebugPrintf(@"effective query end date:   %@\n", args->endDate);
	
	// make predicate for getting all events between start and end dates + use it to get the events
	NSPredicate *eventsPredicate = [CALENDAR_STORE
		eventPredicateWithStartDate:args->startDate
		endDate:args->endDate
		calendars:calendars
		];
	return [[CALENDAR_STORE defaultCalendarStore] eventsWithPredicate:eventsPredicate];
}


NSArray *getTasks(Arguments *args, NSArray *calendars)
{
	NSPredicate *tasksPredicate = nil;
	
	if (args->output_is_tasksDueBefore)
	{
		NSDate *dueBeforeDate = nil;
		
		NSString *dueBeforeDateStr = [args->output substringFromIndex:15]; // "tasksDueBefore:" has 15 chars
		dueBeforeDate = dateFromUserInput(dueBeforeDateStr, @"due date", NO);
		
		if (dueBeforeDate == nil)
		{
			PrintfErr(@"\n");
			printDateFormatInfo();
			return nil;
		}
		
		args->dueBeforeDate = dueBeforeDate;
		DebugPrintf(@"effective query 'due before' date: %@\n", dueBeforeDate);
		tasksPredicate = [CALENDAR_STORE taskPredicateWithUncompletedTasksDueBefore:dueBeforeDate calendars:calendars];
	}
	else // all uncompleted tasks
		tasksPredicate = [CALENDAR_STORE taskPredicateWithUncompletedTasks:calendars];
	
	return [[CALENDAR_STORE defaultCalendarStore] tasksWithPredicate:tasksPredicate];
}


NSArray *getCalItems(Arguments *args)
{
	NSArray *calendars = getCalendars(args);
	
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



NSArray *putItemsUnderSections(Arguments *args, NSArray *calItems)
{
	NSMutableArray *sections = nil;
	
	BOOL printingEvents = areWePrintingEvents(args);
	BOOL printingTasks = areWePrintingTasks(args);
	BOOL printingAlsoPastEvents = areWePrintingAlsoPastEvents(args);
	
	if (args->separateByCalendar)
	{
		NSArray *calendars = getCalendars(args);
		sections = [NSMutableArray arrayWithCapacity:[calendars count]];
		
		for (CalCalendar *cal in calendars)
		{
			NSMutableArray *thisCalendarItems = [NSMutableArray arrayWithCapacity:((printingEvents)?[calItems count]:[calItems count])];
			
			if (printingEvents)
				[thisCalendarItems addObjectsFromArray:calItems];
			else if (printingTasks)
				[thisCalendarItems addObjectsFromArray:calItems];
			
			[thisCalendarItems filterUsingPredicate:[NSPredicate predicateWithFormat:@"calendar.uid == %@", [cal uid]]];
			
			if (thisCalendarItems != nil && [thisCalendarItems count] > 0)
			{
				PrintSection section = {[cal title], thisCalendarItems, nil};
				[sections addObject:SECTION_TO_NSVALUE(section)];
			}
		}
	}
	else if (args->separateByDate)
	{
		// keys: NSDates (representing *days* to use as sections),
		// values: NSArrays of CalCalendarItems that match those days
		NSMutableDictionary *allDays = [NSMutableDictionary dictionaryWithCapacity:[calItems count]];
		
		if (printingEvents)
		{
			// fill allDays using event start dates' days and all spanned days thereafter
			// if the event spans multiple days
			for (CalEvent *anEvent in calItems)
			{
				// calculate anEvent's days span and limit it to the range of days we
				// want displayed
				
				NSUInteger anEventDaysSpan = getDayDiff([anEvent startDate], [anEvent endDate]);
				
				// the previous method call returns day spans that are one day too long for
				// all-day events so in those cases we'll subtract one
				if ([anEvent isAllDay] && anEventDaysSpan > 0)
					anEventDaysSpan--;
				
				NSUInteger eventsDateRangeDaysSpan = getDayDiff(args->startDate, args->endDate);
				NSUInteger rangeStartToAnEventStartDaysSpan = getDayDiff(args->startDate, [anEvent startDate]);
				
				NSUInteger daySpanLeftInRange = eventsDateRangeDaysSpan - rangeStartToAnEventStartDaysSpan;
				NSUInteger anEventDaysSpanToConsider = MIN(daySpanLeftInRange, anEventDaysSpan);
				
				NSDate *thisEventStartDate = [anEvent startDate];
				
				NSDate *fullDaysStartDate = dateForStartOfDay(args->startDate);
				NSDate *fullDaysEndDate = dateForEndOfDay(args->endDate);
				
				for (NSUInteger i = 0; i <= anEventDaysSpanToConsider; i++)
				{
					NSDate *dayToAdd = dateForStartOfDay(dateByAddingDays(thisEventStartDate, i));
					
					NSComparisonResult dayToAddToEndComparisonResult = [dayToAdd compare:fullDaysEndDate];
					if (dayToAddToEndComparisonResult == NSOrderedDescending
						|| dayToAddToEndComparisonResult == NSOrderedSame
						)
						break;
					
					if ([dayToAdd compare:fullDaysStartDate] == NSOrderedAscending)
						continue;
					
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
			for (CalTask *aTask in calItems)
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
		
		sections = [NSMutableArray arrayWithCapacity:[calItems count]];
		
		// remove NSNull ("no due date") if it exists and sort the dates
		NSMutableArray *allDaysArr = [NSMutableArray arrayWithCapacity:[[allDays allKeys] count]];
		[allDaysArr addObjectsFromArray:[allDays allKeys]];
		[allDaysArr removeObjectIdenticalTo:[NSNull null]];
		[allDaysArr sortUsingSelector:@selector(compare:)];
		
		if (args->sectionsForEachDayInSpan)
		{
			// fill the day span we have so that all days have an entry
			NSDate *earliestDate = nil;
			NSDate *latestDate = nil;
			
			if (args->output_is_eventsFromTo || args->output_is_eventsToday || args->output_is_eventsNow)
			{
				earliestDate = dateForStartOfDay(args->startDate);
				latestDate = dateForStartOfDay(args->endDate);
			}
			else if (args->output_is_tasksDueBefore)
			{
				earliestDate = [allDaysArr objectAtIndex:0];
				latestDate = dateForStartOfDay(args->dueBeforeDate);
			}
			else if (args->output_is_uncompletedTasks)
			{
				earliestDate = [allDaysArr objectAtIndex:0];
				latestDate = [allDaysArr lastObject];
			}
			else
			{
				PrintfErr(@"No case defined for given output arg.\n");
				exit(1);
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
		if (printingTasks && [allDays objectForKey:[NSNull null]] != nil)
			[allDaysArr addObject:[NSNull null]];
		
		for (id aDayKey in allDaysArr)
		{
			NSArray *thisSectionItems = [allDays objectForKey:aDayKey];
			if (thisSectionItems == nil)
				thisSectionItems = [NSArray array];
			
			NSDate *thisSectionContextDay = nil;
			if (printingEvents && [aDayKey isKindOfClass:[NSDate class]])
				thisSectionContextDay = aDayKey;
			
			NSString *thisSectionTitle = nil;
			if ([aDayKey isKindOfClass:[NSDate class]])
				thisSectionTitle = dateStr(aDayKey, ONLY_DATE);
			else if ([aDayKey isEqual:[NSNull null]])
				thisSectionTitle = strConcat(@"(", localizedStr(kL10nKeyNoDueDate), @")", nil);
			
			PrintSection section = {thisSectionTitle, thisSectionItems, thisSectionContextDay};
			[sections addObject:SECTION_TO_NSVALUE(section)];
		}
	}
	
	return sections;
}




NSMutableArray *filterCalendars(NSMutableArray *cals, NSArray *includeCals, NSArray *excludeCals)
{
	if (includeCals != nil)
		[cals filterUsingPredicate:[NSPredicate predicateWithFormat:@"(uid IN %@) OR (title IN %@)", includeCals, includeCals]];
	if (excludeCals != nil)
		[cals filterUsingPredicate:[NSPredicate predicateWithFormat:@"(NOT(uid IN %@)) AND (NOT(title IN %@))", excludeCals, excludeCals]];
	return cals;
}


NSArray *getCalendars(Arguments *args)
{
	NSMutableArray *calendars = [[[[CALENDAR_STORE defaultCalendarStore] calendars] mutableCopy] autorelease];
	return filterCalendars(calendars, args->includeCals, args->excludeCals);
}


void printAllCalendars(Arguments *args)
{
	NSArray *calendars = getCalendars(args);
	
	for (CalCalendar *cal in calendars)
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


