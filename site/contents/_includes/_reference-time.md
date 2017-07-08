{@ _defs_.md || 0 @}

{#op||now||{{null}}||{{flt}}||
Returns the current time as Unix timestamp with microseconds. #}

{#op||timestamp||{{null}}||{{i}}||
Returns the current time as Unix timestamp. #}
  
{#op||timeinfo||{{i}}||{{tinfo}}||
Returns a timeinfo dictionary from timestamp {{i}}. #}
  
{#op||to-timestamp||{{tinfo}}||{{i}}||
Converts the timeinfo dictionary {{tinfo}} to the corresponding Unix timestamp. #}
  
{#op||datetime||{{i}}||{{s}}||
Returns an ISO 8601 string representing the combined date and time in UTC of timestamp {{i}}. #}


{#op||tformat||{{i}} {{s}}||{{s}}||
> Formats timestamp {{i}} using string {{s}}.
> 
> > %tip%
> > Tip
> > 
> > For information on special characters in the format string, see the [format](https://nim-lang.org/docs/times.html#format,TimeInfo,string) nim method. #}
