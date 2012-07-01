// ABRecord+HGAdditions.m
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

#import "ABRecord+HGAdditions.h"

@implementation ABRecord (HGAdditions)

- (NSInteger) hg_ageOnDate:(NSDate *)referenceDate
{
    NSDate *birthday = [self valueForProperty:kABBirthdayProperty];
    if (birthday == nil)
        return NSNotFound;

    NSCalendar *calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *dateComponentsRefDate = [calendar components:unitFlags fromDate:referenceDate];
    NSDateComponents *dateComponentsBirth = [calendar components:unitFlags fromDate:birthday];
    
    NSLog(@"Ref year: %i Birth year: %i", [dateComponentsRefDate year], [dateComponentsBirth year]);

    if (([dateComponentsRefDate month] < [dateComponentsBirth month])
        || (([dateComponentsRefDate month] == [dateComponentsBirth month])
            && ([dateComponentsRefDate day] < [dateComponentsBirth day])))
        return [dateComponentsRefDate year] - [dateComponentsBirth year] - 1;
    else
        return [dateComponentsRefDate year] - [dateComponentsBirth year];
}

- (NSInteger) hg_age
{
    return [self hg_ageOnDate:[NSDate date]];
}

- (NSString *) hg_fullName
{
    NSString *firstName = [self valueForProperty:kABFirstNameProperty];
    NSString *lastName = [self valueForProperty:kABLastNameProperty];
    NSString *orgName = [self valueForProperty:kABOrganizationProperty];

    NSInteger personFlags = [[self valueForProperty:kABPersonFlags] integerValue];
    //BOOL isPerson = (personFlags & kABShowAsMask) == kABShowAsPerson;
    BOOL isCompany = (personFlags & kABShowAsMask) == kABShowAsCompany;

    if (isCompany)
        return orgName;

    if (0 < firstName.length && 0 < lastName.length)
    {
        if ([[ABAddressBook sharedAddressBook] defaultNameOrdering] == kABFirstNameFirst)
            return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        else
            return [NSString stringWithFormat:@"%@ %@", lastName, firstName];
    }
    else if (0 < firstName.length)
        return firstName;
    else if (0 < lastName.length)
        return lastName;

    return nil;
}

@end
