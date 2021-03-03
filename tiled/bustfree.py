from tiled import *

class Example(Plugin):
    @classmethod
    def nameFilter(cls):
        return "Bust Free! levels (*.lvl)"

    @classmethod
    def shortName(cls):
        return "bustfree"

    @classmethod
    def write(cls, tileMap, fileName):
        with open(fileName, 'wb') as fileHandle:
            assert tileMap.layerCount() == 1
            layer = tileLayerAt(tileMap, 0)
            assert layer.width() == 16
            assert layer.height() == 16
            for y in range(layer.height() // 2):
                rowTiles = []
                for x in range(layer.width()):
                    top = layer.cellAt(x, y * 2).tile()
                    bottom = layer.cellAt(x, y * 2 + 1).tile()
                    assert top
                    assert bottom
                    rowTiles.append(top.id() << 4 | bottom.id())
                fileHandle.write(bytes(rowTiles))

        return True
