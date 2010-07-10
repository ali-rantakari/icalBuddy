
<div id='title'>icalBuddy Usage Examples</div>

I've noticed that a lot of people who are not familiar with the command line have been using icalBuddy with GeekTool in order to display events and tasks from their calendars on their desktops. I understand how dealing with the user interface of a command-line application (i.e. figuring out arcane combinations of weird command arguments) might be daunting for these people so I thought I'd make this page to try and help out by **showing some examples** of what kind of output you can get from icalBuddy (and **what arguments you need to use** to get them).

Even if you're a regular Unix Hacker&trade; this might still give you a good understanding of what this program is good for.



    ¶¶¶ TOC ¶¶¶


# Basic Examples: Events


### Events Today

First we'll simply use the `eventsToday` command argument to print out all the events occurring today.

    ••• icalBuddy eventsToday

This is what the default output looks like.

_(Note that the date and time formats are [taken from System Preferences][faq-datetime-formats] by default, so they might look different on your computer.)_

[faq-datetime-formats]: http://hasseg.org/icalBuddy/faq.html#Q:+How+can+I+get+icalBuddy+to+display+times+according+to+a+12-hour+clock?

•-----------------------------------


### Events *Later* Today

In the previous example the output shows *all* events for the current date, including past ones. We can *exclude events that have already passed* simply by adding the `-n` (or `--includeOnlyEventsFromNowOn`) argument:

    ••• icalBuddy -n eventsToday

So now we only get events occurring *later today*. You can use the `-n` argument **whenever you want to exclude past events from the output**.


•-----------------------------------


### Events in the Near Future

Let's use the same command as in the first example, but add `+10` after `eventsToday`:

    ••• icalBuddy eventsToday+10

We get a bit more stuff now. The `eventsToday+10` command argument gives us events occurring **today and 10 days into the future**. You can of course do this with any number, like `eventsToday+1` to get events for today and tomorrow, for example.

•-----------------------------------


### Events in the Near Future &mdash; In TechniColor&trade;

Now let's add the `-f` (or `--formatOutput`) argument:

    ••• icalBuddy -f eventsToday+10

Whee! That looks a lot nicer. In fact, I like colors so much that I'm just going to **keep this argument in all my commands from now on**.

_(Note that icalBuddy tries to choose colors that match the calendar colors set in iCal as closely as possible for the item titles, but these colors won't match exactly because command-line programs can only use [16 colors via ANSI escape sequences][ansicolors]. Depending on the program you're using to display icalBuddy's output, you might be able to tune each of these colors to your liking ([NerdTool][nerdtool] can do this, for example) but the fact that there'll only ever be 16 of them remains.)_

[ansicolors]: http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
[nerdtool]: http://mutablecode.com/apps/nerdtool

•-----------------------------------


### Events in the Near Future, Separated by Date

In the previous examples all of the events are in the same continuous list. We can **separate them by date** by adding the `-sd` (or `--separateByDate`) argument:

    ••• icalBuddy -f -sd eventsToday+10

Notice that these are the same events as in the previous example, they're just separated under date headings.



•-----------------------------------


### Events in the Near Future, Separated by Calendar

Instead of separating events by date, we can separate them **by calendar** with the `-sc` (or `--separateByCalendar`) argument:

    ••• icalBuddy -f -sc eventsToday+10

Again -- same events as before, just under calendar headings this time.


•-----------------------------------


# Basic Examples: Tasks


### Uncompleted Tasks

We can switch the command argument to `uncompletedTasks`:

    ••• icalBuddy -f uncompletedTasks

This will give us *all uncompleted tasks*, sorted by priority.

You can sort tasks by their due date by adding either the `-std` (or `--sortTasksByDate`) or the `-stda` (or `--sortTasksByDateAscending`) argument (sort in descending or ascending order, respectively).

_(Notice those red exclamation marks? Those are "alert bullet points" and they are used in place of the standard bullet point for tasks that are past their due date. [You can change both the regular and the alert bullet points](#Custom+Bullet+Points) to whatever you want.)_

•-----------------------------------


### Uncompleted Tasks Due in the Near Future

If we're only interested in seeing uncompleted tasks that are due soon (let's say within the next seven days) we can use the `tasksDueBefore:DATE` command argument with `today+7` as the date:

    ••• icalBuddy -f tasksDueBefore:today+7

You can specify any date (like *tomorrow*, *'aug 10'*, *'next sunday'* or *'2010-10-03 22:00:00 +02:00'*) for `tasksDueBefore:` but using `today+NUM` is useful for always getting the near future tasks regardless of what the current date is.


•-----------------------------------


### Uncompleted Tasks Due in the Near Future, Separated by Calendar

We can add the `-sc` (or `--separateByCalendar`) argument here as well:

    ••• icalBuddy -f -sc tasksDueBefore:today+7

Both events and tasks can be separated by calendar (as seen here) as well as by (due) date (with the `-sd` (or `--separateByDate`) argument).


•-----------------------------------




# Tips and Tricks: Output Formatting


### Underlined Section Titles

You can make section titles more concise by making them underlined while removing the section separators completely:

    ••f sectionTitle = bold,underlined
    ••• icalBuddy -f -sc -ss "" eventsToday+10

The section separators (i.e. the dashes: `---------`) can be removed by specifying an empty value for the `-ss` (or `--sectionSeparators`) argument.

The section title can be made underlined by adding the value `underlined` for the `sectionTitle` formatting key in the config file's formatting section.


•-----------------------------------


### Custom Bullet Points

You can customize both the regular and the "alert" bullet points to your liking:

    ••f alertBullet = bold, white, bg:red
    ••f bullet = white, bg:blue
    ••• icalBuddy -f -b ">> " -ab "!! " -ps "|\n     |" uncompletedTasks

You can specify your own bullet points with the `-b` (or `--bullet`) argument, as well as your own *alert* bullet points with the `-ab` (or `--alertBullet`) argument.

You can customize the bullet point formatting by specifying whatever formatting parameters you'd like (e.g. `bold,red`) for the `bullet` and `alertBullet` keys in the config file's formatting section.

In order to indent the property lines one character further, we'll replace the default value for the `-ps` (or `--propertySeparators`) argument (a newline followed by four spaces) with a newline followed by *five* spaces.


•-----------------------------------


### Very Concise Event or Task List

We can get a very concise listing of events or tasks (this example shows events but the same arguments work for tasks as well) with just a few arguments:

    ••• icalBuddy -f -npn -nc -ps "/ | /" eventsToday+10

We use the `-npn` (or `--noPropertyNames`) argument to omit all property names and the `-nc` (or `--noCalendarNames`) argument to omit all calendar names.

In order to keep all properties (location, notes, date/time etc.) of the same events/tasks on the same line we set the value `"/ | /"` for the `-ps` (or `--propertySeparators`) argument. This means that icalBuddy should separate all properties with the string ` | ` (the slashes at the beginning and the end are just the separator characters -- see the [man page][man] for more info).



•-----------------------------------



# Further Information

That's it for the examples -- be sure to check out the [man page][man] for a **complete list of all the arguments** you can use to customize your output.

If you want to **customize the colors** used or set constant arguments you can do that by creating and editing the configuration file. See the [configuration file man page][cfg-man] for more info.

The [Frequently Asked Questions][faq] document will probably be useful as well.


[man]: http://hasseg.org/icalBuddy/man.html
[cfg-man]: http://hasseg.org/icalBuddy/config-man.html
[faq]: http://hasseg.org/icalBuddy/faq.html












