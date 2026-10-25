from bmp import Bitmap
from bmp import LoadBmp
import struct

bmp = LoadBmp('Emulator-Framework-Splashscreen.bmp')
print("Bitmap height: %d, width: %d" % (bmp.height, bmp.width))

with open('splashscreen.bin', "wb") as fout:
    for y in range(bmp.height):
        for x in range(bmp.width):
            fout.write(struct.pack("<B", 0)) # alpha
            fout.write(struct.pack("<B", bmp.GetPx(y, x).r)) # blue
            fout.write(struct.pack("<B", bmp.GetPx(y, x).g)) # green
            fout.write(struct.pack("<B", bmp.GetPx(y, x).b)) # red

