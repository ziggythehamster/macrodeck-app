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

SpecialPhoto / MTurk Lifecycle Plan
===================================

1. User submits photo.
2. A `SpecialPhoto` is created. This will be sort of complicated, because I'm
   not sure how we're allowing the submitter to specify which place it belongs to.
   Probably I'm thinking just leverage Lucene and see if we can get in the ballpark,
   and then we return a menu to the user if we're not sure.
3. A background process picks up the new `SpecialPhoto` and creates an MTurk
   HIT for the first question. Question type will be `ExternalQuestion`,
   `MaxAssignments` will be 1, HIT type will be question or whatever the ID for that
   would be.
4. One turk will submit their answer.
5. A background process will call the `GetReviewableHITs` API to see if there are
   any answers to process.
6. If there are, retrieve the answers, and update the `SpecialPhoto`s to store the
   turk-provided answer. Call the `SetHITAsReviewing` API to mark the HIT as reviewing.
   Create a new HIT, `MaxAssignments` will be 3, question type will be `ExternalQuestion`,
   HIT type will be verification or the ID that corresponds to that. Verification tasks
   will show the turk's answers, and ask if it accurately represents the photo.
7. A background process will call the `GetReviewableHITs` API to see if there are
   any verification answers to process.
8. If there are, and the majority of workers validated the answer, then approve the
   original worker and the workers that provided the correct answer. Reject the workers
   that validated incorrectly. Flag the answer as validated on our end and call
   `DisposeHIT` on both HITs. If the majority of workers rejected the answer, then reject
   the original worker's answer and the workers that said the original worker was correct.
   Approve the workers that rejected the answer. Call `ExtendHIT` on the original question
   and allow one more person to answer it. Call `DisposeHIT` on this verification HIT.
   Go back to #4.
9. Determine the next question and submit a HIT for the next question. Repeat this process.
   Since there can be multiple questions, we need to support figuring out all of the
   questions with met prerequisites, or we will never be able to get through a `SpecialPhoto`
   in a timely manner.

If a HIT ever comes back reviewable but has no answers, we will `ExtendHIT` and give it a
longer time limit and stop processing at that point.

We can use the notification receptor API so that we don't have to have a background process,
but I don't know how complicated the signing algorithm is, and they don't have any kind of
queue for notifications that never made it.

Ideas for bonuses
-----------------

* If all 3 validators agree on the original worker's answer, give a bonus to the original
  worker.
* Track the workers, and for workers that consistently provide good answers, ramp up the
  bonus based on the number of correct answers they've given to us over time. Maybe range
  the bonus from 50% of the original HIT to 200% of the original HIT?

Notification API
----------------

* [Notification Receptor API - The REST Transport][1]
* MTurk uses a quasi-REST API for notifications.
* You have to set the notification URI in the HIT Type.
* EventTypes we might have to accept: `AssignmentSubmitted` (turk is done),
  `HITReviewable` (can review/process a HIT).
* [AWS Request Authentication][2] - maybe we can use RightAws to do this instead of
  rolling our own. [See also][3] from RTurk.

[1]: http://docs.amazonwebservices.com/AWSMechTurk/2008-08-02/AWSMturkAPI/index.html?ApiReference_NotificationReceptorAPI_RESTTransportArticle.html
[2]: http://docs.amazonwebservices.com/AWSMechTurk/latest/AWSMechanicalTurkRequester/MakingRequests_RequestAuthenticationArticle.html
[3]: https://github.com/mdp/rturk/blob/master/lib/rturk/requester.rb
