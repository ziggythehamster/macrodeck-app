MacroDeck Platform Test App
===========================

Internal name: "Admin App"

This app is released under the terms of the GPL-2 with the exception that
Poseidon Imaging retains copyright for all contributions in our official
distribution.

What is this?
-------------

This is an app to test the functionality of the MacroDeck Platform. It will
later serve as a way to load the different objects used by your app. Its
intention is that you will be wedging this into your existing Ruby web
framework apps (Rails, Camping, etc.).

Developer documentation / brain dump
====================================

(I'm leaving a brain dump here, please ignore it unless you know what I'm
spewing here)

Behaviors
---------

	abbreviation			Display after title.
	bitly_hash			Render as a link to the hash.
	description			Render as a paragraph after title.
	foursquare_venue_id		Render as a link to the venue.
	foursquare_user_id		Render as a link to the user.
	url				Render as a link to the URL.
	(any Time/Date object)		Render as a locale-correct time/date.

