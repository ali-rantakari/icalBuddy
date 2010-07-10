
# icalBuddy Usage Examples

I've noticed that a lot of people who are not familiar with the command line have been using icalBuddy with GeekTool in order to display events and tasks from their calendars on their desktops. I understand how dealing with the user interface of a command-line application (i.e. figuring out arcane combinations of command arguments) might be daunting for these people so I thought I'd make this page to try and help out by showing some examples of what kind of output you can get from icalBuddy (and what arguments you need to use to get them).


### Today's Events

First we'll simply use the `eventsToday` command argument to print out all the events occurring today.

    ••• /usr/local/bin/icalBuddy eventsToday+10

This is what the default output looks like.

•-----------------------------------


### Add Some Color

Let's use the same command as last time, but add the `-f` argument:

••• icalBuddy -f eventsToday+10

Whee! That looks a lot nicer. In fact, I like colors so much that I'm just going to keep this argument in all my commands from now on.

•-----------------------------------




