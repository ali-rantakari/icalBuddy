// icalBuddy test unit test
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

#import "TestTest.h"
#import "../../HGCLIUtils.h"


@implementation TestTest

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

- (void) setUp
{
	
}

- (HG_TEST_RETURN_TYPE) testEventsNow
{
	Arguments args = [self
		setUpWithNowDate:DATE(@"2010-10-22 16:30:00 +0200")
		args:ARR(@"-sd", @"eventsNow")
		];
	
	NSArray *items = getCalItems(&args);
	
	HG_ASSERT_EQUALS([items count], 1);
	HG_ASSERT_OBJ_EQUALS([[items lastObject] title], @"Watch the game");
	
	HG_TEST_DONE;
}

- (HG_TEST_RETURN_TYPE) testNumberEquality
{
	HG_ASSERT_EQUALS(1, 1);
	HG_ASSERT_EQUALS(2, 3);
	HG_TEST_DONE;
}

- (HG_TEST_RETURN_TYPE) testObjectEquality
{
	HG_ASSERT_OBJ_EQUALS([NSNumber numberWithInt:1], [NSNumber numberWithInt:1]);
	HG_ASSERT_OBJ_EQUALS([NSNumber numberWithInt:2], [NSNumber numberWithInt:3]);
	HG_TEST_DONE;
}

- (void) tearDown
{
	
}


@end
