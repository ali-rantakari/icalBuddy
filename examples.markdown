
# icalBuddy Usage Examples

I've noticed that a lot of people who are not familiar with the command line have been using icalBuddy with GeekTool in order to display events and tasks from their calendars on their desktops. I understand how dealing with the user interface of a command-line application (i.e. figuring out arcane combinations of command arguments) might be daunting for these people  so I thought I'd make this page to try and help out by **showing some examples** of what kind of output you can get from icalBuddy (and **what arguments you need to use** to get them).

Even if you're a regular Unix Hacker&trade; this might still give you a good understanding of what this program can give you.

<div style='height:40px'></div>


### Today's Events

First we'll simply use the `eventsToday` command argument to print out all the events occurring today.

    ••• /usr/local/bin/icalBuddy eventsToday+10

This is what the default output looks like.

_(Note that the date and time formats are [taken from System Preferences][faq-datetime-formats] by default, so they might look different on your computer.)_

[faq-datetime-formats]: http://hasseg.org/icalBuddy/faq.html#Q:+How+can+I+get+icalBuddy+to+display+times+according+to+a+12-hour+clock?

•-----------------------------------


### Add Some Color

Let's use the same command as last time, but add the `-f` argument:

    ••• /usr/local/bin/icalBuddy -f eventsToday+10

Whee! That looks a lot nicer. In fact, I like colors so much that I'm just going to keep this argument in all my commands from now on.

•-----------------------------------


### Separate by Date

Check:

    ••• /usr/local/bin/icalBuddy -f -sd eventsToday+10

Blah blah.

•-----------------------------------




