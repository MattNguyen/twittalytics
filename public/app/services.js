var services = angular.module('twittalytics.services', ['config']);

services.factory('RecentStatuses', ['$http', 'API_URL', function($http, API_URL) {
  var RecentStatuses = function(data) { angular.extend(this, data) };

  RecentStatuses.get = function(username) {
    return $http.get(API_URL + 'users/' + username + '/recent_statuses');
  };

  return RecentStatuses;
}])

services.factory('CommonFriends', ['$http', function($http) {
  var CommonFriends = function(data) { angular.extend(this, data) };

  CommonFriends = function(username1, username2) {
    var url = API_URL + 'users/common_friends?username1=' + username1 + '&username2=' + username2;
    return $http.get(url);
  };

  return CommonFriends;
}])
