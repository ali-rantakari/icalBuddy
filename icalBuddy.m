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
#import <AppKit/AppKit.h>

#import "HGUtils.h"
#import "HGCLIUtils.h"
#import "HGCLIAutoUpdater.h"
#import "HGDateFunctions.h"

#import "icalBuddyDefines.h"

#import "icalBuddyL10N.h"
#import "icalBuddyFormatting.h"
#import "icalBuddyPrettyPrint.h"
#import "icalBuddyArgs.h"
#import "icalBuddyFunctions.h"

#import "IcalBuddyAutoUpdaterDelegate.h"


struct
{
    int major;
    int minor;
    int build;
} version = {1,8,5};

NSString* versionNumberStr()
{
    return [NSString stringWithFormat:@"%i.%i.%i", version.major, version.minor, version.build];
}


int main(int argc, char *argv[])
{
    NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];

    // the output buffer string where we add everything we
    // want to print out, and right before terminating
    // convert to an ANSI-escaped string and push it to
    // the standard output. this way we can easily modify
    // the formatting of the output right up until the
    // last minute.
    NSMutableAttributedString *stdoutBuffer = kEmptyMutableAttributedString;

    now = [NSDate date];
    today = dateForStartOfDay(now);

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


    AppOptions opts = NEW_DEFAULT_APP_OPTIONS;
    PrettyPrintOptions prettyPrintOptions = getDefaultPrettyPrintOptions();

    // read and validate general configuration file
    NSMutableDictionary *configDict = nil;
    NSDictionary *userSuppliedFormattingConfigDict = nil;
    if (configFilePath == nil)
        configFilePath = [kConfigFilePath stringByExpandingTildeInPath];
    if (configFilePath != nil && [configFilePath length] > 0)
    {
        readArgsFromConfigFile(&opts, &prettyPrintOptions, configFilePath, &configDict);
        if (configDict != nil)
            userSuppliedFormattingConfigDict = [configDict objectForKey:@"formatting"];
    }

    readProgramArgs(&opts, &prettyPrintOptions, argc, argv);

    NSArray *propertySeparators = nil;
    processAppOptions(&opts, &prettyPrintOptions, &propertySeparators);

    initFormatting(userSuppliedFormattingConfigDict, propertySeparators);

    initPrettyPrint(stdoutBuffer, prettyPrintOptions);


    // ------------------------------------------------------------------
    // ------------------------------------------------------------------
    // print version and exit
    // ------------------------------------------------------------------
    if (opts.printVersion)
    {
        Printf(@"%@\n", versionNumberStr());
    }
    // ------------------------------------------------------------------
    // ------------------------------------------------------------------
    // check for updates
    // ------------------------------------------------------------------
    else if (opts.updatesCheck)
    {
        HGCLIAutoUpdater *autoUpdater = [[[HGCLIAutoUpdater alloc]
            initWithAppName:@"icalBuddy"
            currentVersionStr:versionNumberStr()
            ] autorelease];
        IcalBuddyAutoUpdaterDelegate *autoUpdaterDelegate = [[[IcalBuddyAutoUpdaterDelegate alloc] init] autorelease];
        autoUpdater.delegate = autoUpdaterDelegate;
        [autoUpdater checkForUpdatesWithUI];
    }
    // ------------------------------------------------------------------
    // ------------------------------------------------------------------
    // print possible values for the string encoding argument and exit
    // ------------------------------------------------------------------
    else if ([opts.output isEqualToString:@"strEncodings"])
    {
        printAvailableStringEncodings();
    }
    // ------------------------------------------------------------------
    // ------------------------------------------------------------------
    // print all calendars
    // ------------------------------------------------------------------
    else if ([opts.output isEqualToString:@"calendars"])
    {
        printAllCalendars(&opts);
    }
    // ------------------------------------------------------------------
    // ------------------------------------------------------------------
    // open config file for editing
    // ------------------------------------------------------------------
    else if ([opts.output hasPrefix:@"editConfig"])
    {
        openConfigFileInEditor(configFilePath, [opts.output hasSuffix:@"CLI"]);
    }
    // ------------------------------------------------------------------
    // ------------------------------------------------------------------
    // print events or tasks
    // ------------------------------------------------------------------
    else if (areWePrintingItems(&opts))
    {
        BOOL usingSubheadings = (opts.separateByCalendar || opts.separateByDate
                                 || (areWePrintingTasks(&opts) && opts.separateByPriority));

        NSArray *calItems = getCalItems(&opts);
        if (calItems == nil)
            return 1;

        CalItemPrintOption printOptions = getPrintOptions(&opts);

        calItems = sortCalItems(&opts, calItems);

        if (usingSubheadings)
        {
            NSArray *sections = putItemsUnderSections(&opts, calItems);
            printItemSections(sections, printOptions);
        }
        else
        {
            for (CalCalendarItem *item in calItems)
            {
                if ([item isKindOfClass:[CalEvent class]])
                    printCalEvent((CalEvent *)item, printOptions, now);
                else
                    printCalTask((CalTask *)item, printOptions);
            }
        }
    }
    // ------------------------------------------------------------------
    // ------------------------------------------------------------------
    else
    {
        Printf(@"\n");
        Printf(@"USAGE: %@ [options] <command>\n", [[NSString stringWithCString:argv[0] encoding:NSUTF8StringEncoding] lastPathComponent]);
        Printf(@"\n"
               @"<command> specifies the general action icalBuddy should take:\n"
               @"\n"
               @"  'eventsToday'      Print events occurring today\n"
               @"  'eventsToday+NUM'  Print events occurring between today and NUM days into\n"
               @"                     the future\n"
               @"  'eventsNow'        Print events occurring at present time\n"
               @"  'eventsFrom:START to:END'\n"
               @"                     Print events occurring between the two specified dates\n"
               @"  'uncompletedTasks' Print uncompleted tasks\n"
               @"  'undatedUncompletedTasks'\n"
               @"                     Print uncompleted tasks that have no due date\n"
               @"  'tasksDueBefore:DATE'\n"
               @"                     Print uncompleted tasks that are due before the given\n"
               @"                     date, which can be 'today+NUM' or any regular date\n"
               @"  'calendars'        Print all calendars\n"
               @"  'strEncodings'     Print all the possible string encodings\n"
               @"  'editConfig'       Open the configuration file for editing in a GUI editor\n"
               @"  'editConfigCLI'    Open the configuration file for editing in a CLI editor\n"
               @"\n"
               @"Some of the [options] you can use are:\n"
               @"\n"
               @"-V          Print version number (no <command> needed)\n"
               @"-u          Check for updates to self online (no <command> needed)\n"
               @"-sc,-sd,-sp Separate by calendar, date or priority\n"
               @"-f          Format output\n"
               @"-nc         No calendar names\n"
               @"-nrd        No relative dates\n"
               @"-npn        No property names\n"
               @"-n          Include only events from now on\n"
               @"-sed        Show empty dates\n"
               @"-uid        Show event/task UIDs\n"
               @"-eed        Exclude end datetimes\n"
               @"-ea         Exclude all-day events\n"
               @"-li         Limit items (value required)\n"
               @"-std,-stda  Sort tasks by due date (stda = ascending)\n"
               @"-tf,-df     Set time or date format (value required)\n"
               @"-po         Set property order (value required)\n"
               @"-ps         Set property separators (value required)\n"
               @"-b          Set bullet point (value required)\n"
               @"-ab         Set alert bullet point (value required)\n"
               @"-ss         Set section separator (value required)\n"
               @"-ic,-ec     Include or exclude calendars (value required)\n"
               @"-iep,-eep   Include or exclude event properties (value required)\n"
               @"-itp,-etp   Include or exclude task properties (value required)\n"
               @"-cf,-lf     Set config or localization file path (value required)\n"
               @"-nnr        Set replacement for newlines within notes (value required)\n"
               @"\n"
               @"See the icalBuddy man page for more info.\n"
               @"\n");
        Printf(@"Version %@\n", versionNumberStr());
        Printf(@"Copyright 2008-2012 Ali Rantakari, http://hasseg.org/icalBuddy\n");
        Printf(@"\n");
    }


    // we've been buffering the output for stdout into an attributed string,
    // now's the time to print out that buffer.
    NSDictionary *formattedKeywords = nil;
    if (configDict != nil)
        formattedKeywords = [configDict objectForKey:@"formattedKeywords"];
    flushOutputBuffer(stdoutBuffer, &opts, formattedKeywords);


    [autoReleasePool release];
    return(0);
}
