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

#import <Foundation/Foundation.h>
#import "HGCLIUtils.h"
#import "icalBuddyL10N.h"
#import "icalBuddyDefines.h"


// dictionary for localization values
NSDictionary *L10nStringsDict;

// default version of L10nStringsDict
NSDictionary *defaultStringsDict;


// returns localized, human-readable string corresponding to the
// specified localization dictionary key
NSString* localizedStr(NSString *str)
{
	if (str == nil)
		return nil;
	
	if (L10nStringsDict != nil)
	{
		NSString *localizedStr = [L10nStringsDict objectForKey:str];
		if (localizedStr != nil)
			return localizedStr;
	}
	
	NSString *defaultStr = [defaultStringsDict objectForKey:str];
	NSCAssert((defaultStr != nil), @"defaultStr is nil");
	return defaultStr;
}


void initL10N(NSString *configFilePath)
{
	defaultStringsDict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"title",			kL10nKeyPropNameTitle,
		@"location",		kL10nKeyPropNameLocation,
		@"notes", 			kL10nKeyPropNameNotes,
		@"url", 			kL10nKeyPropNameUrl,
		@"uid",				kL10nKeyPropNameUID,
		@"due",		 		kL10nKeyPropNameDueDate,
		@"no due date",		kL10nKeyNoDueDate,
		@"priority", 		kL10nKeyPropNamePriority,
		@"%@'s Birthday (age %i)",	kL10nKeySomeonesBirthday,
		@"My Birthday",				kL10nKeyMyBirthday,
		@"today", 					kL10nKeyToday,
		@"tomorrow", 				kL10nKeyTomorrow,
		@"yesterday", 				kL10nKeyYesterday,
		@"day before yesterday",	kL10nKeyDayBeforeYesterday,
		@"day after tomorrow",		kL10nKeyDayAfterTomorrow,
		@"%d days ago",				kL10nKeyXDaysAgo,
		@"%d days from now",		kL10nKeyXDaysFromNow,
		@"this week",				kL10nKeyThisWeek,
		@"last week",				kL10nKeyLastWeek,
		@"next week",				kL10nKeyNextWeek,
		@"%d weeks ago",			kL10nKeyXWeeksAgo,
		@"%d weeks from now",		kL10nKeyXWeeksFromNow,
		@"high",		 kL10nKeyPriorityHigh,
		@"medium",		 kL10nKeyPriorityMedium,
		@"low",			 kL10nKeyPriorityLow,
		@"none",		 kL10nKeyPriorityNone,
		@"%@ priority",  kL10nKeyPriorityTitle,
		@"No priority",  kL10nKeyPriorityTitleNone,
		@" at ",		 kL10nKeyDateTimeSeparator,
		@"Nothing.",	 kL10nKeyNoItemsInSection,
		nil
		];
	readAndValidateL10NConfigFile(configFilePath);
}

void readAndValidateL10NConfigFile(NSString *filePath)
{
	L10nStringsDict = nil;
	
	if (filePath == nil)
		filePath = kL10nFilePath;
	
	filePath = [filePath stringByExpandingTildeInPath];
	
	BOOL L10nFileIsDir;
	BOOL L10nFileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&L10nFileIsDir];
	if (L10nFileExists && !L10nFileIsDir)
	{
		BOOL L10nFileIsValid = YES;
		
		L10nStringsDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
		
		if (L10nStringsDict == nil)
		{
			PrintfErr(@"* Error in localization file \"%@\":\n", filePath);
			PrintfErr(@"  can not recognize file format -- must be a valid property list\n");
			PrintfErr(@"  with a structure specified in the icalBuddyLocalization man page.\n");
			L10nFileIsValid = NO;
		}
		
		if (L10nFileIsValid)
		{
			// validate some specific keys in localization config
			NSDictionary *L10nKeysRequiringSubstrings = [NSDictionary dictionaryWithObjectsAndKeys:
				@"%d", kL10nKeyXWeeksFromNow,
				@"%d", kL10nKeyXWeeksAgo,
				@"%d", kL10nKeyXDaysAgo,
				@"%d", kL10nKeyXDaysFromNow,
				@"%@", kL10nKeySomeonesBirthday,
				nil
				];
			NSString *thisKey;
			NSString *thisVal;
			NSString *requiredSubstring;
			for (thisKey in [L10nKeysRequiringSubstrings allKeys])
			{
				requiredSubstring = [L10nKeysRequiringSubstrings objectForKey:thisKey];
				thisVal = [L10nStringsDict objectForKey:thisKey];
				if (thisVal != nil && [thisVal rangeOfString:requiredSubstring].location == NSNotFound)
				{
					PrintfErr(@"* Error in localization file \"%@\"\n", filePath);
					PrintfErr(@"  (key: \"%@\", value: \"%@\"):\n", thisKey, thisVal);
					PrintfErr(@"  value must include %@ to indicate position for a variable.\n", requiredSubstring);
					L10nFileIsValid = NO;
				}
			}
		}
		
		if (!L10nFileIsValid)
		{
			PrintfErr(@"\nTry running \"man icalBuddyLocalization\" to read the relevant documentation\n");
			PrintfErr(@"and \"plutil '%@'\" to validate the\nfile's property list syntax.\n\n", filePath);
			L10nStringsDict = nil;
		}
	}
}



