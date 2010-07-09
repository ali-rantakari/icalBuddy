


#import <Cocoa/Cocoa.h>
#import "ANSIEscapeHelper.h"
#import "HGCLIUtils.h"


ANSIEscapeHelper *ansiHelper;


NSString *runTask(NSString *path, NSArray *args)
{
	NSPipe *pipe;
	pipe = [NSPipe pipe];
	
	NSTask *task;
	task = [[NSTask alloc] init];
	[task setLaunchPath: path];
	[task setArguments: args];
	[task setStandardOutput: pipe];
	
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	
	[task launch];
	
	NSData *data;
	data = [file readDataToEndOfFile];
	
	NSString *string;
	string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	
	[task release];
	
	return [string autorelease];
}


NSString *toHTMLEntities(NSString *str)
{
	if (str == nil)
		return nil;
	
	// escape special chars
	NSString *eStr = [((NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)str, NULL)) autorelease];
	
	NSMutableString *ms = [NSMutableString string];
	
	// deal with line indentation & newlines
	NSArray *lines = [eStr componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	for (NSString *line in lines)
	{
		int i = 0;
		while (i < [line length] && [line characterAtIndex:i] == 32) // 32 is the space unichar
		{
			[ms appendString:@"&nbsp;"];
			i++;
		}
		[ms appendString:[line substringFromIndex:i]];
		[ms appendString:@"<br />"];
	}
	
	// tabs
	[ms replaceOccurrencesOfString:@"\t" withString:@"&nbsp;&nbsp;&nbsp;&nbsp;" options:NSLiteralSearch range:NSMakeRange(0,[ms length])];
	
	return ms;
}


NSString *cssClassNameForSGRCode(enum sgrCode aSGRCode)
{
	if (aSGRCode == SGRCodeIntensityBold)
		return @"bold";
	else if (aSGRCode == SGRCodeUnderlineSingle)
		return @"underlined";
	else if (aSGRCode == SGRCodeUnderlineDouble)
		return @"double-underlined";
	
	NSDictionary *colorNames = [NSDictionary dictionaryWithObjectsAndKeys:
		@"black", [NSNumber numberWithInt:0],
		@"red", [NSNumber numberWithInt:1],
		@"green", [NSNumber numberWithInt:2],
		@"yellow", [NSNumber numberWithInt:3],
		@"blue", [NSNumber numberWithInt:4],
		@"magenta", [NSNumber numberWithInt:5],
		@"cyan", [NSNumber numberWithInt:6],
		@"white", [NSNumber numberWithInt:7],
		nil
		];
	
	NSDictionary *colorTypes = [NSDictionary dictionaryWithObjectsAndKeys:
		@"fg-", [NSNumber numberWithInt:3],
		@"bg-", [NSNumber numberWithInt:4],
		@"bright-fg-", [NSNumber numberWithInt:9],
		@"bright-bg-", [NSNumber numberWithInt:10],
		nil
		];
	
	int colorTypeNum = floor(aSGRCode / 10);
	int colorNum = aSGRCode % 10;
	NSString *prefix = nil;
	for (NSNumber *typeKey in colorTypes)
	{
		if ([typeKey intValue] != colorTypeNum)
			continue;
		prefix = [colorTypes objectForKey:typeKey];
		break;
	}
	NSString *colorName = nil;
	for (NSNumber *colorKey in colorNames)
	{
		if ([colorKey intValue] != colorNum)
			continue;
		colorName = [colorNames objectForKey:colorKey];
		break;
	}
	
	if (prefix != nil && colorName != nil)
		return strConcat(prefix, colorName, nil);
	
	return nil;
}



NSString *htmlFromAttributedString(NSAttributedString *aAttributedString)
{
	NSString *cleanString = [aAttributedString string];
	NSMutableString* retString = [NSMutableString string];
	
	NSRange effectiveRange;
	NSRange limitRange = NSMakeRange(0, [aAttributedString length]);
	NSDictionary *attrs = nil;
	
	while (limitRange.length > 0)
	{
		// get attributes at current location + span for which they stay constant
		attrs = [aAttributedString
			attributesAtIndex:limitRange.location
			longestEffectiveRange:&effectiveRange
			inRange:limitRange
			];
		
		// determine CSS class names for these attributes
		NSMutableArray *classNames = [NSMutableArray array];
		
		for (NSString *attrName in attrs)
		{
			id attrValue = [attrs valueForKey:attrName];
			enum sgrCode thisSGRCode = SGRCodeNoneOrInvalid;
			
			if ([attrName isEqualToString:NSForegroundColorAttributeName])
			{
				if ([attrValue isEqual:ansiHelper.defaultStringColor])
					continue;
				thisSGRCode = [ansiHelper closestSGRCodeForColor:attrValue isForegroundColor:YES];
			}
			else if ([attrName isEqualToString:NSBackgroundColorAttributeName])
			{
				thisSGRCode = [ansiHelper closestSGRCodeForColor:attrValue isForegroundColor:NO];
			}
			else if ([attrName isEqualToString:NSFontAttributeName])
			{
				// we currently only use NSFontAttributeName for bolding so
				// here we assume that the formatting "type" in ANSI SGR
				// terms is indeed intensity
				thisSGRCode = ([[NSFontManager sharedFontManager] weightOfFont:attrValue] >= kBoldFontMinWeight)
								? SGRCodeIntensityBold : SGRCodeIntensityNormal;
			}
			else if ([attrName isEqualToString:NSUnderlineStyleAttributeName])
			{
				if ([attrValue intValue] == NSUnderlineStyleSingle)
					thisSGRCode = SGRCodeUnderlineSingle;
				else if ([attrValue intValue] == NSUnderlineStyleDouble)
					thisSGRCode = SGRCodeUnderlineDouble;
				else
					thisSGRCode = SGRCodeUnderlineNone;
			}
			
			NSString *className = cssClassNameForSGRCode(thisSGRCode);
			if (className == nil)
				continue;
			[classNames addObject:className];
		}
		
		// append the text within our span into the string we're building,
		// inside a span tag with the CSS class names we have
		if ([classNames count] > 0)
		{
			[retString appendString:@"<span class='"];
			[retString appendString:[classNames componentsJoinedByString:@" "]];
			[retString appendString:@"'>"];
		}
		[retString appendString:[cleanString substringWithRange:effectiveRange]];
		if ([classNames count] > 0)
		{
			[retString appendString:@"</span>"];
		}
		
		
		limitRange = NSMakeRange(NSMaxRange(effectiveRange),
								 NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
	}
	
	return retString;
}



int main(int argc, char *argv[])
{
	NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
	
	ansiHelper = [[[ANSIEscapeHelper alloc] init] autorelease];
	
	if (argc == 1)
	{
		Print(@"Need command to run as an argument.\n");
		return 1;
	}
	
	NSString *command = [NSString stringWithUTF8String:argv[1]];
	
	command = [command stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if ([command length] == 0)
	{
		Print(@"Need command to run as an argument.\n");
		return 1;
	}
	
	NSString *output = runTask(@"/bin/bash", [NSArray arrayWithObjects: @"-c", command, nil]);
	output = toHTMLEntities(output);
	
	Print(htmlFromAttributedString([ansiHelper attributedStringWithANSIEscapedString:output]));
	
	
	[autoReleasePool release];
	return 0;
}


















