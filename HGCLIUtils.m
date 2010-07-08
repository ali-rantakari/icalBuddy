// CLI app utils
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

#import "HGCLIUtils.h"


// the string encoding to use for output
NSStringEncoding outputStrEncoding = NSUTF8StringEncoding; // default

BOOL debugPrintEnabled = NO;



// helper methods for printing to stdout and stderr
// 		from: http://www.sveinbjorn.org/objectivec_stdout
// 		(modified to use non-deprecated version of writeToFile:...
//       and allow for using the "string format" syntax)



void Print(NSString *aStr)
{
	[aStr writeToFile:@"/dev/stdout" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}

// other Printf functions call this, and you call them
void RealPrintf(NSString *aStr, NSString *aFile, va_list args)
{
	NSString *str = [
		[[NSString alloc]
			initWithFormat:aStr
			locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]
			arguments:args
			] autorelease
		];
	
	[str writeToFile:aFile atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}

void Printf(NSString *aStr, ...)
{
	va_list argList;
	va_start(argList, aStr);
	RealPrintf(aStr, @"/dev/stdout", argList);
	va_end(argList);
}

void PrintfErr(NSString *aStr, ...)
{
	va_list argList;
	va_start(argList, aStr);
	RealPrintf(aStr, @"/dev/stderr", argList);
	va_end(argList);
}

void DebugPrintf(NSString *aStr, ...)
{
	if (!debugPrintEnabled)
		return;
	
	NSString *str = strConcat(@"icalBuddy: ", aStr, nil);
	
	va_list argList;
	va_start(argList, aStr);
	RealPrintf(str, @"/dev/stderr", argList);
	va_end(argList);
}




#define UNICHAR_NEWLINE 10
#define UNICHAR_TAB 9
#define UNICHAR_SPACE 32
#define TAB_STOP_LENGTH 4

void wordWrapMutableAttrStr(NSMutableAttributedString *mutableAttrStr, NSUInteger width)
{
	// replace tabs with spaces to avoid problems with different programs
	// (that would display our output) using different tab stop lengths:
	replaceInMutableAttrStr(mutableAttrStr, @"\t", ATTR_STR(WHITESPACE(TAB_STOP_LENGTH)));
	
	NSString *str = [[mutableAttrStr string] copy];
	
	NSAttributedString *newlineAttrStr = ATTR_STR(@"\n");
	
	// characters we'll consider as indentation:
	NSCharacterSet *indentChars = [NSCharacterSet characterSetWithCharactersInString:@" •"];
	
	// find all input string indices where we want to
	// wrap the line
	NSUInteger strLength = [str length];
	NSUInteger strIndex = 0;
	NSUInteger currentLineLength = 0;
	NSUInteger lastWhitespaceIndex = 0;
	unichar currentUnichar = 0;
	BOOL lastCharWasWhitespace = NO;
	BOOL lastCharWasIndentation = NO;
	NSUInteger numAddedChars = 0;
	NSUInteger currentLineIndentAmount = 0;
	while(strIndex < strLength)
	{
		if (width <= currentLineLength)
		{
			// insert newline at the wrap index, eating one whitespace
			// *if* we're wrapping at a whitespace (i.e. don't eat characters
			// if we've been forced to wrap in the middle of a word)
			
			NSUInteger indexToWrapAt = ((0 < lastWhitespaceIndex) ? lastWhitespaceIndex : strIndex) + numAddedChars;
			NSUInteger lengthToReplace = ((lastWhitespaceIndex != 0)?1:0);
			NSRange replaceRange = NSMakeRange(indexToWrapAt, lengthToReplace);
			
			NSAttributedString *replaceStr = nil;
			if (currentLineIndentAmount == 0)
				replaceStr = newlineAttrStr;
			else
				replaceStr = ATTR_STR(strConcat(@"\n", WHITESPACE(currentLineIndentAmount), nil));
			
			[mutableAttrStr
				replaceCharactersInRange:replaceRange
				withAttributedString:replaceStr
				];
			
			numAddedChars += [replaceStr length] - lengthToReplace;
			
			lastWhitespaceIndex = 0;
			currentLineLength = (strIndex-(indexToWrapAt-numAddedChars));
		}
		else
		{
			currentUnichar = [str characterAtIndex:strIndex];
			
			if ((lastCharWasIndentation || currentLineLength == 0) &&
				[indentChars characterIsMember:currentUnichar]
				)
			{
				lastCharWasIndentation = YES;
				currentLineIndentAmount++;
			}
			else
				lastCharWasIndentation = NO;
			
			if (currentUnichar == UNICHAR_NEWLINE)
			{
				lastWhitespaceIndex = 0;
				currentLineLength = 0;
				currentLineIndentAmount = 0;
			}
			// we want to wrap at the beginning of the last
			// whitespace run of the current line, excluding the
			// beginning of the line (doesn't make sense to wrap
			// there):
			else if (!lastCharWasWhitespace &&
					 0 < currentLineLength &&
					 currentUnichar == UNICHAR_SPACE
					 )
			{
				lastWhitespaceIndex = strIndex;
				currentLineLength++;
			}
			else
			{
				currentLineLength++;
			}
			
			lastCharWasWhitespace = (currentUnichar == UNICHAR_SPACE);
		}
		
		strIndex++;
	}
	
	[str release];
}




