var exec = require('cordova/exec');
    
var Tic = {

    init: function (args, onSuccess, onError) {
        if (!args) return;
        exec(onSuccess, onError, "Tic", "init", [args]);
    },
    
    join: function (args, onSuccess, onError) {
        if (!args) return;
        exec(onSuccess, onError, "Tic", "join", [args]);
    }

};

module.exports = Tic;
