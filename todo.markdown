
TODO:

before next release:
-------------------------
- update translations for new priority L10N strings
  - Need people to help me with this.


own ideas:
-------------------------
- allow user to put config files under ~/.icalBuddy/.

- preference for specifying short/medium/long/full date/time formats?

- simplify handling of "relative dates" -- there's a special case (with the
  -nrd argument and all) and there's the %RD specifier. if we need both, their
  coexistence should be clearer.


user requests:
-------------------------
- Output both events and tasks into the same list
  - Problem: how to handle args that assume we're printing only events or tasks?

- ability to specify color for specific calendars not just specific words (user
  ref: Edward)

- Add argument -co (or: --calendarOrder) (user ref: Derek)

- ability to only get tasks with specific priorities
- ability to only get only undated tasks (or no undated tasks) (user ref: Thomas R.)
- Add argument for seeing only recurring events (user ref: Jonathan)
- Add support for date suffixes (e.g. 1st, 2nd...) (user ref: Sam)
- ability to use relative dates today and tomorrow but the rest as normal
  dates... I don't like the long "day after tomorrow" text it seems to defeat
  the purpose of the simple today and tomorrow scheme (user ref: Edward)
- Display also attachments
- Display also attendees
- AddressBookBuddy (user ref: Paul E.)


other (my own ideas):
-------------------------

- Write better examples to the web page in order to better illustrate the
  customizability of output formatting
- Implement wrapping to a specified number of maximum characters on each line
  (problem: will look off with non-fixed-width fonts if we try to match
  indenting levels and fixing those problems with arguments might become really
  complex (i.e. you would need too many different kinds of arguments for all
  the different cases))

- Think about timezone support (how to handle these? what kind of support would
  we need? the "eventsFrom: to:" command already requires the timezone to be
  specified.)



