// icalBuddy test runner
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

#define USE_MOCKED_CALENDARSTORE

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

#import "tests/unit/UnitTest.h"
#import "tests/unit/allTests.h"



int main(int argc, char *argv[])
{
	NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
	
	/*
	NSMutableAttributedString *stdoutBuffer = kEmptyMutableAttributedString;
	
	now = [NSDate date];
	today = dateForStartOfDay(now);
	
	initL10N(nil);
	
	Arguments args = {NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,NO,
					  nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil};
	PrettyPrintOptions prettyPrintOptions = getDefaultPrettyPrintOptions();
	
	// TODO: set up args
	
	NSArray *propertySeparators = nil;
	processArgs(&args, &prettyPrintOptions, &propertySeparators);
	initFormatting(nil, propertySeparators);
	initPrettyPrint(stdoutBuffer, prettyPrintOptions);
	*/
	
	
	NSUInteger totalNumTests = 0;
	NSUInteger totalNumSuccesses = 0;
	
	NSArray *allTests = getAllTests();
	for (UnitTest *test in allTests)
	{
		TestInfo *info = [test runTests];
		totalNumTests += info.numTests;
		totalNumSuccesses += info.numSuccesses;
	}
	
	Printf(@"\n");
	PRINTLN_Y(@"%i/%i tests succeeded.", totalNumSuccesses, totalNumTests);
	
	
	
	
	[autoReleasePool release];
	return(0);
}
