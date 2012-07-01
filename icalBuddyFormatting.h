// icalBuddy output formatting functions
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
#import <AppKit/AppKit.h>
#import <CalendarStore/CalendarStore.h>

void initFormatting(NSDictionary *aFormattingConfigDict, NSArray *aPropertySeparators);

NSColor *getClosestAnsiColorForColor(NSColor *color, BOOL foreground);

NSMutableDictionary* formattingConfigToStringAttributes(NSString *formattingConfig, CalCalendarItem *calItem);

void processCustomStringAttributes(NSMutableAttributedString **aAttributedString);

NSDictionary* getStringAttributesForKey(NSString *key, CalCalendarItem *calItem);

NSDictionary* getSectionTitleStringAttributes(NSString *sectionTitle);
NSDictionary* getFirstLineStringAttributes(CalCalendarItem *calItem);
NSDictionary* getBulletStringAttributes(BOOL isAlertBullet, CalCalendarItem *calItem);
NSDictionary* getCalNameInTitleStringAttributes(CalCalendarItem *calItem);
NSDictionary* getPropNameStringAttributes(NSString *propName, CalCalendarItem *calItem);
NSDictionary* getPropValueStringAttributes(NSString *propName, NSString *propValue, CalCalendarItem *calItem);

NSString* getPropSeparatorStr(NSUInteger propertyNumber);

NSString *ansiEscapedStringWithAttributedString(NSAttributedString *str);

