// icalBuddy mocked CalendarStore helper functions
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

#import "mockHelperFunctions.h"


NSDate *dateFromStr(NSString *str)
{
    NSString *dateStr = nil;
    if ([str length] == 25)
        dateStr = str;
    else if ([str length] == 19)
        dateStr = strConcat(str, @" +0200", nil);
    else if ([str length] == 16)
        dateStr = strConcat(str, @":00 +0200", nil);
    else if ([str length] == 13)
        dateStr = strConcat(str, @":00:00 +0200", nil);
    else if ([str length] == 10)
        dateStr = strConcat(str, @" 12:00:00 +0200", nil);
    return [NSDate dateWithString:dateStr];
}

CalCalendar *newCalendar(NSString *title, NSColor *color)
{
    CalCalendar *cal = [CalCalendar calendar];
    cal.title = title;
    cal.color = color;
    return cal;
}

CalEvent *newEvent(CalCalendar *calendar,
    NSString *title, NSString *location,
    NSString *start, NSString *end,
    NSString *notes, NSURL *url
    )
{
    CalEvent *event = [CalEvent event];
    event.calendar = calendar;
    event.title = title;
    event.location = location;
    event.isAllDay = NO;
    event.startDate = dateFromStr(start);
    event.endDate = dateFromStr(end);
    event.notes = notes;
    event.url = url;
    return event;
}

CalEvent *newAllDayEvent(CalCalendar *calendar,
    NSString *title, NSString *location,
    NSString *start, NSString *end,
    NSString *notes, NSURL *url
    )
{
    CalEvent *event = [CalEvent event];
    event.calendar = calendar;
    event.title = title;
    event.location = location;
    event.isAllDay = YES;
    event.startDate = dateFromStr(start);
    event.endDate = dateByAddingDays(dateFromStr(end), 1);
    event.notes = notes;
    event.url = url;
    return event;
}


