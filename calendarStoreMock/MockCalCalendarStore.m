// icalBuddy mocked CalendarStore
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

#import "MockCalCalendarStore.h"
#import "../HGUtils.h"
#import "../HGDateFunctions.h"



@implementation MockCalCalendarStore

@synthesize calendarsArr;
@synthesize itemsArr;

- (id) init
{
	if (!(self = [super init]))
		return nil;
	
	self.calendarsArr = [NSMutableArray array];
	self.itemsArr = [NSMutableArray array];
	
	return self;
}

- (void) dealloc
{
	self.calendarsArr = nil;
	self.itemsArr = nil;
	[super dealloc];
}





//  An array of all the user's calendars, represented as CalCalendars. If the user has iCal data from a previous
//  version of Mac OS X, but has not launched iCal in 10.5, this will return an array of empty calendars. iCal needs
//  to be launched at least once in order to migrate the user's calendar data.
//
//  If no calendar data from any version of Mac OS X exists, then this method will create and return two default
//  calendars, named Home and Work.
- (NSArray *)calendars
{
	return self.calendarsArr;
}


//  The calendar associated with the specific UID. If no record with this UID exists, nil is returned.
- (CalCalendar *)calendarWithUID:(NSString *)UID
{
	// not implemented
	return nil;
}


- (BOOL)saveCalendar:(CalCalendar *)calendar error:(NSError **)error
{
	// not implemented
	return NO;
}
- (BOOL)removeCalendar:(CalCalendar *)calendar error:(NSError **)error
{
	// not implemented
	return NO;
}


//  - (NSArray *)eventsWithPredicate:(NSPredicate *)predicate;
//
//  This method returns an array of all the CalEvents which match the conditions described in the predicate that is 
//  passed. At this time, eventsWithPredicate: only suppports predicates generated with one of the class methods added 
//  to NSPredicate below.
//  
//  If the predicate passed to eventsWithPredicate: was not created with one of the class methods included in this file, 
//  nil is returned. If nil is passed as the predicate, an exception will be raised.
//
//  For performance reasons, this method will only return occurrences of repeating events that fall within a specific 
//  four year timespan. If the date range between the startDate and endDate is greater than four years, then the 
//  timespan containing recurrences is always the first four years of date range.
- (NSArray *)eventsWithPredicate:(NSPredicate *)predicate
{
	NSMutableArray *arr = [NSMutableArray array];
	
	for (CalCalendarItem *item in self.itemsArr)
	{
		if (![item isKindOfClass:[CalEvent class]])
			continue;
		CalEvent *event = (CalEvent *)item;
		if ([predicate evaluateWithObject:event])
			[arr addObject:event];
	}
	
	return arr;
}

- (CalEvent *)eventWithUID:(NSString *)uid occurrence:(NSDate *)date
{
	// not implemented
	return nil;
}


//  - (NSArray *)tasksWithPredicate:(NSPredicate *)predicate;
//
//  This method returns an array of all the CalTasks which match the conditions described in the predicate that is 
//  passed. At this time, tasksWithPredicate: only suppports predicates generated with one of the class methods added to 
//  NSPredicate below.
//
//  If the predicate passed to tasksWithPredicate: was not created with one of the class methods included in thsi file, 
//  nil is returned. If nil is passed as the predicate, an exception will be raised.
- (NSArray *)tasksWithPredicate:(NSPredicate *)predicate
{
	NSMutableArray *arr = [NSMutableArray array];
	
	for (CalCalendarItem *item in self.itemsArr)
	{
		if (![item isKindOfClass:[CalTask class]])
			continue;
		CalTask *task = (CalTask *)item;
		if ([predicate evaluateWithObject:task])
			[arr addObject:task];
	}
	
	return arr;
}

- (CalTask *)taskWithUID:(NSString *)uid
{
	// not implemented
	return nil;
}


- (BOOL)saveEvent:(CalEvent *)event span:(CalSpan)span error:(NSError **)error
{
	// not implemented
	return NO;
}
- (BOOL)removeEvent:(CalEvent *)event span:(CalSpan)span error:(NSError **)error
{
	// not implemented
	return NO;
}


- (BOOL)saveTask:(CalTask *)task error:(NSError **)error
{
	// not implemented
	return NO;
}
- (BOOL)removeTask:(CalTask *)task error:(NSError **)error
{
	// not implemented
	return NO;
}


//  A predicate passed to eventsWithPredicate: or tasksWithPredicate: must be returned from one of these methods.

+ (NSPredicate *)eventPredicateWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate calendars:(NSArray *)calendars
{
	NSPredicate *pred = [NSPredicate
		predicateWithFormat:
			@"calendar IN %@ AND (endDate >= %@ AND startDate <= %@)",
			calendars, startDate, endDate
		];
	return pred;
}

+ (NSPredicate *)taskPredicateWithUncompletedTasks:(NSArray *)calendars
{
	// TODO
	return nil;
}

+ (NSPredicate *)taskPredicateWithUncompletedTasksDueBefore:(NSDate *)dueDate calendars:(NSArray *)calendars
{
	// TODO
	return nil;
}

+ (NSPredicate *)eventPredicateWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate UID:(NSString *)UID calendars:(NSArray *)calendars
{
	// not implemented
	return nil;
}

+ (NSPredicate *)taskPredicateWithCalendars:(NSArray *)calendars //  This will return all tasks, completed and uncompleted, for a set of calendars
{
	// not implemented
	return nil;
}

+ (NSPredicate *)taskPredicateWithTasksCompletedSince:(NSDate *)completedSince calendars:(NSArray *)calendars
{
	// not implemented
	return nil;
}




// ----------- singleton implementation:


static MockCalCalendarStore *sharedInstance = NULL;

//  Returns an instance of the calendar store.
+ (MockCalCalendarStore *) defaultCalendarStore
{
    @synchronized(self)
    {
        if (sharedInstance == nil)
			sharedInstance = [[MockCalCalendarStore alloc] init];
    }
    return sharedInstance;
}

+ (id) allocWithZone:(NSZone *)zone
{
    @synchronized(self)
	{
        if (sharedInstance == nil)
		{
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id) copyWithZone:(NSZone *)zone
{
    return self;
}

- (id) retain
{
    return self;
}

- (NSUInteger) retainCount
{
    return UINT_MAX;  // denotes an object that cannot be released
}

- (void) release
{
    //do nothing
}

- (id) autorelease
{
    return self;
}





@end












