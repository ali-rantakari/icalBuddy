// icalBuddy definitions
// 
// http://hasseg.org/icalBuddy
//

/*
The MIT License

Copyright (c) 2008-2010 Ali Rantakari

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

#define kInternalErrorDomain @"org.hasseg.icalBuddy"

#define kPropertyListEditorAppName @"Property List Editor"

// custom date-formatting specifiers
#define kRelativeWeekFormatSpecifier @"%RW"
#define kDayDiffFormatSpecifier @"%RD"


// property names
#define kPropName_title 	@"title"
#define kPropName_location 	@"location"
#define kPropName_notes 	@"notes"
#define kPropName_url 		@"url"
#define kPropName_datetime 	@"datetime"
#define kPropName_priority 	@"priority"
#define kPropName_UID		@"uid"


// keys for the "sections" dictionary (see printItemSections())
#define kSectionDictKey_title 				@"sectionTitle"
#define kSectionDictKey_items 				@"sectionItems"
#define kSectionDictKey_eventsContextDay 	@"eventsContextDay"


// output formatting configuration keys
#define kFormatKeySectionTitle			@"sectionTitle"
#define kFormatKeyFirstItemLine			@"firstItemLine"
#define kFormatKeyBullet				@"bullet"
#define kFormatKeyAlertBullet			@"alertBullet"
#define kFormatKeyNoItems				@"noItems"
#define kFormatKeyCalendarNameInTitle	@"calendarNameInTitle"
#define kFormatKeyPriorityValueHigh		@"priorityValueHigh"
#define kFormatKeyPriorityValueMedium	@"priorityValueMedium"
#define kFormatKeyPriorityValueLow		@"priorityValueLow"
// the "suffix" definitions below are used like:
//   kPropName_notes + kFormatKeyPropNameSuffix
//   ^-- defines the formatting config key for the
//       "notes" property name
#define kFormatKeyPropNameSuffix		@"Name"
#define kFormatKeyPropValueSuffix		@"Value"


// output formatting parameters
#define kFormatFgColorPrefix		@"fg:"
#define kFormatBgColorPrefix		@"bg:"
#define kFormatDoubleUnderlined		@"double-underlined"
#define kFormatUnderlined			@"underlined"
#define kFormatBold					@"bold"
#define kFormatBlink				@"blink"
#define kFormatColorBlack			@"black"
#define kFormatColorRed				@"red"
#define kFormatColorGreen			@"green"
#define kFormatColorYellow			@"yellow"
#define kFormatColorBlue			@"blue"
#define kFormatColorMagenta			@"magenta"
#define kFormatColorWhite			@"white"
#define kFormatColorCyan			@"cyan"
#define kFormatColorBrightBlack		@"bright-black"
#define kFormatColorBrightRed		@"bright-red"
#define kFormatColorBrightGreen		@"bright-green"
#define kFormatColorBrightYellow	@"bright-yellow"
#define kFormatColorBrightBlue		@"bright-blue"
#define kFormatColorBrightMagenta	@"bright-magenta"
#define kFormatColorBrightWhite		@"bright-white"
#define kFormatColorBrightCyan		@"bright-cyan"

// custom string formatting attribute(s)
#define kBlinkAttributeName			@"blinkAttributeName"
#define kSGRCodeBlink				5
#define kSGRCodeBlinkReset			25



// default item property order + list of allowed property names (i.e. these must be in
// the default order and include all of the allowed property names)
#define kDefaultPropertyOrder [NSArray arrayWithObjects:kPropName_title, kPropName_location, kPropName_notes, kPropName_url, kPropName_datetime, kPropName_priority, kPropName_UID, nil]

#define kDefaultPropertySeparators [NSArray arrayWithObjects:@"\n    ", nil]

// general configuration file path
#define kConfigFilePath @"~/.icalBuddyConfig.plist"

// contents for a new configuration file "stub"
#define kConfigFileStub [NSDictionary dictionaryWithObjectsAndKeys:\
						 [NSDictionary dictionary], @"formatting",\
						 nil\
						]

// variables for arguments
typedef struct
{
	BOOL separateByCalendar;
	BOOL separateByDate;
	BOOL updatesCheck;
	BOOL printVersion;
	BOOL includeOnlyEventsFromNowOn;
	BOOL useFormatting;
	BOOL noCalendarNames;
	BOOL sortTasksByDueDate;
	BOOL sortTasksByDueDateAscending;
	BOOL sectionsForEachDayInSpan;
	BOOL noPropNames;
	
	BOOL output_is_uncompletedTasks;
	BOOL output_is_eventsToday;
	BOOL output_is_eventsNow;
	BOOL output_is_eventsFromTo;
	BOOL output_is_tasksDueBefore;
	
	NSString *output;
	NSArray *includeCals;
	NSArray *excludeCals;
	NSString *strEncoding;
	NSString *propertyOrderStr;
	NSString *propertySeparatorsStr;
	NSString *eventsFrom;
	NSString *eventsTo;
	
	NSDate *startDate;
	NSDate *endDate;
	NSDate *dueBeforeDate;
} Arguments;


