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

#define ARR(...)        [NSArray arrayWithObjects:__VA_ARGS__, nil]
#define DATE(x)         [NSDate dateWithString:(x)]

#define RED(...)        strConcat(@"\e[31m", [NSString stringWithFormat:__VA_ARGS__], @"\e[39m", nil)
#define GREEN(...)      strConcat(@"\e[32m", [NSString stringWithFormat:__VA_ARGS__], @"\e[39m", nil)
#define YELLOW(...)     strConcat(@"\e[33m", [NSString stringWithFormat:__VA_ARGS__], @"\e[39m", nil)
#define BLUE(...)       strConcat(@"\e[34m", [NSString stringWithFormat:__VA_ARGS__], @"\e[39m", nil)
#define MAGENTA(...)    strConcat(@"\e[35m", [NSString stringWithFormat:__VA_ARGS__], @"\e[39m", nil)
#define CYAN(...)       strConcat(@"\e[36m", [NSString stringWithFormat:__VA_ARGS__], @"\e[39m", nil)
#define BOLD(...)       strConcat(@"\e[1m", [NSString stringWithFormat:__VA_ARGS__], @"\e[22m", nil)

#define PRINTLN_R(...)  Printf(strConcat(RED(__VA_ARGS__), @"\n", nil))
#define PRINTLN_G(...)  Printf(strConcat(GREEN(__VA_ARGS__), @"\n", nil))
#define PRINTLN_Y(...)  Printf(strConcat(YELLOW(__VA_ARGS__), @"\n", nil))
#define PRINTLN_B(...)  Printf(strConcat(BLUE(__VA_ARGS__), @"\n", nil))
#define PRINTLN_BOLD(...)   Printf(strConcat(BOLD(__VA_ARGS__), @"\n", nil))

#define HG_FAIL(t,m)        Printf(\
                                strConcat(\
                                    @"\e[31m- ", (t), @":\e[39m ",\
                                    (m),\
                                    RED(@" [%s:%u]", __FILE__, __LINE__),\
                                    @"\n", nil\
                                    )\
                                );\
                            return [NSNumber numberWithBool:NO];

#define HG_FAIL_AB(t,m,a,b)     Printf(\
                                    strConcat(\
                                        @"\e[31m- ", (t), @":\e[39m ",\
                                        [NSString stringWithFormat:(m), #a, (b), (a)],\
                                        RED(@" [%s:%u]", __FILE__, __LINE__),\
                                        @"\n", nil\
                                        )\
                                    );\
                                return [NSNumber numberWithBool:NO];

#define HG_ASSERT_EQUALS(a,b)       {if ((a) != (b)) { HG_FAIL_AB(@"assert equals", @"\e[36m%s\e[39m should be \e[35m%d\e[39m but was \e[33m%d\e[39m instead", a, b) }}
#define HG_ASSERT_OBJ_EQUALS(a,b)   {if (![(a) isEqual:(b)]) { HG_FAIL_AB(@"assert obj equals", @"\e[36m%s\e[39m should be \e[35m%@\e[39m but was \e[33m%@\e[39m instead", a, b) }}
#define HG_ASSERT_NOT_NIL(a)        {if ((a) == nil) { HG_FAIL(@"assert not nil", @"") }}
#define HG_ASSERT_TRUE(a)           {if (!(a)) { HG_FAIL(@"assert true", @"") }}
#define HG_ASSERT_FALSE(a)          {if (a) { HG_FAIL(@"assert false", @"") }}
//#define HG_ASSERT_THROWS(a,m)
//#define HG_ASSERT_NO_THROW(a,m)
#define HG_TEST_DONE            return [NSNumber numberWithBool:YES]
#define HG_TEST_RETURN_TYPE     NSNumber *


@interface UnitTest : NSObject
{
    
}

- (TestInfo *) runTests;


@end
