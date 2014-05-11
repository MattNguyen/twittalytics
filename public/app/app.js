var app = angular.module('twittalytics', ['ngRoute', 'twittalytics.services', 'twittalytics.controllers']);

app.config(['$routeProvider','$locationProvider','$httpProvider', function($routeProvider,$locationProvider,$httpProvider) {
  $httpProvider.defaults.headers.common["X-Requested-With"] = 'XMLHttpRequest';

  $locationProvider.html5Mode(true);
  $locationProvider.hashPrefix('!');

  $routeProvider
    .when('/', { controller: 'HomeController', templateUrl: '/app/partials/index.html' })
    .when('/user_statuses', { controller: 'StatusesController', templateUrl: '/app/partials/get_statuses.html' })
    .when('/common_friends', { controller: 'CommonFriendsController', templateUrl: '/app/partials/common_friends.html' })
    .otherwise({ redirectTo: '/' });
}]);
