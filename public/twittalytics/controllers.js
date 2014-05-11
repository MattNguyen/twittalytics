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
