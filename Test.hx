package;

import packer.Packer;

class Test {
    static function main() {
        var packer = new Packer('.vscode', 'mypackage');
        // for (fileInfo in packer.filesList) {
        //     var filepath = fileInfo.keys().next();
        //     trace(filepath + ': ' + fileInfo[filepath]);
        // }
        packer.pack();
        var unpacker = new Unpacker('mypackage');
        // sys.io.File.saveBytes('launch.json', unpacker.unpack('.vscode/launch.json'));
        unpacker.unpackAll('./test');
    }
}
