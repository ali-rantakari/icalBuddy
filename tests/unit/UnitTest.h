// icalBuddy unit test
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
#import "TestInfo.h"
#import "../../HGUtils.h"
#import "../../HGCLIUtils.h"


#define PRINTLN_R(...)	Printf(strConcat(@"\e[31m", [NSString stringWithFormat:__VA_ARGS__], @"\e[39m\n", nil))
#define PRINTLN_G(...)	Printf(strConcat(@"\e[32m", [NSString stringWithFormat:__VA_ARGS__], @"\e[39m\n", nil))
#define PRINTLN_Y(...)	Printf(strConcat(@"\e[33m", [NSString stringWithFormat:__VA_ARGS__], @"\e[39m\n", nil))
#define PRINTLN_B(...)	Printf(strConcat(@"\e[34m", [NSString stringWithFormat:__VA_ARGS__], @"\e[39m\n", nil))
#define PRINTLN_BOLD(...)	Printf(strConcat(@"\e[1m", [NSString stringWithFormat:__VA_ARGS__], @"\e[22m\n", nil))

#define HG_FAIL(t,m,b)				PRINTLN_R(strConcat((t), @": ", (m), nil), (b)); return [NSNumber numberWithBool:NO];
#define HG_ASSERT_EQUALS(a,b,m)		{if ((a) != (b)) { HG_FAIL(@"assert equals", m, b) }}
#define HG_ASSERT_OBJ_EQUALS(a,b,m)	{if (![(a) isEqual:(b)]) { HG_FAIL(@"assert obj equals", m, b) }}
//#define HG_ASSERT_NOT_NIL(a,m)
//#define HG_ASSERT_TRUE(a,m)
//#define HG_ASSERT_FALSE(a,m)
//#define HG_ASSERT_THROWS(a,m)
//#define HG_ASSERT_NO_THROW(a,m)
#define HG_UNITTEST_DONE			return [NSNumber numberWithBool:YES]


@interface UnitTest : NSObject
{
	
}

- (TestInfo *) runTests;


@end
