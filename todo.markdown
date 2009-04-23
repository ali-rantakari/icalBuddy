
TODO:

user requests:
-------------------------

- Output in CSV format (i.e. support for more than one (or even arbitrary) output format(s))
	- we could start with: `icalBuddy -cf "" -b '"' -ab '"' -ps '|","|' eventsToday+20`
	  and then add an argument to specify a 'wrapper' character for all printed properties
	  (in this case, double quotes (")) and maybe an argument for making all properties
	  get printed, even if they don't have values (so as to keep the column order the same).
	  would also need an argument for escaping specific characters in property values (in
	  this case, double quotes (")).
	  	- would these 2-3 extra arguments be useful for any other purpose? I'm not sure
		  I'd like to add them there just for this.
- Display also attachments
- Display also attendees


other (my own ideas):
-------------------------

- Write better examples to the web page in order to better illustrate the customizability
  of output formatting
- Rewrite man page using the POD syntax (I hate the raw man page syntax so much)
- Implement wrapping to a specified number of maximum characters on each line (problem: will
  look off with non-fixed-width fonts if we try to match indenting levels and fixing those
  problems with arguments might become really complex (i.e. you would need too many different
  kinds of arguments for all the different cases))

- Add timezone support (how to handle these?)


Replace versionNumberCompare() with this: (is this adequate? must test. might break with more
than single-digit numbers.)

    NSNumberFormatter *conv = [[[NSNumberFormatter alloc] init] autorelease];
    NSNumber *curVersNum = [conv numberFromString:[versDict objectForKey:(id)@"Version"]];
    NSNumber *curVersBundleNum = [conv numberFromString:sb_bundleVers];
    
    if ([curVersBundleNum compare:curVersNum]==NSOrderedAscending)
        (-> update available)


