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

#import "IcalBuddyAutoUpdaterDelegate.h"
#import "HGCLIAutoUpdater.h"
#import "HGCLIUtils.h"

#define kAppSiteURLPrefix 		@"http://hasseg.org/icalBuddy/"
#define kVersionCheckURL 		[NSURL URLWithString:[kAppSiteURLPrefix stringByAppendingString:@"?versioncheck=y"]]
#define kDownloadURLFormat		[kAppSiteURLPrefix stringByAppendingString:@"%@/icalBuddy-v%@.zip"]



@implementation IcalBuddyAutoUpdaterDelegate

- (NSURL *) latestVersionCheckURLWithCurrentVersion:(NSString *)currentVersionStr
{
	return kVersionCheckURL;
}

- (NSURL *) latestVersionInfoWebURLWithCurrentVersion:(NSString *)currentVersionStr latestVersion:(NSString *)latestVersionStr
{
	return [NSURL
		URLWithString:[kAppSiteURLPrefix
			stringByAppendingString:[@"?currentversion=" stringByAppendingString:currentVersionStr]
			]
		];
}

- (NSURL *) releaseNotesHTMLURLWithCurrentVersion:(NSString *)currentVersionStr latestVersion:(NSString *)latestVersionStr
{
	return [NSURL
		URLWithString:[kAppSiteURLPrefix
			stringByAppendingString:[@"?whatschanged=y&currentversion=" stringByAppendingString:currentVersionStr]
			]
		];
}

- (NSURL *) latestVersionZIPURLWithCurrentVersion:(NSString *)currentVersionStr latestVersion:(NSString *)latestVersionStr
{
	return [NSURL
		URLWithString:[NSString
			stringWithFormat:kDownloadURLFormat, latestVersionStr, latestVersionStr
			]
		];
}

- (NSString *) commandToRunInstaller
{
	return @"./install.command -y";
}

- (void) autoUpdater:(HGCLIAutoUpdater *)autoUpdater didInstallVersion:(NSString *)latestVersionStr
{
	Printf(@"You can run \"icalBuddy -V\" to confirm the update.\n\n");
}


@end

