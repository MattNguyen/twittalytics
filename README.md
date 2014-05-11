Twittalytics
---------

A coding challenge from Crowdtilt.

![Birthday Shots](https://fbcdn-sphotos-h-a.akamaihd.net/hphotos-ak-prn2/t1.0-9/p417x417/1526416_10201883243017278_1749366691_n.jpg "My birthday funded through Crowdtilt")

### Requirements

Using [Perl Dancer](http://perldancer.org/,https://metacpan.org/module/Dancer), write a web app with these features:

* Given a twitter username, display their most recent tweets
  * Don't hit the twitter api via javascript, but on the backend/perl-side
  * Given two twitter usernames, display the intersection of the people that they
    follow
  * Try to minimize requests to twitter API

Feel free to use any open source tools/libraries that you wish on the perl, javascript, css side.

### Requirements
* NPM
* CPANM

### Setup Instructions

* Make sure Redis is running at 127.0.0.1:6379.
* Create a `.env` file with the following environment variables:
  * `TWITTER_API_KEY=<your api key>`
  * `TWITTER_API_SECRET=<your api secret>`
* Run `npm install`
* Run `bower install`
* Run `grunt build`
* `$ perl bin/app.pl` to start the server.
* Go to http://localhost:3000 in the browser.
