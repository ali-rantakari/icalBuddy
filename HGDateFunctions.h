
#import <Foundation/Foundation.h>




NSCalendarDate *dateForStartOfDay(NSCalendarDate *date);

NSCalendarDate *dateByAddingDays(NSCalendarDate *date, NSInteger days);

BOOL datesRepresentSameDay(NSCalendarDate *date1, NSCalendarDate *date2);

NSInteger getNumWeeksInYear(NSInteger year);

NSInteger getWeekDiff(NSDate *date1, NSDate *date2);
NSInteger getDayDiff(NSDate *date1, NSDate *date2);

NSDate *dateFromUserInput(NSString *input, NSString *inputName);
NSCalendarDate *calDateFromUserInput(NSString *input, NSString *inputName);
void printDateFormatInfo();


