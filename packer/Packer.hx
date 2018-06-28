package packer;

import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import haxe.Serializer;
import haxe.Unserializer;

class GlobalVars {
    public static var version(default, null) = 0x01;
    public static var trunkSize(default, null) = 4096;
}

class Packer {
    var directory:String;
    public var filesList(default, null) = new List<Map<String, Int>>();
    var dist:String;

    public function new(directory: String, dist: String) {
        if (FileSystem.exists(directory) && FileSystem.isDirectory(directory)) {
            this.directory = directory;
        } else {
            trace('error');
        }
        this.dist = dist;
        this.list();
    }

    function list(?directory) {
        if (directory == null) { directory = this.directory; }
        for (file in FileSystem.readDirectory(directory)) {
            var path = Path.join([directory, file]);
            if (FileSystem.isDirectory(path)) {
                list(path);
            } else {
                var fileInfo = new Map<String, Int>();
                fileInfo[path] = FileSystem.stat(path).size;
                this.filesList.add(fileInfo);
            }
        }

        return this.filesList;
    }

    public function pack() {
        var serializer = new Serializer();
        serializer.serialize(this.filesList);
        var context = serializer.toString();
        var saveFile = File.write(this.dist, true);
        saveFile.writeByte(GlobalVars.version);
        if (context.length > 255) {
            saveFile.writeByte(Math.floor(context.length / 255));
            saveFile.writeByte(context.length % 255);
        } else {
            saveFile.writeByte(0);
            saveFile.writeByte(context.length);
        }
        saveFile.writeString(context);

        for (fileInfo in this.filesList) {
            var filepath = fileInfo.keys().next();
            var readFile = File.read(filepath, true);
            saveFile.write(readFile.readAll(GlobalVars.trunkSize));
            readFile.close();
        }

        saveFile.close();
    }
}

class Unpacker {
    var src:String;
    var filesList = new List<Map<String, Int>>();
    var offset:Int = 3;

    public function new(src:String) {
        if (FileSystem.exists(src) && !FileSystem.isDirectory(src)) {
            this.src = src;
            unserialization();
        }
    }

    function unserialization() {
        var file = File.read(src, true);
        if (Std.parseInt('0x' + file.read(1).toHex()) != GlobalVars.version) return;
        var filesListLength = Std.parseInt('0x' + file.read(1).toHex()) * 255
            + Std.parseInt('0x' + file.read(1).toHex());
        this.offset += filesListLength;
        var filesList = file.read(filesListLength).toString();

        var unserializer = new Unserializer(filesList).unserialize();
        this.filesList = unserializer;
    }

    public function list() {
        for (fileInfo in this.filesList) {
            var filepath = fileInfo.keys().next();
            trace('file: $filepath  ' + fileInfo[filepath]);
        }
    }

    public function unpack(picked:String) {
        var offset:Int = this.offset;
        for (fileInfo in this.filesList) {
            var filepath = fileInfo.keys().next();
            var len = fileInfo[filepath];
            if (picked == filepath) {
                var file = File.read(this.src, true);
                var content = file.readAll(GlobalVars.trunkSize).sub(offset, len);
                file.close();
                return content;
            } else {
                offset += len;
            }
        }
        return null;
    }

    public function unpackAll(dist:String) {
        if (FileSystem.exists(dist) && !FileSystem.isDirectory(dist)) return;

        var offset:Int = this.offset;
        var fileRead = File.read(src, true);
        var contents = fileRead.readAll(GlobalVars.trunkSize);
        for (fileInfo in this.filesList) {
            var filepath = fileInfo.keys().next();
            var path = Path.join([dist, filepath]);
            if (!FileSystem.exists(Path.directory(path))) {
                FileSystem.createDirectory(Path.directory(path));
            }
            var len = fileInfo[filepath];
            File.saveBytes(path, contents.sub(offset, len));
            offset += len;
        }
        fileRead.close();
    }
}
