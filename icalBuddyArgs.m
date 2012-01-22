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


void handleArgument(NSString *shortName, NSString *longName, id value,
					AppOptions *opts, PrettyPrintOptions *prettyPrintOptions)
{
	// 'on/off' arguments
	BOOL valueMayBeBool = [value respondsToSelector:@selector(boolValue)];
	BOOL valueIsString = [value isKindOfClass:[NSString class]];
	if (valueIsString || !valueMayBeBool || (valueMayBeBool && [value boolValue]))
	{
		if ([shortName isEqualToString:@"sc"] || [longName isEqualToString:@"separateByCalendar"])
			opts->separateByCalendar = YES;
		else if ([shortName isEqualToString:@"sd"] || [longName isEqualToString:@"separateByDate"])
			opts->separateByDate = YES;
		else if ([shortName isEqualToString:@"u"] || [longName isEqualToString:@"checkForUpdates"])
			opts->updatesCheck = YES;
		else if ([shortName isEqualToString:@"V"] || [longName isEqualToString:@"version"])
			opts->printVersion = YES;
		else if ([shortName isEqualToString:@"d"] || [longName isEqualToString:@"debug"])
			debugPrintEnabled = YES;
		else if ([shortName isEqualToString:@"n"] || [longName isEqualToString:@"includeOnlyEventsFromNowOn"])
			opts->includeOnlyEventsFromNowOn = YES;
		else if ([shortName isEqualToString:@"f"] || [longName isEqualToString:@"formatOutput"])
			opts->useFormatting = YES;
		else if ([shortName isEqualToString:@"nc"] || [longName isEqualToString:@"noCalendarNames"])
			opts->noCalendarNames = YES;
		else if ([shortName isEqualToString:@"nrd"] || [longName isEqualToString:@"noRelativeDates"])
			prettyPrintOptions->displayRelativeDates = NO;
		else if ([shortName isEqualToString:@"eed"] || [longName isEqualToString:@"excludeEndDates"])
			prettyPrintOptions->excludeEndDates = YES;
		else if ([shortName isEqualToString:@"std"] || [longName isEqualToString:@"sortTasksByDate"])
			opts->sortTasksByDueDate = YES;
		else if ([shortName isEqualToString:@"stda"] || [longName isEqualToString:@"sortTasksByDateAscending"])
			opts->sortTasksByDueDateAscending = YES;
		else if ([shortName isEqualToString:@"sed"] || [longName isEqualToString:@"showEmptyDates"])
			opts->sectionsForEachDayInSpan = YES;
		else if ([shortName isEqualToString:@"uid"] || [longName isEqualToString:@"showUIDs"])
			prettyPrintOptions->showUIDs = YES;
		else if ([shortName isEqualToString:@"npn"] || [longName isEqualToString:@"noPropNames"])
			opts->noPropNames = YES;
		else if ([shortName isEqualToString:@"t"] || [longName isEqualToString:@"showTodaysSection"])
			opts->alwaysShowTodaysSection = YES;
	}
	
	// value-requiring arguments
	if (value != nil)
	{
		// string value
		NSString *stringValue = nil;
		if ([value isKindOfClass:[NSString class]])
			stringValue = value;
		else if ([value respondsToSelector:@selector(stringValue)])
			stringValue = [value stringValue];
		
		if (stringValue != nil)
		{
			if ([shortName isEqualToString:@"b"] || [longName isEqualToString:@"bullet"])
				prettyPrintOptions->prefixStrBullet = stringValue;
			else if ([shortName isEqualToString:@"ab"] || [longName isEqualToString:@"alertBullet"])
				prettyPrintOptions->prefixStrBulletAlert = stringValue;
			else if ([shortName isEqualToString:@"ss"] || [longName isEqualToString:@"sectionSeparator"])
				prettyPrintOptions->sectionSeparatorStr = stringValue;
			else if ([shortName isEqualToString:@"tf"] || [longName isEqualToString:@"timeFormat"])
				prettyPrintOptions->timeFormatStr = stringValue;
			else if ([shortName isEqualToString:@"df"] || [longName isEqualToString:@"dateFormat"])
				prettyPrintOptions->dateFormatStr = stringValue;
			else if ([shortName isEqualToString:@"iep"] || [longName isEqualToString:@"includeEventProps"])
				prettyPrintOptions->includedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace(stringValue);
			else if ([shortName isEqualToString:@"eep"] || [longName isEqualToString:@"excludeEventProps"])
				prettyPrintOptions->excludedEventProperties = setFromCommaSeparatedStringTrimmingWhitespace(stringValue);
			else if ([shortName isEqualToString:@"itp"] || [longName isEqualToString:@"includeTaskProps"])
				prettyPrintOptions->includedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace(stringValue);
			else if ([shortName isEqualToString:@"etp"] || [longName isEqualToString:@"excludeTaskProps"])
				prettyPrintOptions->excludedTaskProperties = setFromCommaSeparatedStringTrimmingWhitespace(stringValue);
			else if ([shortName isEqualToString:@"ict"] || [longName isEqualToString:@"includeCalTypes"])
				opts->includeCalTypes = arrayFromCommaSeparatedStringTrimmingWhitespace(stringValue);
			else if ([shortName isEqualToString:@"ect"] || [longName isEqualToString:@"excludeCalTypes"])
				opts->excludeCalTypes = arrayFromCommaSeparatedStringTrimmingWhitespace(stringValue);
			else if ([shortName isEqualToString:@"nnr"] || [longName isEqualToString:@"notesNewlineReplacement"])
				prettyPrintOptions->notesNewlineReplacement = stringValue;
			else if ([shortName isEqualToString:@"ic"] || [longName isEqualToString:@"includeCals"])
				opts->includeCals = arrayFromCommaSeparatedStringTrimmingWhitespace(stringValue);
			else if ([shortName isEqualToString:@"ec"] || [longName isEqualToString:@"excludeCals"])
				opts->excludeCals = arrayFromCommaSeparatedStringTrimmingWhitespace(stringValue);
			else if ([shortName isEqualToString:@"po"] || [longName isEqualToString:@"propertyOrder"])
				opts->propertyOrderStr = stringValue;
			else if ([longName isEqualToString:@"strEncoding"])
				opts->strEncoding = stringValue;
			else if ([shortName isEqualToString:@"ps"] || [longName isEqualToString:@"propertySeparators"])
				opts->propertySeparatorsStr = stringValue;
		}
		
		// integer value
		if ([value respondsToSelector:@selector(integerValue)])
		{
			if ([shortName isEqualToString:@"li"] || [longName isEqualToString:@"limitItems"])
				prettyPrintOptions->maxNumPrintedItems = abs([value integerValue]);
		}
	}
}




void readArgsFromConfigFile(AppOptions *opts, PrettyPrintOptions *prettyPrintOptions, NSString *filePath, NSMutableDictionary **retConfigDict)
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
	
	for (NSString *key in [constArgsDict allKeys])
	{
		handleArgument(nil, key, [constArgsDict objectForKey:key], opts, prettyPrintOptions);
	}
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
		opts->output_is_undatedUncompletedTasks = [opts->output isEqualToString:@"undatedUncompletedTasks"];
		
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
		if (strncmp(argv[i], "-", 1) != 0)
			continue;
		
		NSString *shortArgName = nil;
		NSString *longArgName = nil;
		NSString *argValue = nil;
		
		if (strncmp(argv[i], "--", 2) == 0)
			longArgName = [[NSString stringWithUTF8String:argv[i]] substringFromIndex:2];
		else
			shortArgName = [[NSString stringWithUTF8String:argv[i]] substringFromIndex:1];
		
		if (i+1 < argc)
			argValue = [NSString stringWithUTF8String:argv[i+1]];
		
		handleArgument(shortArgName, longArgName, argValue, opts, prettyPrintOptions);
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








