var exec = require('cordova/exec');

var AdyenCordovaPlugin = function () { };
// This just makes it easier for us to export all of the functions at once.
// All of your plugin functions go below this.
// Note: We are not passing any options in the [] block for this, so make sure you include the empty [] block.

AdyenCordovaPlugin.coolMethod = function (arg0, onSuccess, onError) {
    exec(onSuccess, onError, "AdyenCordovaPlugin", "coolMethod", [arg0]);
};
module.exports = AdyenCordovaPlugin;
