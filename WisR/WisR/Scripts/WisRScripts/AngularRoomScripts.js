﻿//Directive for capturing enter key in angular
//Found at: http://stackoverflow.com/questions/28851893/angularjs-textaera-enter-key-submit-form-with-autocomplete
app.directive('ngEnter', function () {
    return function (scope, element, attrs) {
        element.bind("keydown", function (e) {
            //Check that enter key is hit and that shift key is not(shift to add row to message)
            if (e.which === 13 && !window.event.shiftKey) {
                scope.$apply(function () {
                    scope.$eval(attrs.ngEnter, { 'e': e });
                });
                e.preventDefault();
            }
        });
    };
});

app.controller("RoomController", [
    '$scope', '$http', 'configs', '$window', function ($scope, $http, configs, $window) {
        //Connect to SignalR hub and wait for chat messages
        $(function () {
            // Declare a proxy to reference the hub. 
            var hub = $.connection.chatHub;
            // Create a function that the hub can call to broadcast messages.
            hub.client.broadcastChatMessage = function (chatMessageToAdd) {
                $scope.ChatMessages.push(JSON.parse(chatMessageToAdd));
                $scope.$apply();
            };
            $.connection.hub.start();
        });
        //Do the same for newly added questions
        $(function () {
            // Declare a proxy to reference the hub. 
            var hub = $.connection.questionHub;
            // Create a function that the hub can call to broadcast messages.
            hub.client.broadcastQuestion = function (questionToAdd) {
                $scope.Questions.push(JSON.parse(questionToAdd));
                $scope.$apply();
            };
            $.connection.hub.start();
        });
        //watch the window.userId variable
        $scope.$watch(
                function () {
                    return $window.userId;
                }, function (n, o) {
                    $scope.userId = n;
                }
);
        //watch the questionImage.filesize variable
        $scope.$watch(
                function () {
                    return $scope.questionImage;
                }, function (n, o) {
                    if (n != undefined) {
                        if (n.filesize > 1049000) {
                            alert("File is too big");
                            $scope.questionImage.base64 = "R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==";
                        }

                    }

                }
);

        //Get all questions
        var getQuestions = function () {
            $http.get(configs.restHostName + '/Question/GetAll').then(function (response) {
                $scope.Questions = response.data;
            });
        };
        getQuestions();

        //Get information about this specific room
        //Get room info
        var getRoom = function () {
            $http.post(configs.restHostName + '/Room/GetById', { id: MyRoomIdFromViewBag }).then(function (response) {
                $scope.CurrentRoom = response.data;
            });
        };
        getRoom();
        var getChatMessages = function () {
            $http.post(configs.restHostName + '/Chat/GetAllByRoomId', { roomId: MyRoomIdFromViewBag }).then(function (response) {
                $scope.ChatMessages = response.data;
            });
        };
        getChatMessages();
        $scope.userIsHost = false;
        $scope.SpecificQuestionShown = false;
        $scope.QuestionTypes = [{ name: 'Boolean Question', val: 'BooleanQuestion' }, { name: 'Textual Question', val: 'TextualQuestion' }];
        $scope.ActiveUsers = [];

        $scope.ResponseOptions = [{ id: 0, val: undefined }, { id: 1, val: undefined }];
        //Function for retrieving userName by an id
        var getAllUsers = function () {
                $http.get(configs.restHostName + '/User/GetAll').then(function(result) {
                    $scope.ActiveUsers = result.data;
                });
        }
        getAllUsers();

        $scope.GetUsernameById=function(userId) {
            var result = $.grep($scope.ActiveUsers, function (e) { return e._id == userId; });
            if (userId == undefined)
                return "Undefined name";
            return result[0].DisplayName;
        }


        //function for showing a specific question
        $scope.ShowSpecificQuestion = function (question) {
            $scope.ToggleShowQuestionTables();
            $scope.SpecificQuestion = question;
        }
        $scope.ToggleShowQuestionTables = function () {
            $scope.SpecificQuestionShown = !$scope.SpecificQuestionShown;
        }

        

        //Get precentage for loading bar
        $scope.getPercentage = function () {
            if ($scope.SpecificQuestion != undefined) {
                $scope.timerOverflow = false;
                $scope.$apply(function () {
                    var nominater = Date.now() - parseInt($scope.SpecificQuestion.CreationTimestamp);
                    var denominater = parseInt($scope.SpecificQuestion.ExpireTimestamp) - parseInt($scope.SpecificQuestion.CreationTimestamp);
                    $scope.precentage = (nominater / denominater) * 100;
                    var timeLeftInmSec = parseInt($scope.SpecificQuestion.ExpireTimestamp) - Date.now();
                    var hours = (parseInt(timeLeftInmSec / 3600000) + "").length == 1 ? "0" + parseInt(timeLeftInmSec / 3600000) : parseInt(timeLeftInmSec / 3600000);
                    var min = (parseInt((timeLeftInmSec % 3600000) / 60000) + "").length == 1 ? "0" + parseInt((timeLeftInmSec % 3600000) / 60000) : parseInt((timeLeftInmSec % 3600000) / 60000);
                    var sec = (parseInt(((timeLeftInmSec % 3600000) % 60000) / 1000) + "").length == 1 ? "0" + parseInt(((timeLeftInmSec % 3600000) % 60000) / 1000) : parseInt(((timeLeftInmSec % 3600000) % 60000) / 1000);
                    $scope.timeLeft = (hours + ":" + min + ":" + sec).indexOf("-") >-1 ? "The time has run out!" : hours + ":" + min + ":" + sec;
                    if ($scope.precentage>100) {
                        $scope.timerOverflow = true;
                    }
                }
                )
            }
        }

        setInterval($scope.getPercentage, 1000);
        //adds answer to specificQuestion
        $scope.AddAnswer = function () {
            $scope.SpecificQuestion.Result.push($scope.answerChoosen);
           
            var newResponses = "";
            for (var i = 0; i < $scope.SpecificQuestion.ResponseOptions.length; i++) {
                if (i != $scope.SpecificQuestion.ResponseOptions.length - 1) {
                    newResponses = newResponses + $scope.SpecificQuestion.ResponseOptions[i].Value + ',';
                } else {
                    newResponses = newResponses + $scope.SpecificQuestion.ResponseOptions[i].Value;
                }
        } 

            var newResults = "";
            for (var i = 0; i < $scope.SpecificQuestion.Result.length; i++) {
                if (i != $scope.SpecificQuestion.Result.length - 1) {
                    newResults = newResults + $scope.SpecificQuestion.Result[i].Value + "-" + $window.userId + ',';
                } else {
                    newResults = newResults + $scope.SpecificQuestion.Result[i].Value+"-" + $window.userId;
                }
            }

            //Make get request for json object conversion
            $http.post('/Room/toJsonQuestion', {CreatedBy: $scope.SpecificQuestion.CreatedById, RoomId: $scope.SpecificQuestion.RoomId, Downvotes: $scope.SpecificQuestion.Downvotes, Image: $scope.SpecificQuestion.Img, Upvotes: $scope.SpecificQuestion.Upvotes, QuestionText: $scope.SpecificQuestion.QuestionText, ResponseOptions: newResponses, CreationTimestamp: $scope.SpecificQuestion.CreationTimestamp, ExpireTimestamp: $scope.SpecificQuestion.ExpireTimestamp, QuestionResult: newResults, QuetionsType: $scope.SpecificQuestion._t
            }).
                then(function (response) {
                    //Use response to send to REST API
                    $http.post(configs.restHostName + '/Question/UpdateQuestionResponse', { question: JSON.stringify(response.data), type: $scope.SpecificQuestion._t, id: $scope.SpecificQuestion._id });
                });
        }
        //Function for creating a question
        $scope.postQuestion = function () {

            var newResponses = "";
            for (var i = 0; i < $scope.ResponseOptions.length; i++) {
                if (i != $scope.ResponseOptions.length - 1) {
                    newResponses = newResponses + $scope.ResponseOptions[i].val + ',';
                } else {
                    newResponses = newResponses + $scope.ResponseOptions[i].val;
                }

            }
            //Make get request for json object conversion
            $http.post('/Room/toJsonQuestion', { CreatedBy: $window.userId, RoomId: MyRoomIdFromViewBag, Downvotes: 0, Image: $scope.questionImage != undefined ? $scope.questionImage.base64 : "R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==", Upvotes: 0, QuestionText: $scope.QuestionText, ResponseOptions: newResponses, ExpireTimestamp: $scope.ExpirationTime, QuetionsType: $scope.QuestionType }).
                then(function (response) {
                    //Use response to send to REST API
                    $http.post(configs.restHostName + '/Question/CreateQuestion', { question: JSON.stringify(response.data), type: $scope.QuestionType.val });
                });
        }

        //Function for creating a chatMessage
        $scope.postChatMessage = function (message) {
            //Clear text area, so that it is ready for a new message
            $scope.textAreaModel = "";

            //Make get request for json object conversion
            $http.post('/Room/toJsonChatMessage', { userId: window.userId, roomId: MyRoomIdFromViewBag, text: message }).
                then(function (response) {
                    //Use response to send to REST API
                    $http.post(configs.restHostName + '/Chat/CreateChatMessage', { ChatMessage: JSON.stringify(response.data) });
                });
        }
    }
]);

