// Misc utility functions
// 
// http://hasseg.org/
//

/*
The MIT License

Copyright (c) 2010 Ali Rantakari

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

#import "HGUtils.h"



NSError *hgInternalError(NSInteger code, NSString *description)
{
	return [NSError
		errorWithDomain:kHGInternalErrorDomain
		code:code
		userInfo:[NSDictionary
			dictionaryWithObject:description
			forKey:NSLocalizedDescriptionKey
			]
		];
}


// convenience function: concatenates strings (yes, I hate the
// verbosity of -stringByAppendingString:.)
// NOTE: MUST SEND nil AS THE LAST ARGUMENT
NSString *strConcat(NSString *firstStr, ...)
{
	if (!firstStr)
		return nil;
	
	va_list argList;
	NSMutableString *retVal = [firstStr mutableCopy];
	NSString *str;
	va_start(argList, firstStr);
	while((str = va_arg(argList, NSString*)))
		[retVal appendString:str];
	va_end(argList);
	return retVal;
}

NSString *escapeDoubleQuotes(NSString *str)
{
	return [str stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
}

NSString *translateEscapeSequences(NSString *str)
{
	if (str == nil)
		return nil;
	
	NSMutableString *ms = [NSMutableString stringWithString:str];
	[ms replaceOccurrencesOfString:@"\\n" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0,[ms length])];
	[ms replaceOccurrencesOfString:@"\\t" withString:@"\t" options:NSLiteralSearch range:NSMakeRange(0,[ms length])];
	[ms replaceOccurrencesOfString:@"\\e" withString:@"\e" options:NSLiteralSearch range:NSMakeRange(0,[ms length])];
	return ms;
}


NSMutableAttributedString *mutableAttrStrWithAttrs(NSString *string, NSDictionary *attrs)
{
	return [[[NSMutableAttributedString alloc] initWithString:string attributes:attrs] autorelease];
}

// replaces all occurrences of searchStr in str with replaceStr
void replaceInMutableAttrStr(NSMutableAttributedString *str, NSString *searchStr, NSAttributedString *replaceStr)
{
	if (str == nil || searchStr == nil || replaceStr == nil)
		return;
	
	NSUInteger replaceStrLength = [replaceStr length];
	NSString *strRegularString = [str string];
	NSRange searchRange = NSMakeRange(0, [strRegularString length]);
	NSRange foundRange;
	do
	{
		foundRange = [strRegularString rangeOfString:searchStr options:NSLiteralSearch range:searchRange];
		if (foundRange.location != NSNotFound)
		{
			[str replaceCharactersInRange:foundRange withAttributedString:replaceStr];
			
			strRegularString = [str string];
			searchRange.location = foundRange.location + replaceStrLength;
			searchRange.length = [strRegularString length] - searchRange.location;
		}
	}
	while (foundRange.location != NSNotFound);
}




// create an NSSet from a comma-separated string,
// trimming whitespace from around each string component
NSSet *setFromCommaSeparatedStringTrimmingWhitespace(NSString *str)
{
	if (str != nil)
	{
		NSMutableSet *set = [NSMutableSet setWithCapacity:10];
		NSArray *arr = [str componentsSeparatedByString:@","];
		NSString *component;
		for (component in arr)
			[set addObject:[component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
		return set;
	}
	return [NSSet set];
}


// create an NSArray from a comma-separated string,
// trimming whitespace from around each string component
NSArray *arrayFromCommaSeparatedStringTrimmingWhitespace(NSString *str)
{
	if (str != nil)
	{
		NSMutableArray *retArr = [NSMutableArray arrayWithCapacity:10];
		NSArray *arr = [str componentsSeparatedByString:@","];
		NSString *component;
		for (component in arr)
			[retArr addObject:[component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
		return retArr;
	}
	return [NSArray array];
}


// create an NSArray from a string where components are
// separated by an arbitrary character and this separator character
// must be present as both the first and the last character
// in the given string (e.g.: @"/first/second/third/")
NSArray *arrayFromArbitrarilySeparatedString(NSString *str, BOOL aTranslateEscapeSequences, NSError **error)
{
	if (str == nil)
	{
		if (error != NULL)
			*error = hgInternalError(0, @"Given string is null");
		return nil;
	}
	if ([str length] < 2)
	{
		if (error != NULL)
			*error = hgInternalError(0, @"Given string has less than two characters");
		return nil;
	}
	
	NSString *separatorChar = nil;
	
	NSString *firstChar = [str substringToIndex:1];
	NSString *lastChar = [str substringFromIndex:[str length]-1];
	if ([firstChar isEqualToString:lastChar])
		separatorChar = firstChar;
	else
	{
		if (error != NULL)
			*error = hgInternalError(0, @"Given string must start and end with the separator character");
		return nil;
	}
	
	if (separatorChar != nil)
	{
		NSString *trimmedStr = [str substringWithRange:NSMakeRange(1,([str length]-2))];
		if (aTranslateEscapeSequences)
			trimmedStr = translateEscapeSequences(trimmedStr);
		return [trimmedStr componentsSeparatedByString:separatorChar];
	}
	
	return [NSArray array];
}



NSUInteger countOccurrences(NSString *haystack, NSString *needle, NSStringCompareOptions options)
{
	NSInteger count = -1;
	
	NSRange searchRange = NSMakeRange(0, [haystack length]);
	NSRange result;
	do
	{
		count++;
		result = [haystack rangeOfString:needle options:options range:searchRange];
		if (result.location != NSNotFound)
		{
			searchRange.location = NSMaxRange(result);
			searchRange.length = [haystack length] - searchRange.location;
		}
	}
	while (result.location != NSNotFound);
	
	return count;
}



// returns YES if success, NO if failure
BOOL moveFileToTrash(NSString *filePath)
{
	if (filePath == nil)
		return NO;
	
	NSString *fileDir = [filePath stringByDeletingLastPathComponent];
	NSString *fileName = [filePath lastPathComponent];
	
	return [[NSWorkspace sharedWorkspace]
		performFileOperation:NSWorkspaceRecycleOperation
		source:fileDir
		destination:@""
		files:[NSArray arrayWithObject:fileName]
		tag:nil
		];
}


