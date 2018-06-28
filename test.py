import packit

def test():
    packer = packit.packer_Packer('.vscode', 'mypackage')
    packer.pack()
    unpacker = packit.packer_Unpacker('mypackage')
    print(unpacker.unpack('.vscode/launch.json').toHex())
    unpacker.unpackAll('./test')

if __name__ == '__main__':
    test()
