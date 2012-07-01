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

#import "UnitTest.h"
#import <objc/runtime.h>


@implementation UnitTest

- (id) init
{
    if (!(self = [super init]))
        return nil;
    
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (NSString *) getClassName
{
    return [NSString stringWithUTF8String:class_getName([self class])];
}

- (NSArray *) getMethodNames
{
    NSMutableArray *methodsArr = [NSMutableArray array];
    
    unsigned int numMethods;
    Method *methods = class_copyMethodList([self class], &numMethods);
    for (unsigned i = 0; i < numMethods; i++)
        [methodsArr addObject:[NSString stringWithUTF8String:sel_getName(method_getName(methods[i]))]];
    free(methods);
    
    return methodsArr;
}

- (NSArray *) getTestMethodNames
{
    NSMutableArray *testMethods = [NSMutableArray array];
    
    NSArray *methodNames = [self getMethodNames];
    for (NSString *name in methodNames)
    {
        if ([name hasPrefix:@"test"])
            [testMethods addObject:name];
    }
    
    return testMethods;
}


- (TestInfo *) runTests
{
    TestInfo *testInfo = [[[TestInfo alloc] init] autorelease];
    
    SEL setUpSel = @selector(setUp);
    SEL tearDownSel = @selector(tearDown);
    
    PRINTLN_BOLD(@"------------------------------------------------");
    PRINTLN_BOLD(@"TEST CLASS: %@", [self getClassName]);
    
    if ([self respondsToSelector:setUpSel])
    {
        PRINTLN_B(@"• setUp");
        [self performSelector:setUpSel];
    }
    
    NSArray *testMethods = [self getTestMethodNames];
    for (NSString *name in testMethods)
    {
        PRINTLN_B(@"• Running test: %@", name);
        BOOL success = [[self performSelector:NSSelectorFromString(name)] boolValue];
        
        testInfo.numTests++;
        if (success)
        {
            testInfo.numSuccesses++;
            PRINTLN_G(@"+ TEST %@ OK.", name);
        }
        else
            PRINTLN_R(@"- TEST %@ FAILED.", name);
    }
    
    if ([self respondsToSelector:tearDownSel])
    {
        PRINTLN_B(@"• tearDown");
        [self performSelector:tearDownSel];
    }
    
    return testInfo;
}


@end
