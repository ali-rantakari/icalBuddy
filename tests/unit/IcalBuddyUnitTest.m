// icalBuddy-specific unit test
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

#import "IcalBuddyUnitTest.h"


@implementation IcalBuddyUnitTest

- (id) init
{
    if (!(self = [super init]))
        return nil;

    return self;
}

- (void) dealloc
{
    [super dealloc];
}


- (AppOptions) setUpWithNowDate:(NSDate *)date opts:(NSArray *)argsArr
{
    int argc = [argsArr count];
    char **argv = (char **) malloc(sizeof(char *) * (argc + 1));
    for (int i = 0; i < argc; i++)
    {
        NSString *s = [argsArr objectAtIndex:i];
        const char *cstr = [s UTF8String];
        int len = strlen(cstr);
        char *cstr_copy = (char *) malloc(sizeof(char) * (len + 1));
        strcpy(cstr_copy, cstr);
        argv[i] = cstr_copy;
    }



    NSMutableAttributedString *stdoutBuffer = kEmptyMutableAttributedString;

    now = date;
    today = dateForStartOfDay(now);

    // don't read any config or L10N files
    NSString *configFilePath = @"";
    NSString *L10nFilePath = @"";
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
    initFormatting(nil, propertySeparators);
    initPrettyPrint(stdoutBuffer, prettyPrintOptions);

    return opts;
}


@end
