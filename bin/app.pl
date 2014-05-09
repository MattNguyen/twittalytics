#!/usr/bin/env perl
use Dancer;
use Twittalytics;

if ($ENV{'ENVIRONMENT'} eq "production") {
  set "environment" => "production";
} else {
  set "environment" => "development";
}

dance;
