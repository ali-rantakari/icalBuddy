// icalBuddy arguments handling functions
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

#import "icalBuddyArgs.h"
#import "HGUtils.h"
#import "HGCLIUtils.h"
#import "icalBuddyPrettyPrint.h"



void readArgsFromConfigFile(Arguments *args, PrettyPrintOptions *prettyPrintOptions, NSString *filePath, NSMutableDictionary **retConfigDict)
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
		prettyPrintOptions->prefixStrBullet = [constArgsDict objectForKey:@"bullet"];
	if ([allArgKeys containsObject:@"alertBullet"])
		prettyPrintOptions->prefixStrBulletAlert = [constArgsDict objectForKey:@"alertBullet"];
	if ([allArgKeys containsObject:@"sectionSeparator"])
		prettyPrintOptions->sectionSeparatorStr = [constArgsDict objectForKey:@"sectionSeparator"];
	if ([allArgKeys containsObject:@"timeFormat"])
		prettyPrintOptions->timeFormatStr = [constArgsDict objectForKey:@"timeFormat"];
	if ([allArgKeys containsObject:@"dateFormat"])
		prettyPrintOptions->dateFormatStr = [constArgsDict objectForKey:@"dateFormat"];
	if ([allArgKeys containsObject:@"includeEventProps"])
		prettyPrintOptions->includedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"includeEventProps"]);
	if ([allArgKeys containsObject:@"excludeEventProps"])
		prettyPrintOptions->excludedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"excludeEventProps"]);
	if ([allArgKeys containsObject:@"includeTaskProps"])
		prettyPrintOptions->includedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"includeTaskProps"]);
	if ([allArgKeys containsObject:@"excludeTaskProps"])
		prettyPrintOptions->excludedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"excludeTaskProps"]);
	if ([allArgKeys containsObject:@"includeCals"])
		opts->includeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"includeCals"]);
	if ([allArgKeys containsObject:@"excludeCals"])
		opts->excludeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([constArgsDict objectForKey:@"excludeCals"]);
	if ([allArgKeys containsObject:@"propertyOrder"])
		opts->propertyOrderStr = [constArgsDict objectForKey:@"propertyOrder"];
	if ([allArgKeys containsObject:@"strEncoding"])
		opts->strEncoding = [constArgsDict objectForKey:@"strEncoding"];
	if ([allArgKeys containsObject:@"separateByCalendar"])
		opts->separateByCalendar = [[constArgsDict objectForKey:@"separateByCalendar"] boolValue];
	if ([allArgKeys containsObject:@"separateByDate"])
		opts->separateByDate = [[constArgsDict objectForKey:@"separateByDate"] boolValue];
	if ([allArgKeys containsObject:@"includeOnlyEventsFromNowOn"])
		opts->includeOnlyEventsFromNowOn = [[constArgsDict objectForKey:@"includeOnlyEventsFromNowOn"] boolValue];
	if ([allArgKeys containsObject:@"formatOutput"])
		opts->useFormatting = [[constArgsDict objectForKey:@"formatOutput"] boolValue];
	if ([allArgKeys containsObject:@"noCalendarNames"])
		opts->noCalendarNames = [[constArgsDict objectForKey:@"noCalendarNames"] boolValue];
	if ([allArgKeys containsObject:@"noRelativeDates"])
		prettyPrintOptions->displayRelativeDates = ![[constArgsDict objectForKey:@"noRelativeDates"] boolValue];
	if ([allArgKeys containsObject:@"showEmptyDates"])
		opts->sectionsForEachDayInSpan = [[constArgsDict objectForKey:@"showEmptyDates"] boolValue];
	if ([allArgKeys containsObject:@"notesNewlineReplacement"])
		prettyPrintOptions->notesNewlineReplacement = [constArgsDict objectForKey:@"notesNewlineReplacement"];
	if ([allArgKeys containsObject:@"limitItems"])
		prettyPrintOptions->maxNumPrintedItems = [[constArgsDict objectForKey:@"limitItems"] unsignedIntegerValue];
	if ([allArgKeys containsObject:@"propertySeparators"])
		opts->propertySeparatorsStr = [constArgsDict objectForKey:@"propertySeparators"];
	if ([allArgKeys containsObject:@"excludeEndDates"])
		prettyPrintOptions->excludeEndDates = [[constArgsDict objectForKey:@"excludeEndDates"] boolValue];
	if ([allArgKeys containsObject:@"sortTasksByDate"])
		opts->sortTasksByDueDate = [[constArgsDict objectForKey:@"sortTasksByDate"] boolValue];
	if ([allArgKeys containsObject:@"sortTasksByDateAscending"])
		opts->sortTasksByDueDateAscending = [[constArgsDict objectForKey:@"sortTasksByDateAscending"] boolValue];
	if ([allArgKeys containsObject:@"noPropNames"])
		opts->noPropNames = [[constArgsDict objectForKey:@"noPropNames"] boolValue];
	if ([allArgKeys containsObject:@"showUIDs"])
		prettyPrintOptions->showUIDs = [[constArgsDict objectForKey:@"showUIDs"] boolValue];
	if ([allArgKeys containsObject:@"debug"])
		debugPrintEnabled = [[constArgsDict objectForKey:@"debug"] boolValue];
	if ([allArgKeys containsObject:@"showTodaysSection"])
		opts->alwaysShowTodaysSection = [[constArgsDict objectForKey:@"showTodaysSection"] boolValue];
}


void readProgramArgs(AppOptions *opts, PrettyPrintOptions *prettyPrintOptions, int argc, char *argv[])
{
	if (argc > 1)
	{
		opts->output = [NSString stringWithCString: argv[argc-1] encoding: NSASCIIStringEncoding];
		
		opts->output_is_uncompletedTasks = [opts->output isEqualToString:@"uncompletedTasks"];
		opts->output_is_eventsToday = [opts->output hasPrefix:@"eventsToday"];
		opts->output_is_eventsNow = [opts->output isEqualToString:@"eventsNow"];
		opts->output_is_tasksDueBefore = [opts->output hasPrefix:@"tasksDueBefore:"];
		
		if ([opts->output hasPrefix:@"to:"] && argc > 2)
		{
			NSString *secondToLastArg = [NSString stringWithCString: argv[argc-2] encoding: NSASCIIStringEncoding];
			if ([secondToLastArg hasPrefix:@"eventsFrom:"])
			{
				opts->eventsFrom = [secondToLastArg substringFromIndex:11]; // "eventsFrom:" has 11 chars
				opts->eventsTo = [opts->output substringFromIndex:3]; // "to:" has 3 chars
				opts->output_is_eventsFromTo = YES;
			}
		}
	}
	
	for (int i = 1; i < argc; i++)
	{
		if ((strcmp(argv[i], "-sc") == 0) || (strcmp(argv[i], "--separateByCalendar") == 0))
			opts->separateByCalendar = YES;
		else if ((strcmp(argv[i], "-sd") == 0) || (strcmp(argv[i], "--separateByDate") == 0))
			opts->separateByDate = YES;
		else if ((strcmp(argv[i], "-u") == 0) || (strcmp(argv[i], "--checkForUpdates") == 0))
			opts->updatesCheck = YES;
		else if ((strcmp(argv[i], "-V") == 0) || (strcmp(argv[i], "--version") == 0))
			opts->printVersion = YES;
		else if ((strcmp(argv[i], "-d") == 0) || (strcmp(argv[i], "--debug") == 0))
			debugPrintEnabled = YES;
		else if ((strcmp(argv[i], "-n") == 0) || (strcmp(argv[i], "--includeOnlyEventsFromNowOn") == 0))
			opts->includeOnlyEventsFromNowOn = YES;
		else if ((strcmp(argv[i], "-f") == 0) || (strcmp(argv[i], "--formatOutput") == 0))
			opts->useFormatting = YES;
		else if ((strcmp(argv[i], "-nc") == 0) || (strcmp(argv[i], "--noCalendarNames") == 0))
			opts->noCalendarNames = YES;
		else if ((strcmp(argv[i], "-nrd") == 0) || (strcmp(argv[i], "--noRelativeDates") == 0))
			prettyPrintOptions->displayRelativeDates = NO;
		else if ((strcmp(argv[i], "-eed") == 0) || (strcmp(argv[i], "--excludeEndDates") == 0))
			prettyPrintOptions->excludeEndDates = YES;
		else if ((strcmp(argv[i], "-std") == 0) || (strcmp(argv[i], "--sortTasksByDate") == 0))
			opts->sortTasksByDueDate = YES;
		else if ((strcmp(argv[i], "-stda") == 0) || (strcmp(argv[i], "--sortTasksByDateAscending") == 0))
			opts->sortTasksByDueDateAscending = YES;
		else if ((strcmp(argv[i], "-sed") == 0) || (strcmp(argv[i], "--showEmptyDates") == 0))
			opts->sectionsForEachDayInSpan = YES;
		else if ((strcmp(argv[i], "-uid") == 0) || (strcmp(argv[i], "--showUIDs") == 0))
			prettyPrintOptions->showUIDs = YES;
		else if ((strcmp(argv[i], "-npn") == 0) || (strcmp(argv[i], "--noPropNames") == 0))
			opts->noPropNames = YES;
		else if ((strcmp(argv[i], "-t") == 0) || (strcmp(argv[i], "--showTodaysSection") == 0))
			opts->alwaysShowTodaysSection = YES;
		else if (((strcmp(argv[i], "-b") == 0) || (strcmp(argv[i], "--bullet") == 0)) && (i+1 < argc))
			prettyPrintOptions->prefixStrBullet = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-ab") == 0) || (strcmp(argv[i], "--alertBullet") == 0)) && (i+1 < argc))
			prettyPrintOptions->prefixStrBulletAlert = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-ss") == 0) || (strcmp(argv[i], "--sectionSeparator") == 0)) && (i+1 < argc))
			prettyPrintOptions->sectionSeparatorStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-tf") == 0) || (strcmp(argv[i], "--timeFormat") == 0)) && (i+1 < argc))
			prettyPrintOptions->timeFormatStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-df") == 0) || (strcmp(argv[i], "--dateFormat") == 0)) && (i+1 < argc))
			prettyPrintOptions->dateFormatStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-iep") == 0) || (strcmp(argv[i], "--includeEventProps") == 0)) && (i+1 < argc))
			prettyPrintOptions->includedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-eep") == 0) || (strcmp(argv[i], "--excludeEventProps") == 0)) && (i+1 < argc))
			prettyPrintOptions->excludedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-itp") == 0) || (strcmp(argv[i], "--includeTaskProps") == 0)) && (i+1 < argc))
			prettyPrintOptions->includedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-etp") == 0) || (strcmp(argv[i], "--excludeTaskProps") == 0)) && (i+1 < argc))
			prettyPrintOptions->excludedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-nnr") == 0) || (strcmp(argv[i], "--notesNewlineReplacement") == 0)) && (i+1 < argc))
			prettyPrintOptions->notesNewlineReplacement = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-ic") == 0) || (strcmp(argv[i], "--includeCals") == 0)) && (i+1 < argc))
			opts->includeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-ec") == 0) || (strcmp(argv[i], "--excludeCals") == 0)) && (i+1 < argc))
			opts->excludeCals = arrayFromCommaSeparatedStringTrimmingWhitespace([NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding]);
		else if (((strcmp(argv[i], "-po") == 0) || (strcmp(argv[i], "--propertyOrder") == 0)) && (i+1 < argc))
			opts->propertyOrderStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if ((strcmp(argv[i], "--strEncoding") == 0) && (i+1 < argc))
			opts->strEncoding = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
		else if (((strcmp(argv[i], "-li") == 0) || (strcmp(argv[i], "--limitItems") == 0)) && (i+1 < argc))
			prettyPrintOptions->maxNumPrintedItems = abs([[NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding] integerValue]);
		else if (((strcmp(argv[i], "-ps") == 0) || (strcmp(argv[i], "--propertySeparators") == 0)) && (i+1 < argc))
			opts->propertySeparatorsStr = [NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding];
	}
}



void readConfigAndL10NFilePathArgs(int argc, char *argv[], NSString **retConfigFilePath,
								   NSString **retL10NConfigFilePath)
{
	NSString *configFilePath = nil;
	NSString *L10nFilePath = nil;
	
	for (int i = 1; i < argc; i++)
	{
		if (((strcmp(argv[i], "-cf") == 0) || (strcmp(argv[i], "--configFile") == 0)) && (i+1 < argc))
		{
			configFilePath = [[NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding] stringByExpandingTildeInPath];
			if ([configFilePath length] > 0)
			{
				BOOL userSpecifiedConfigFileIsDir;
				BOOL userSpecifiedConfigFileExists = [[NSFileManager defaultManager]
					fileExistsAtPath:configFilePath
					isDirectory:&userSpecifiedConfigFileIsDir
					];
				if (!userSpecifiedConfigFileExists)
				{
					PrintfErr(@"Error: specified configuration file doesn't exist: '%@'\n", configFilePath);
					configFilePath = nil;
				}
				else if (userSpecifiedConfigFileIsDir)
				{
					PrintfErr(@"Error: specified configuration file is a directory: '%@'\n", configFilePath);
					configFilePath = nil;
				}
			}
		}
		else if (((strcmp(argv[i], "-lf") == 0) || (strcmp(argv[i], "--localizationFile") == 0)) && (i+1 < argc))
		{
			L10nFilePath = [[NSString stringWithCString:argv[i+1] encoding:NSUTF8StringEncoding] stringByExpandingTildeInPath];
			if ([L10nFilePath length] > 0)
			{
				BOOL userSpecifiedL10nFileIsDir;
				BOOL userSpecifiedL10nFileExists = [[NSFileManager defaultManager]
					fileExistsAtPath:L10nFilePath
					isDirectory:&userSpecifiedL10nFileIsDir
					];
				if (!userSpecifiedL10nFileExists)
				{
					PrintfErr(@"Error: specified localization file doesn't exist: '%@'\n", L10nFilePath);
					L10nFilePath = nil;
				}
				else if (userSpecifiedL10nFileIsDir)
				{
					PrintfErr(@"Error: specified localization file is a directory: '%@'\n", L10nFilePath);
					L10nFilePath = nil;
				}
			}
		}
	}
	
	if (retConfigFilePath != NULL)
		*retConfigFilePath = configFilePath;
	if (retL10NConfigFilePath != NULL)
		*retL10NConfigFilePath = L10nFilePath;
}


void processAppOptions(AppOptions *opts, PrettyPrintOptions *prettyPrintOptions, NSArray **retPropertySeparators)
{
	if (opts->propertyOrderStr != nil)
	{
		// if property order is specified, filter out property names that are not allowed (the allowed
		// ones are all included in the NSArray specified by the kDefaultPropertyOrder macro definition)
		// and then add to the list the omitted property names in the default order
		NSArray *specifiedPropertyOrder = arrayFromCommaSeparatedStringTrimmingWhitespace(opts->propertyOrderStr);
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
		prettyPrintOptions->propertyOrder = tempPropertyOrder;
	}
	else
		prettyPrintOptions->propertyOrder = kDefaultPropertyOrder;
	
	
	NSArray *propertySeparators = nil;
	if (opts->propertySeparatorsStr != nil)
	{
		NSError *propertySeparatorsArgParseError = nil;
		propertySeparators = arrayFromArbitrarilySeparatedString(opts->propertySeparatorsStr, YES, &propertySeparatorsArgParseError);
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
	
	if (opts->strEncoding != nil)
	{
		// process provided output string encoding argument
		opts->strEncoding = [opts->strEncoding stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSStringEncoding matchedEncoding = 0;
		const NSStringEncoding *availableEncoding = [NSString availableStringEncodings];
		while(*availableEncoding != 0)
		{
			if ([[NSString localizedNameOfStringEncoding: *availableEncoding] isEqualToString:opts->strEncoding])
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
			PrintfErr(@"* Error: Invalid string encoding argument: \"%@\".\n", opts->strEncoding);
			PrintfErr(@"  Run \"icalBuddy strEncodings\" to see all the possible values.\n");
			PrintfErr(@"  Using default encoding \"%@\".\n\n", [NSString localizedNameOfStringEncoding: outputStrEncoding]);
		}
	}
	
	// interpret/translate escape sequences for values of arguments
	// that take arbitrary strings
	prettyPrintOptions->sectionSeparatorStr = translateEscapeSequences(prettyPrintOptions->sectionSeparatorStr);
	prettyPrintOptions->timeFormatStr = translateEscapeSequences(prettyPrintOptions->timeFormatStr);
	prettyPrintOptions->dateFormatStr = translateEscapeSequences(prettyPrintOptions->dateFormatStr);
	prettyPrintOptions->prefixStrBullet = translateEscapeSequences(prettyPrintOptions->prefixStrBullet);
	prettyPrintOptions->prefixStrBulletAlert = translateEscapeSequences(prettyPrintOptions->prefixStrBulletAlert);
	prettyPrintOptions->notesNewlineReplacement = translateEscapeSequences(prettyPrintOptions->notesNewlineReplacement);
}








