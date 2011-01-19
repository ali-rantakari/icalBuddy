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

#ifndef USE_MOCKED_CALENDARSTORE
	#define USE_MOCKED_CALENDARSTORE
#endif

#import <Foundation/Foundation.h>

#import "tests/unit/UnitTest.h"
#import "tests/unit/allTests.h"



int main(int argc, char *argv[])
{
	NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
	
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
