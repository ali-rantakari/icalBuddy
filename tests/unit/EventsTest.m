// icalBuddy events test
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

#import "EventsTest.h"

@implementation EventsTest

- (void) setUp
{
    CalCalendar *homeCal = newCalendar(@"Home", [NSColor greenColor]);
    CalCalendar *workCal = newCalendar(@"Work", [NSColor blueColor]);
    [CALENDAR_STORE defaultCalendarStore].calendarsArr = [NSMutableArray arrayWithObjects:
        homeCal, workCal,
        nil
        ];
    
    [CALENDAR_STORE defaultCalendarStore].itemsArr = [NSMutableArray arrayWithObjects:
        newAllDayEvent(homeCal, @"Off from work", nil, @"2010-10-22", @"2010-10-23", nil, nil),
        newEvent(homeCal, @"Feed the cat", @"apartment", @"2010-10-21 15", @"2010-10-21 15", nil, nil),
        newEvent(homeCal, @"Watch the game", @"apartment", @"2010-10-22 16", @"2010-10-22 17", nil, nil),
        nil
        ];
}

- (HG_TEST_RETURN_TYPE) testEventsNow
{
    AppOptions opts = [self
        setUpWithNowDate:DATE(@"2010-10-22 16:30:00 +0200")
        opts:ARR(@"-sd", @"eventsNow")
        ];
    
    NSArray *items = getCalItems(&opts);
    
    HG_ASSERT_EQUALS([items count], 2);
    HG_ASSERT_OBJ_EQUALS([[items objectAtIndex:0] title], @"Off from work");
    HG_ASSERT_OBJ_EQUALS([[items objectAtIndex:1] title], @"Watch the game");
    
    HG_TEST_DONE;
}

- (void) tearDown
{
    [CALENDAR_STORE defaultCalendarStore].calendarsArr = nil;
    [CALENDAR_STORE defaultCalendarStore].itemsArr = nil;
}

@end
