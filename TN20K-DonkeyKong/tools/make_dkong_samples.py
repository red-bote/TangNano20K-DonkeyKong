#!/usr/bin/env python3
# Build the sample ROM image tools/dk_wave.bin from the MAME dkong sample WAVs
# (re-authored layout of the Basys 3 port, read by both builds through
# proms/snd/dkong_wav.vhd).
#   make_dkong_samples.py <wav dir> <output .bin>
# Slots (padded with 0x80, WAVs cut to the slot size):
#   0x0000 run01, 0x0800 run02, 0x1000 run03, 0x1800 dkstomp, 0x3000 jump
# The WAVs must be 8-bit mono PCM at 11025 Hz.
# Source of the tracked dk_wave.bin: MAME dkong sample set dated 2004-09-24, e.g.
#   https://media.githubusercontent.com/media/douglaslassance/mame-setup/main/samples/dkong.zip
#   (zip SHA-256 28949f4bb14d1e1be1e6a268a5c24102af3757ee75cec23e7310f0bb49625725)
# Each WAV is checked against the SHA-256 below. A different set is used with a warning
# (dk_wave.bin then differs from the tracked file).
import hashlib
import os
import struct
import sys

SLOTS = [
    ("run01.wav", 0x0000, 0x0800),
    ("run02.wav", 0x0800, 0x0800),
    ("run03.wav", 0x1000, 0x0800),
    ("dkstomp.wav", 0x1800, 0x1800),
    ("jump.wav", 0x3000, 0x2000),
]
SIZE = 0x5000

SHA256 = {
    "run01.wav": "dcefa9a1cfc2fd108a1a3b5e5fb8e58d549c0c5ff2beda318da50d58adbfa536",
    "run02.wav": "89722781d726580aca4a087dee779fedfcaef42dbd1ceeefe5a5286a687aac0c",
    "run03.wav": "bed5928abaf6df76fa8e03f46ec8e2e2c18b60aa513f3561c5272afcc9d4406a",
    "dkstomp.wav": "9e794b68ad97f1ca9f0ac1cea8345695bd6b524c2e60b9afe4c4584c0faa9f4f",
    "jump.wav": "bc7748ddbae5497a5c372ddcf1975d510f73af12a2ac8843405c5ecec556468e",
}


def read_wav(path):
    with open(path, "rb") as f:
        d = f.read()
    name = os.path.basename(path)
    if hashlib.sha256(d).hexdigest() != SHA256.get(name):
        print("warning: %s differs from the 2004 MAME sample set (SHA-256)" % name)
    if d[0:4] != b"RIFF" or d[8:12] != b"WAVE":
        sys.exit("error: not a WAV file: %s" % path)
    pos = 12
    fmt = None
    while pos + 8 <= len(d):
        cid = d[pos:pos + 4]
        size = struct.unpack("<I", d[pos + 4:pos + 8])[0]
        body = d[pos + 8:pos + 8 + size]
        if cid == b"fmt ":
            fmt = struct.unpack("<HHIIHH", body[:16])
        elif cid == b"data":
            if fmt is None:
                sys.exit("error: data before fmt chunk: %s" % path)
            tag, ch, rate, _, _, bits = fmt
            if (tag, ch, rate, bits) != (1, 1, 11025, 8):
                sys.exit("error: %s: need 8-bit mono PCM 11025 Hz, got "
                         "tag %d, %d ch, %d Hz, %d bit" % (path, tag, ch, rate, bits))
            return body
        pos += 8 + size + (size & 1)
    sys.exit("error: no data chunk: %s" % path)


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: make_dkong_samples.py <wav dir> <output .bin>")
    wav_dir, out = sys.argv[1], sys.argv[2]
    rom = bytearray([0x80] * SIZE)
    for name, base, size in SLOTS:
        data = read_wav(os.path.join(wav_dir, name))[:size]
        rom[base:base + len(data)] = data
        print("%-12s 0x%04X  %5d of %5d bytes" % (name, base, len(data), size))
    with open(out, "wb") as f:
        f.write(rom)


if __name__ == "__main__":
    main()
