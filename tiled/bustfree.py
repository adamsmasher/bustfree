from tiled import *

class Example(Plugin):
    @classmethod
    def nameFilter(cls):
        return "Bust Free! levels (*.lvl)"

    @classmethod
    def shortName(cls):
        return "bustfree"

    @classmethod
    def getRowTiles(cls, layer):
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
            yield rowTiles

    @classmethod
    def write(cls, tileMap, fileName):
        assert tileMap.layerCount() == 1
:
        rowTiles = cls.getRowTiles(tileLayerAt(tileMap, 0))

        with open(fileName, 'wb') as fileHandle:
            for row in rowTiles:
                fileHandle.write(bytes(row))

        return True
