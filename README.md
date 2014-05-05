Twittalytics
---------

A coding challenge from Crowdtilt.

### Requirements

Using [Perl Dancer](http://perldancer.org/,https://metacpan.org/module/Dancer), write a web app with these features:

* Given a twitter username, display their most recent tweets
  * Don't hit the twitter api via javascript, but on the backend/perl-side
  * Given two twitter usernames, display the intersection of the people that they
    follow
  * Try to minimize requests to twitter API

Feel free to use any open source tools/libraries that you wish on the perl, javascript, css side.

### Setup Instructions

* Make sure Redis is running at 127.0.0.1:6379.
* `$ perl bin/app.pl`.
* Go to http://localhost:3000 in the browser.

