// icalBuddy localization functions
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


// localization configuration keys
#define kL10nKeyPropNameTitle		kPropName_title
#define kL10nKeyPropNameLocation	kPropName_location
#define kL10nKeyPropNameNotes		kPropName_notes
#define kL10nKeyPropNameUrl			kPropName_url
#define kL10nKeyPropNamePriority	kPropName_priority
#define kL10nKeyPropNameUID			kPropName_UID
#define kL10nKeyPropNameDueDate		@"dueDate"
#define kL10nKeyNoDueDate			@"noDueDate"
#define kL10nKeyToday				@"today"
#define kL10nKeyTomorrow			@"tomorrow"
#define kL10nKeyDayAfterTomorrow	@"dayAfterTomorrow"
#define kL10nKeyYesterday			@"yesterday"
#define kL10nKeyDayBeforeYesterday	@"dayBeforeYesterday"
#define kL10nKeyXDaysAgo			@"xDaysAgo"
#define kL10nKeyXDaysFromNow		@"xDaysFromNow"
#define kL10nKeyLastWeek			@"lastWeek"
#define kL10nKeyThisWeek			@"thisWeek"
#define kL10nKeyNextWeek			@"nextWeek"
#define kL10nKeyXWeeksAgo			@"xWeeksAgo"
#define kL10nKeyXWeeksFromNow		@"xWeeksFromNow"
#define kL10nKeyPriorityHigh 		@"high"
#define kL10nKeyPriorityMedium		@"medium"
#define kL10nKeyPriorityLow			@"low"
#define kL10nKeySomeonesBirthday	@"someonesBirthday"
#define kL10nKeyMyBirthday			@"myBirthday"
#define kL10nKeyDateTimeSeparator	@"dateTimeSeparator"
#define kL10nKeyNoItemsInSection	@"noItems"

// localization configuration file path
#define kL10nFilePath @"~/.icalBuddyLocalization.plist"

void initL10N(NSString *configFilePath);
void readAndValidateL10NConfigFile(NSString *filePath);

NSString* localizedStr(NSString *str);

