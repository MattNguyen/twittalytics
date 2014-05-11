var app = angular.module('twittalytics', ['ngRoute', 'twittalytics.services', 'twittalytics.controllers'])

app.config(['$routeProvider','$locationProvider','$httpProvider', function($routeProvider,$locationProvider,$httpProvider) {
  $httpProvider.defaults.headers.common["X-Requested-With"] = 'XMLHttpRequest';

  $locationProvider.html5Mode(true);
  $locationProvider.hashPrefix('!');

  $routeProvider
    .when('/', { controller: 'HomeController', templateUrl: '/twittalytics/partials/index.html' })
    .when('/user_statuses', { controller: 'StatusesController', templateUrl: '/twittalytics/partials/get_statuses.html' })
    .when('/common_friends', { controller: 'CommonFriendsController', templateUrl: '/twittalytics/partials/common_friends.html' })
    .otherwise({ redirectTo: '/' });
}]);

var services = angular.module('twittalytics.services', []);

services.factory('RecentStatuses', ['$http', function($http) {
  var RecentStatuses = function(data) { angular.extend(this, data) };

  RecentStatuses.get = function(username) {
    return $http.get('http://localhost:3000/api/users/' + username + '/recent_statuses');
  };

  return RecentStatuses;
}])

services.factory('CommonFriends', ['$http', function($http) {
  var CommonFriends = function(data) { angular.extend(this, data) };

  CommonFriends = function(username1, username2) {
    var url = 'http://localhost:3000/api/users/common_friends?username1=' + username1 + '&username2=' + username2;
    return $http.get(url);
  };

  return CommonFriends;
}])

var controllers = angular.module('twittalytics.controllers', []);

controllers.controller("HomeController", ["$scope", function($scope) {
}]);

controllers.controller("CommonFriendsController", ["$scope", "CommonFriends", function($scope, CommonFriends) {
  $scope.getCommonFriends = function() {
    CommonFriends($scope.username1, $scope.username2)
      .then(function(response) {
        $scope.commonFriends = response.data.common_friends;
      }, function(error) {
        console.log('nooo');
      });
  }
}]);

controllers.controller("StatusesController", ["$scope", "RecentStatuses", function($scope, RecentStatuses) {
  $scope.getRecentStatuses = function() {
    RecentStatuses.get($scope.username)
      .then(function(response) {
        $scope.recentStatuses = response.data.tweets;
      }, function(error) {
        console.log('nooo');
      });
  }
}]);
