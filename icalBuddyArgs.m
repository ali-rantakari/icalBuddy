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

#import "icalBuddyArgs.h"
#import "HGUtils.h"
#import "HGCLIUtils.h"
#import "icalBuddyPrettyPrint.h"
#import "icalBuddyMacros.h"



Arguments args = {NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,nil,nil,nil,nil,nil,nil,nil,nil};



void readArgsFromConfigFile(NSString *filePath, NSMutableDictionary **retConfigDict)
{
	NSMutableDictionary *configDict = nil;
	
	if (filePath == nil || [filePath length] == 0)
		return;
	
	BOOL configFileIsDir;
	BOOL configFileExists = [[NSFileManager defaultManager]
		fileExistsAtPath:filePath
		isDirectory:&configFileIsDir
		];
	if (!configFileExists || configFileIsDir)
		return;
	
	BOOL configFileIsValid = YES;
	
	configDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
	
	if (configDict == nil)
	{
		PrintfErr(@"* Error in configuration file \"%@\":\n", filePath);
		PrintfErr(@"  can not recognize file format -- must be a valid property list\n");
		PrintfErr(@"  with a structure specified in the icalBuddyConfig man page.\n");
		configFileIsValid = NO;
	}
	
	if (!configFileIsValid)
	{
		PrintfErr(@"\nTry running \"man icalBuddyConfig\" to read the relevant documentation\n");
		PrintfErr(@"and \"plutil '%@'\" to validate the\nfile's property list syntax.\n\n", filePath);
		return;
	}
	
	if (retConfigDict != NULL)
		*retConfigDict = configDict;
	
	NSDictionary *constArgsDict = [configDict objectForKey:@"constantArguments"];
	if (constArgsDict == nil)
		return;
	
	NSArray *allArgKeys = [constArgsDict allKeys];
	if ([allArgKeys containsObject:@"bullet"])
		prettyPrintOptions.prefixStrBullet = [constArgsDict objectForKey:@"bullet"];
	if ([allArgKeys containsObject:@"alertBullet"])
		prettyPrintOptions.prefixStrBulletAlert = [constArgsDict objectForKey:@"alertBullet"];
	if ([allArgKeys containsObject:@"sectionSeparator"])
		prettyPrintOptions.sectionSeparatorStr = [constArgsDict objectForKey:@"sectionSeparator"];
	if ([allArgKeys containsObject:@"timeFormat"])
		prettyPrintOptions.timeFormatStr = [constArgsDict objectForKey:@"timeFormat"];
	if ([allArgKeys containsObject:@"dateFormat"])
		prettyPrintOptions.dateFormatStr = [constArgsDict objectForKey:@"dateFormat"];
	if ([allArgKeys containsObject:@"includeEventProps"])
		prettyPrintOptions.includedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"includeEventProps"]);
	if ([allArgKeys containsObject:@"excludeEventProps"])
		prettyPrintOptions.excludedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"excludeEventProps"]);
	if ([allArgKeys containsObject:@"includeTaskProps"])
		prettyPrintOptions.includedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"includeTaskProps"]);
	if ([allArgKeys containsObject:@"excludeTaskProps"])
		prettyPrintOptions.excludedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"excludeTaskProps"]);
	if ([allArgKeys containsObject:@"includeCals"])
		args.includeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"includeCals"]);
	if ([allArgKeys containsObject:@"excludeCals"])
		args.excludeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"excludeCals"]);
	if ([allArgKeys containsObject:@"prettyPrintOptions.propertyOrder"])
		args.propertyOrderStr = [constArgsDict objectForKey:@"prettyPrintOptions.propertyOrder"];
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
		prettyPrintOptions.displayRelativeDates = ![[constArgsDict objectForKey:@"noRelativeDates"] boolValue];
	if ([allArgKeys containsObject:@"showEmptyDates"])
		args.sectionsForEachDayInSpan = [[constArgsDict objectForKey:@"showEmptyDates"] boolValue];
	if ([allArgKeys containsObject:@"prettyPrintOptions.notesNewlineReplacement"])
		prettyPrintOptions.notesNewlineReplacement = [constArgsDict objectForKey:@"prettyPrintOptions.notesNewlineReplacement"];
	if ([allArgKeys containsObject:@"limitItems"])
		prettyPrintOptions.maxNumPrintedItems = [[constArgsDict objectForKey:@"limitItems"] unsignedIntegerValue];
	if ([allArgKeys containsObject:@"propertySeparators"])
		args.propertySeparatorsStr = [constArgsDict objectForKey:@"propertySeparators"];
	if ([allArgKeys containsObject:@"prettyPrintOptions.excludeEndDates"])
		prettyPrintOptions.excludeEndDates = [[constArgsDict objectForKey:@"prettyPrintOptions.excludeEndDates"] boolValue];
	if ([allArgKeys containsObject:@"sortTasksByDate"])
		args.sortTasksByDueDate = [[constArgsDict objectForKey:@"sortTasksByDate"] boolValue];
	if ([allArgKeys containsObject:@"sortTasksByDateAscending"])
		args.sortTasksByDueDateAscending = [[constArgsDict objectForKey:@"sortTasksByDateAscending"] boolValue];
	if ([allArgKeys containsObject:@"noPropNames"])
		args.noPropNames = [[constArgsDict objectForKey:@"noPropNames"] boolValue];
	if ([allArgKeys containsObject:@"prettyPrintOptions.showUIDs"])
		prettyPrintOptions.showUIDs = [[constArgsDict objectForKey:@"prettyPrintOptions.showUIDs"] boolValue];
	if ([allArgKeys containsObject:@"debug"])
		debugPrintEnabled = [[constArgsDict objectForKey:@"debug"] boolValue];
}


void readArgs(int argc, char *argv[])
{
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
	
	for (int i = 1; i < argc; i++)
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
			prettyPrintOptions.displayRelativeDates = NO;
		else if ((strcmp(argv[i], "-eed") == 0) || (strcmp(argv[i], "--prettyPrintOptions.excludeEndDates") == 0))
			prettyPrintOptions.excludeEndDates = YES;
		else if ((strcmp(argv[i], "-std") == 0) || (strcmp(argv[i], "--sortTasksByDate") == 0))
			args.sortTasksByDueDate = YES;
		else if ((strcmp(argv[i], "-stda") == 0) || (strcmp(argv[i], "--sortTasksByDateAscending") == 0))
			args.sortTasksByDueDateAscending = YES;
		else if ((strcmp(argv[i], "-sed") == 0) || (strcmp(argv[i], "--showEmptyDates") == 0))
			args.sectionsForEachDayInSpan = YES;
		else if ((strcmp(argv[i], "-uid") == 0) || (strcmp(argv[i], "--prettyPrintOptions.showUIDs") == 0))
			prettyPrintOptions.showUIDs = YES;
		else if ((strcmp(argv[i], "-npn") == 0) || (strcmp(argv[i], "--noPropNames") == 0))
			args.noPropNames = YES;
		else if (((strcmp(argv[i], "-b") == 0) || (strcmp(argv[i], "--bullet") == 0)) && (i+1 < argc))
			prettyPrintOptions.prefixStrBullet = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-ab") == 0) || (strcmp(argv[i], "--alertBullet") == 0)) && (i+1 < argc))
			prettyPrintOptions.prefixStrBulletAlert = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-ss") == 0) || (strcmp(argv[i], "--sectionSeparator") == 0)) && (i+1 < argc))
			prettyPrintOptions.sectionSeparatorStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-tf") == 0) || (strcmp(argv[i], "--timeFormat") == 0)) && (i+1 < argc))
			prettyPrintOptions.timeFormatStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-df") == 0) || (strcmp(argv[i], "--dateFormat") == 0)) && (i+1 < argc))
			prettyPrintOptions.dateFormatStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-iep") == 0) || (strcmp(argv[i], "--includeEventProps") == 0)) && (i+1 < argc))
			prettyPrintOptions.includedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-eep") == 0) || (strcmp(argv[i], "--excludeEventProps") == 0)) && (i+1 < argc))
			prettyPrintOptions.excludedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-itp") == 0) || (strcmp(argv[i], "--includeTaskProps") == 0)) && (i+1 < argc))
			prettyPrintOptions.includedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-etp") == 0) || (strcmp(argv[i], "--excludeTaskProps") == 0)) && (i+1 < argc))
			prettyPrintOptions.excludedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-nnr") == 0) || (strcmp(argv[i], "--prettyPrintOptions.notesNewlineReplacement") == 0)) && (i+1 < argc))
			prettyPrintOptions.notesNewlineReplacement = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-ic") == 0) || (strcmp(argv[i], "--includeCals") == 0)) && (i+1 < argc))
			args.includeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-ec") == 0) || (strcmp(argv[i], "--excludeCals") == 0)) && (i+1 < argc))
			args.excludeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-po") == 0) || (strcmp(argv[i], "--prettyPrintOptions.propertyOrder") == 0)) && (i+1 < argc))
			args.propertyOrderStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if ((strcmp(argv[i], "--strEncoding") == 0) && (i+1 < argc))
			args.strEncoding = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-li") == 0) || (strcmp(argv[i], "--limitItems") == 0)) && (i+1 < argc))
			prettyPrintOptions.maxNumPrintedItems = abs([[NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding] integerValue]);
		else if (((strcmp(argv[i], "-ps") == 0) || (strcmp(argv[i], "--propertySeparators") == 0)) && (i+1 < argc))
			args.propertySeparatorsStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
	}
}



void processArgs(NSArray **retPropertySeparators)
{
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
		prettyPrintOptions.propertyOrder = tempPropertyOrder;
	}
	else
		prettyPrintOptions.propertyOrder = kDefaultPropertyOrder;
	
	
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
	
	if (retPropertySeparators != NULL)
		*retPropertySeparators = propertySeparators;
	
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
	prettyPrintOptions.sectionSeparatorStr = translateEscapeSequences(prettyPrintOptions.sectionSeparatorStr);
	prettyPrintOptions.timeFormatStr = translateEscapeSequences(prettyPrintOptions.timeFormatStr);
	prettyPrintOptions.dateFormatStr = translateEscapeSequences(prettyPrintOptions.dateFormatStr);
	prettyPrintOptions.prefixStrBullet = translateEscapeSequences(prettyPrintOptions.prefixStrBullet);
	prettyPrintOptions.prefixStrBulletAlert = translateEscapeSequences(prettyPrintOptions.prefixStrBulletAlert);
	prettyPrintOptions.notesNewlineReplacement = translateEscapeSequences(prettyPrintOptions.notesNewlineReplacement);
}








