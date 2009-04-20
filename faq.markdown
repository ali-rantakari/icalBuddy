
icalBuddy FAQ
=====================

------------

### Q: Does icalBuddy have a manual? If so, where is it?

Yes indeed: icalBuddy, like most other Unix-type command line applications, has something called a [man page][wikipediamanpages]. You can read it by typing `man icalBuddy` into the terminal, and the man page for the latest version of icalBuddy is also [available online][manpageonline]. If you'd prefer to use a dedicated application for reading manual pages in normal GUI windows, see the TUAW post ["Here comes your man (viewer)"][tuawmanviewers].


### Q: The output of my calendar items is garbled! What gives?

icalBuddy uses unicode (UTF-8) string encoding by default in its output, so make sure that the application you're using to invoke it understands UTF-8. If there's a mismatch between the string encoding icalBuddy uses for its output and the string encoding an application uses to read that output, some special characters (like umlauts, chinese or arabic) might not display correctly.

You can turn on UTF-8 encoding in **Apple's Terminal.app** from *preferences > settings > (whichever style you're using) > advanced > international > character encoding*. In **iTerm** this can be done from *"Bookmarks" menu > manage profiles... > terminal profiles > (whichever profile you're using, probably "default") > encoding*. **[GeekTool][geektool]** doesn't understand UTF-8 by default, but you can get a custom build that does from [Xu Lian's page here][xulian].

You can also use the `--strEncoding` argument to make icalBuddy output using some other string encoding. Run `icalBuddy strEncodings` to see all the possible values you can use for that argument.


### Q: How can I get icalBuddy to display times according to a 12-hour clock?

You can use the `-tf` (or `--timeFormat`) argument to specify the format in which to display times. For example, `icalBuddy -tf "%1I:%M %p" eventsToday` would display times such as `5:00 PM`. See [Apple's documentation][datetimeformats] for all the possible values you can use for date and time formatting (there's also the `-df` (or `--dateFormat`) argument for date formatting, which works similarly to this one.)


### Q: I would like icalBuddy to speak my language instead of just english. Can it be localized?

As of version 1.5.0, it can be. Read the [localization man page][l10nmanpageonline] for documentation on how to do this. If you think you have managed to write a nice general localization file for your language, please [contact me][hassegcontact] and I'll include it into the distribution package so that others who'd like to use a localized icalBuddy in your language wouldn't have to redo that work.


### Q: How can I change the bullet points used in the output? We don't like them asterisks around these here parts.

You can use the `-b` (or `--bullet`) argument to change the normal bullet point value (`"* "` by default) and `-ab` (or `--alertBullet`) to change the alert bullet point value (`"! "` by default, used for tasks that are late from their due date.) Also note that you can change indenting for non-bulleted lines with the `-i` (or `--indent`) argument. See [the manual page][manpageonline] for more info.


### Q: How can I keep all (or some) event/task properties on the same line?

You can use the `-ps` (or `--propertySeparators`) argument to specify the strings to use between the properties that get printed out. An example:

    $ icalBuddy eventsToday+2
	* An Event (Work)
	    location: Meeting room A
	    tomorrow at 13:00 - 14:15
    $
	$ icalBuddy -ps "| / | -- |" eventsToday+2
	* An Event (Work) / Meeting room A -- tomorrow at 13:00 - 14:15


### Q: For some of my calendar items the bullet point is displayed on the right side of the line instead of on the left side, like it's supposed to. Why is this?

The calendar items in question probably have text in a language that's written from right to left? The Mac OS X text layout system sees this and automatically "flips" the line, putting the bullet point (which was supposed to be at the far left side of the line) to the far right. There are two workarounds I've come up with, depending on the application you're using to invoke icalBuddy:

 1. If the application you're using to call icalBuddy allows you to set the "writing direction" for the printed output, set that to something other than "natural".
 2. If the application you're using to call icalBuddy <em>does not</em> allow you to set the "writing direction", you can try to "trick" the layout system to keep the bullets on the left side by adding a letter from the latin alphabet as a part of the bullet point. Unfortunately this is not very pretty, though. :( So for example: `icalBuddy -b "I- "`. You can also omit the bullet points completely by running: `icalBuddy -b "" -ab ""`, but this won't keep the lines from being "flipped".


### Q: The question I had in mind is not answered here. What should I do?

You should look through icalBuddy's [manual page][manpageonline] and see if what you're looking for is documented there. Just type `man icalBuddy` into the terminal to see it. If what you're looking for is not in the manual, you can [contact the me, the author][hassegcontact].





[wikipediamanpages]: 	http://en.wikipedia.org/wiki/Manual_page_(Unix)
[manpageonline]: 		http://hasseg.org/icalBuddy/man.html
[tuawmanviewers]: 		http://www.tuaw.com/2008/03/07/here-comes-your-man-viewer/
[l10nmanpageonline]: 	http://hasseg.org/icalBuddy/localization-man.html
[geektool]: 			http://projects.tynsoe.org/en/geektool
[xulian]: 				http://sites.google.com/site/lianxukeefo/Home/research/geektool-utf8
[datetimeformats]: 		http://developer.apple.com/documentation/Cocoa/Conceptual/DataFormatting/Articles/df100103.html#//apple_ref/doc/uid/TP40007972-SW9
[hassegcontact]: 		http://hasseg.org/

