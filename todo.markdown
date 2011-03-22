
TODO:

important:
-------------------------

- preference for specifying short/medium/long/full date/time formats?

- simplify handling of "relative dates" -- there's a special case (with the
  -nrd argument and all) and there's the %RD specifier. if we need both, their
  coexistence should be clearer.


user requests:
-------------------------

- ability to only get tasks with specific priorities

- ability to use relative dates today and tomorrow but the rest as normal
  dates... I don't like the long "day after tomorrow" text it seems to defeat
  the purpose of the simple today and tomorrow scheme (user ref: Edward)

- ability to use eventsTomorrow and eventsTomorrow+n to exclude today without
  having to resort to messy date range scripts... Although this is how i
  handled it for now (user ref: Edward)

- ability to specify color for specific calendars not just specific words (user
  ref: Edward)

- Add argument for seeing only recurring events (user ref: Jonathan)
- Add support for date suffixes (e.g. 1st, 2nd...) (user ref: Sam)
- Add argument -co (or: --calendarOrder) (user ref: Derek)
- Output both events and tasks into the same list (user ref: Richard B.
  +someone else)
- Display events also from delegate calendars
    - CalendarStore API won't work -- this is not an OS X feature, but an iCal
      feature
- Output in CSV format (i.e. support for more than one (or even arbitrary)
  output format(s))
	- we could start with: `icalBuddy -cf "" -b '"' -ab '"' -ps '|","|'
	  eventsToday+20` and then add an argument to specify a 'wrapper' character
	  for all printed properties (in this case, double quotes (")) and maybe an
	  argument for making all properties get printed, even if they don't have
	  values (so as to keep the column order the same). would also need an
	  argument for escaping specific characters in property values (in this
	  case, double quotes (")).
	  	- would these 2-3 extra arguments be useful for any other purpose? I'm
	  	  not sure I'd like to add them there just for this.
- AddressBookBuddy (user ref: Paul E.)
- Display also attachments
- Display also attendees


other (my own ideas):
-------------------------

- Write better examples to the web page in order to better illustrate the
  customizability of output formatting
- Implement wrapping to a specified number of maximum characters on each line
  (problem: will look off with non-fixed-width fonts if we try to match
  indenting levels and fixing those problems with arguments might become really
  complex (i.e. you would need too many different kinds of arguments for all
  the different cases))

- Add timezone support (how to handle these? what kind of support would we
  need? the "eventsFrom: to:" command already requires the timezone to be
  specified.)



