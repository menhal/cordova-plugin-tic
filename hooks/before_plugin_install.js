
module.exports = function(ctx){


    console.log("正在拷贝资源文件....");

    // This hook copies resource files to appropriate platform specific locations
    // recommended to be used with the 'after_platform_add' hook
    // based off devgirl's original script from her sample hooks.
    // http://www.mooreds.com/sample-hooks.tar.gz

    // these resource paths need to exist in the root of your Codova project

    // configure all the files to copy from each of the resource paths.
    // key of object is the source file, value is the destination location.
    // the directory/file structure used closely mirrors how the resources
    // are stored in each platform

    var iosFilesToCopy = [
        "src/ios/Images.xcassets/",
    ];

    // required node modules
    var fs = require('fs');
    var path = require('path');
    var ncp = require('ncp').ncp;
    var rootdir = ctx.opts.projectRoot;
    var pluginRootDir = ctx.opts.plugin.dir;

    // retrieve the iOS project directory name
    var xmlFile = path.join(rootdir, 'config.xml');
    var configData = fs.readFileSync(xmlFile, 'utf8');
    var nameStart = (configData.indexOf('<name>')+6);
    var nameEnd = configData.indexOf('</name>');
    var iosProjDir = configData.slice(nameStart, nameEnd);

    // configure ios platform resource path
    var platformIosPath = 'platforms/ios/' + iosProjDir + '/Images.xcassets/';

    console.log(platformIosPath);

    // determine platform to copy to
    filesToCopy(iosFilesToCopy, 'ios');

    // function that copies resource files to choosen platform
    function filesToCopy(obj, platform) {
    var srcFile, destFile, destDir;

        Object.keys(obj).forEach(function(key) {
            var filename = path.basename(obj[key]);
            srcFile = path.join(pluginRootDir, obj[key]);
            destFile = path.join(rootdir, platformIosPath, filename);

            console.log('copying ' + srcFile + ' to ' + destFile);
            destDir = path.dirname(destFile);
            if (fs.existsSync(srcFile) && fs.existsSync(destDir)) {
                ncp(srcFile, destDir);
            }
        });
    }

}