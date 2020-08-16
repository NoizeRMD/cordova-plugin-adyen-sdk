module.exports.readVersion = function(contents) {
    const version = contents.match(/(<widget [\S\s]*?version=")[^"]+("[\S\s]*?>)/gmi)[0];
    return version;
};

module.exports.writeVersion = function(contents, version) {
    return contents.replace(/(<widget [\S\s]*?version=")[^"]+("[\S\s]*?>)/gmi,`$1${ version }$2`);
};
