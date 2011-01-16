// icalBuddy
// 
// http://hasseg.org/icalBuddy
//

/*
The MIT License

Copyright (c) 2008-2010 Ali Rantakari

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

#import "icalBuddyMacros.h"
#import "HGCLIUtils.h"


void openConfigFileInEditor(NSString *configFilePath, BOOL openInCLIEditor)
{
	NSString *path = configFilePath;
	if (path == nil)
		path = [kConfigFilePath stringByExpandingTildeInPath];
	
	BOOL configFileIsDir;
	BOOL configFileExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&configFileIsDir];
	
	if (!configFileExists)
	{
		[kConfigFileStub writeToFile:path atomically:YES];
		Printf(@"Configuration file did not exist; it has now been created.\n");
	}
	
	if (configFileIsDir)
	{
		PrintfErr(
			@"Error: There seems to be a directory where the configuration\nfile should be: %@\nCan not open configuration file.\n",
			path
			);
		return;
	}
	
	if (openInCLIEditor)
	{
		NSString *foundEditorPath = nil;
		
		NSMutableArray *preferredEditors = [NSMutableArray arrayWithObjects:@"vim", @"vi", @"nano", @"pico", @"emacs", @"ed", nil];
		NSString *pathEnvironmentVariable = [[[NSProcessInfo processInfo] environment] objectForKey:@"PATH"];
		NSString *editorEnvironmentVariable = [[[NSProcessInfo processInfo] environment] objectForKey:@"EDITOR"];
		
		if (editorEnvironmentVariable != nil)
		{
			if ([[NSFileManager defaultManager] isExecutableFileAtPath:editorEnvironmentVariable])
				foundEditorPath = editorEnvironmentVariable;
			else
			{
				[preferredEditors removeObject:[editorEnvironmentVariable lastPathComponent]];
				[preferredEditors insertObject:[editorEnvironmentVariable lastPathComponent] atIndex:0];
			}
		}
		
		if (foundEditorPath == nil && pathEnvironmentVariable != nil)
		{
			NSArray *separatePaths = [pathEnvironmentVariable componentsSeparatedByString:@":"];
			NSString *thisFullEditorPathCandidate;
			NSString *thisEditor;
			for (thisEditor in preferredEditors)
			{
				NSString *thisPath;
				for (thisPath in separatePaths)
				{
					thisFullEditorPathCandidate = strConcat(thisPath, @"/", thisEditor, nil);
					if ([[NSFileManager defaultManager] isExecutableFileAtPath:thisFullEditorPathCandidate])
					{
						foundEditorPath = thisFullEditorPathCandidate;
						break;
					}
				}
				if (foundEditorPath != nil)
					break;
			}
		}
		
		if (foundEditorPath != nil)
		{
			Printf(
				@"Opening config file for editing with %@ -- press\nany key to continue or Ctrl-C to cancel.\n",
				foundEditorPath
				);
			if (system("read") == 0)
				system([strConcat(@"'", foundEditorPath, @"' '", path, @"'", nil) UTF8String]);
		}
		else
		{
			PrintfErr(
				@"Error: Can not find or execute any of the following\neditors in your $PATH: %@\n",
				[preferredEditors componentsJoinedByString:@", "]
				);
		}
	}
	else // GUI editor
	{
		if ([[NSWorkspace sharedWorkspace] fullPathForApplication:kPropertyListEditorAppName] != nil)
		{
			Printf(@"Opening configuration file with the Property List\nEditor application.\n");
			[[NSWorkspace sharedWorkspace] openFile:path withApplication:kPropertyListEditorAppName];
		}
		else
		{
			Printf(@"Opening configuration file with the default application\nassociated with the property list type.\n");
			[[NSWorkspace sharedWorkspace] openFile:path];
		}
	}
}


