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
	Printf(@"set up!\n");
}

- (NSNumber *) testNumberEquality
{
	HG_ASSERT_EQUALS(1, 1, @"1 should be 1 but was %d instead");
	HG_ASSERT_EQUALS(2, 3, @"2 should be 2 but was %d instead");
	HG_UNITTEST_DONE;
}

- (NSNumber *) testObjectEquality
{
	HG_ASSERT_OBJ_EQUALS([NSNumber numberWithInt:1], [NSNumber numberWithInt:1], @"1 should be 1 but was %@ instead");
	HG_ASSERT_OBJ_EQUALS([NSNumber numberWithInt:2], [NSNumber numberWithInt:3], @"2 should be 2 but was %@ instead");
	HG_UNITTEST_DONE;
}

- (void) tearDown
{
	Printf(@"tear down!\n");
}


@end
