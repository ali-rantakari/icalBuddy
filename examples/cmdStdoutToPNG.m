


#import <Cocoa/Cocoa.h>
#import "ANSIEscapeHelper.h"
#import "HGCLIUtils.h"
#import "RegexKitLite.h"

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




#define VIEW_SIZE NSMakeRect(0,0, 500, 400)
#define FONT_NAME @"Monaco"
#define FONT_SIZE 9
#define TEXT_COLOR [NSColor whiteColor]
#define BACKGROUND_COLOR [NSColor blackColor]

int main(int argc, char *argv[])
{
    NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];

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

    ANSIEscapeHelper *ansiHelper = [[[ANSIEscapeHelper alloc] init] autorelease];
    ansiHelper.defaultStringColor = TEXT_COLOR;

    NSTextView *textView = [[[NSTextView alloc] initWithFrame:VIEW_SIZE] autorelease];
    [textView setEditable:NO];
    [textView setBackgroundColor:BACKGROUND_COLOR];

    NSString *output = runTask(@"/bin/bash", [NSArray arrayWithObjects: @"-c", command, nil]);

    NSAttributedString *attrStr = [ansiHelper attributedStringWithANSIEscapedString:output];
    [[textView textStorage] setAttributedString:attrStr];
    [[textView textStorage] setFont:[NSFont fontWithName:FONT_NAME size:FONT_SIZE]];

    NSBitmapImageRep *textViewImageRep = [textView bitmapImageRepForCachingDisplayInRect:[textView frame]];
    [textView cacheDisplayInRect:[textView frame] toBitmapImageRep:textViewImageRep];
    NSData *imagePNGData = [textViewImageRep representationUsingType:NSPNGFileType properties:nil];

    [imagePNGData writeToFile:@"cmdStdout.png" atomically:YES];


    [autoReleasePool release];
    return 0;
}


















