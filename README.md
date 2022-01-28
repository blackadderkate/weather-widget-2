An updated version of the "plasma-applet-weather-widget" by Kotelnik.

To summarise the reason for this fork, YR.NO have changed their API and Kotelnik's original widget no longer works correctly with their data, and their project seems to be abandoned.
So I have downloaded their code, did some serious research and hacking over Christmas, and eventually come up with this project.

There are a couple of significant changes:

The new API uses Latitude and Longtitude to download the weather data - this version includes a searchable database of places.

The new Data does not include Sunrise or Sunset times, so I've had to find an alternative API but this new source does not appear to be very accurate.

A full list of the API changes can be found here: https://developer.yr.no/doc/guides/getting-started-from-forecast-xml/

In addition I have made the following modifications:

I have added Wind Direction/Strength icons to the "rendered" Meteogram so it more closely matches the original YR.NO graphic.

I have added MouseOvers to the Wind Direction/Strength icons to show the predicted Windspeed value.

I have added rainfall Units to the Meteogram.






I am just a hobbyist / enthusiastic amateur - I'm sure a professional Javascript / QML programmer will be horrified with my code!
So bug reports, suggestions, code polishes and bugfixes are welcome - as are translations (as Google Translate may not have been entirely accurate)!
