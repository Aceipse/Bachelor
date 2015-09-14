﻿//Directive for capturing enter key in angular
//Found at: http://stackoverflow.com/questions/28851893/angularjs-textaera-enter-key-submit-form-with-autocomplete
app.directive('ngEnter', function () {
    return function (scope, element, attrs) {
        element.bind("keydown", function (e) {
            //Check that enter key is hit and that shift key is not(shift to add row to message)
            if (e.which === 13&& !window.event.shiftKey) {
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
        var getChatMessages = function() {
            $http.post(configs.restHostName + '/Chat/GetAllByRoomId', { roomId: MyRoomIdFromViewBag }).then(function (response) {
                $scope.ChatMessages = response.data;
            });
        };
        getChatMessages();
        $scope.userIsHost = false;
        $scope.SpecificQuestionShown = false;
        $scope.QuestionTypes = [{ name: 'Boolean Question', val: 'BooleanQuestion' }, { name: 'Textual Question', val: 'TextualQuestion' }];

        $scope.ResponseOptions = [{ id:0, val: undefined }, { id: 1, val: undefined }];
       
        
        
        //function for showing a specific question
        $scope.ShowSpecificQuestion = function (question) {
            $scope.ToggleShowQuestionTables();
            $scope.SpecificQuestion = question;
        }
        $scope.ToggleShowQuestionTables = function () {
            $scope.SpecificQuestionShown = !$scope.SpecificQuestionShown;
        }

        //Function for creating a question
        $scope.postQuestion = function () {

            var newResponses = "";
            for (var i = 0; i < $scope.ResponseOptions.length; i++) {
                if (i != $scope.ResponseOptions.length-1) {
                    newResponses = newResponses + $scope.ResponseOptions[i].val + ',';
                } else {
                    newResponses = newResponses + $scope.ResponseOptions[i].val;
                }
                
            }
            //Make get request for json object conversion
            $http.post('/Room/toJsonQuestion', { CreatedBy: $window.userId, RoomId: MyRoomIdFromViewBag, Downvotes: 0, Image: $scope.questionImage.base64, Upvotes: 0, QuestionText: $scope.QuestionText, ResponseOptions: newResponses, CreationTimestamp: Date.now(), ExpireTimestamp: $scope.ExpirationTime, QuetionsType: $scope.QuestionType }).
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

