var exec = require('cordova/exec');
    
var Tic = {

    join: function (args, onSuccess, onError) {
        if (!args) return;
        exec(onSuccess, onError, "Tic", "join", [args]);
    }

};

module.exports = Tic;
