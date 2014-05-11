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
