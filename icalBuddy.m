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

#import "HGUtils.h"
#import "HGCLIUtils.h"
#import "HGCLIAutoUpdater.h"
#import "HGDateFunctions.h"

#import "icalBuddyMacros.h"
#import "icalBuddyL10N.h"
#import "icalBuddyFormatting.h"
#import "icalBuddyPrettyPrint.h"
#import "icalBuddyArgs.h"

#import "IcalBuddyAutoUpdaterDelegate.h"



const int VERSION_MAJOR = 1;
const int VERSION_MINOR = 7;
const int VERSION_BUILD = 14;

NSString* versionNumberStr()
{
	return [NSString stringWithFormat:@"%d.%d.%d", VERSION_MAJOR, VERSION_MINOR, VERSION_BUILD];
}



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
	
	now = [NSDate date];
	today = dateForStartOfDay(now);
	
	autoUpdater = [[HGCLIAutoUpdater alloc]
		initWithAppName:@"icalBuddy"
		currentVersionStr:versionNumberStr()
		];
	autoUpdaterDelegate = [[IcalBuddyAutoUpdaterDelegate alloc] init];
	autoUpdater.delegate = autoUpdaterDelegate;
	
	initPrettyPrint(now, today, stdoutBuffer);
	
	// read user arguments for specifying paths to the config and
	// localization files before reading any other arguments (we
	// want to load the config first and then read the argv arguments
	// so that the latter could override whatever is set in the
	// former. the localization stuff is just along for the ride
	// (it's good friends with the config stuff and I don't have
	// the heart to separate them))
	NSString *configFilePath = nil;
	NSString *L10nFilePath = nil;
	readConfigAndL10NFilePathArgs(argc, argv, &configFilePath, &L10nFilePath);
	
	initL10N(L10nFilePath);
	
	
	Arguments args = {NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,nil,nil,nil,nil,nil,nil,nil,nil};
	
	// read and validate general configuration file
	configDict = nil;
	NSDictionary *userSuppliedFormattingConfigDict = nil;
	if (configFilePath == nil)
		configFilePath = [kConfigFilePath stringByExpandingTildeInPath];
	if (configFilePath != nil && [configFilePath length] > 0)
	{
		readArgsFromConfigFile(&args, configFilePath, &configDict);
		if (configDict != nil)
			userSuppliedFormattingConfigDict = [configDict objectForKey:@"formatting"];
	}
	
	readProgramArgs(&args, argc, argv);
	
	NSArray *propertySeparators = nil;
	processArgs(&args, &propertySeparators);
	
	initFormatting(userSuppliedFormattingConfigDict, propertySeparators);
	
	
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
