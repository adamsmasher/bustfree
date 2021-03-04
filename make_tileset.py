import png
import sys
from itertools import chain, islice, product, zip_longest

def grouper(iterable, n, fillvalue=None):
    "Collect data into fixed-length chunks or blocks"
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx"
    args = [iter(iterable)] * n
    return zip_longest(*args, fillvalue=fillvalue)

def flatten(list_of_lists):
    "Flatten one level of nesting"
    return chain.from_iterable(list_of_lists)

def take(n, iterable):
    "Return first n items of the iterable as a list"
    return list(islice(iterable, n))

empty_brick = [[0xff] * 32] * 4

def main(args):
    in_file, out_file = args[1:]
    png_reader = png.Reader(filename=in_file)
    width, height, rows, info = png_reader.read()
    print(info)

    assert width == 8
    assert height % 4 == 0

    bricks = list(grouper(rows, 4))
    bricks += [empty_brick] * (16 - len(bricks))

    w = png.Writer(width=8, height=128*8, alpha=True, greyscale=False)
    with open(out_file, 'wb') as f:
        brick_combinations = product(bricks, repeat=2)
        bricks = take(256, flatten(brick_combinations))
        brick_rows = flatten(bricks)
        w.write(f, brick_rows)

if __name__ == '__main__':
    main(sys.argv)
