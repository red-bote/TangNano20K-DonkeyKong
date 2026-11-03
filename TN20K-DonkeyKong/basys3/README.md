# Donkey Kong - Digilent Basys 3

Donkey Kong (© 1981 Nintendo Co., Ltd.), FPGA core by Katsumi Degawa, VHDL translation by
d18c7db, Tang Nano 20K port by pinballwiz.org
(<https://github.com/pinballwizz/TangNano20K-DonkeyKong>), built here for the Digilent
Basys 3 (Artix-7 `xc7a35tcpg236-1`).

## Hardware

- Digilent Basys 3.
- VGA monitor (31 kHz), or a 15 kHz TV/CRT (sw13, not tested).
- USB keyboard on the Basys 3 USB-HID host port.
- Optional: Atari-style joystick on Pmod JA, Digilent PmodAMP2 on Pmod JXADC.

## Build

Requirements:

- Vivado 2020.2, gcc, make, unzip, python3, openFPGALoader.
- Romset `dkong.zip`, supplied by the user. Roms are not part of this repository.
- Optional: MAME sample set `samples/dkong.zip` (run01-03, jump, dkstomp), see Sound.

```
make roms        # compile make_vhdl_prom, unzip ~/roms/dkong.zip, generate PROM VHDL
make bitstream   # Vivado batch build of basys3/dkong_basys3.xpr
make load        # program the Basys 3 (SRAM), building first if the bitstream is outdated
make clean       # remove roms, PROM VHDL and Vivado outputs
```

- `ROMDIR=<dir>` or `ROMZIP=<zip>` selects the romset, `SAMPLEZIP=<zip>` the sample set
  (default `ROMDIR/samples/dkong.zip`).
- `VIVADO=<path>` selects the Vivado binary.

## IO

| Input           | Function                                      |
|-----------------|-----------------------------------------------|
| Arrow keys      | move                                          |
| Left Ctrl       | jump                                          |
| 1 / 2           | start 1 player / 2 players                    |
| 5               | coin                                          |
| btnU, btnD      | coin                                          |
| btnL / btnR     | start 1 player / 2 players                    |
| btnC            | reset                                         |
| JA 1/2/3/4/7    | joystick right/left/down/up/jump (active low) |
| sw0-sw7         | DIP switches (down = default, see below)      |
| sw13 down       | 31 kHz VGA                                    |
| sw13 up         | 15 kHz TV, composite sync on HS (not tested)  |
| sw14 up         | PmodAMP2 gain                                 |
| sw15 up         | PmodAMP2 shutdown (mute)                      |

DIP switches (switch up inverts the default bit):

| Bits | Setting | Default         |
|------|---------|-----------------|
| 1:0  | lives   | 3               |
| 3:2  | bonus   | 7000            |
| 6:4  | coinage | 1 coin 1 credit |
| 7    | cabinet | upright         |

## Resource use

To be recorded after the next build (gaz68 sample player, re-authored sample ROM).

## Core changes for the Basys 3 port

Changes to the core files in `src/dkong/` (shared with the Tang Nano 20K project):

- DIP switch input, native video and sound source outputs of `dkong_main` for the Basys 3
  top. Unconnected in the Tang Nano 20K top, defaults keep its settings.
- Vivado elaboration error: colour PROM data port connected in full (`dkong_vram.vhd`).
- Vivado synthesis error: scan doubler `scanlines` input through a signal
  (`dkong_main.vhd`).
- Re-authored sample ROM: address width and slot addresses of the core sample player
  (`dkong_main.vhd`, `dkong_wav_sound.vhd`), see Sound.
- Sound: `dkong_main` generic `SND_EXT` (1 in both tops) selects the gaz68 sample player
  (new `dkong_wav_gaz68.v`, `dkongjr_wav_dma.v`) in place of the core sample player.

## Sound

Walk, jump and stomp are played from samples in place of the original board's analog
sound circuits. `tools/dk_wave.bin` (8-bit, 11,025 Hz) holds the three walk sounds run01,
run02, run03, stomp and jump of MAME's former `dkong` sample set (2004 set, separate from
the `dkong.zip` ROM set). `make roms` re-authors it from `samples/dkong.zip` when present,
else uses the tracked file, and writes `proms/snd/dkong_wav.vhd`. The upstream file held
run03 only.

Both builds (`SND_EXT => 1`) play them on three channels of the sample player of the
gaz68 MiSTer core (<https://github.com/gaz68/Arcade-DonkeyKongJunior_MiSTer>), as the
Donkey Kong Jr. Basys 3 port: walk, jump and stomp overlap, walk rotates over run01-03 in
MAME's order.

Known differences from the arcade board (TKG4-13 CPU board schematic, MAME discrete
sound model):

- The board starts each sound on the sound request (latch bit 0 to 1). The sample player
  starts it when the request ends (1 to 0), about 50 ms later, as the upstream core.
- Power-on: the board plays jump and stomp once (their envelope capacitors start empty),
  MAME emulates this. The sample player plays walk, jump and stomp after every reset
  (power-on and btnC), a side effect of its trigger detection.
- Samples are fixed recordings: no variation per trigger, retriggers restart the sample.
- The sound CPU output has no decay envelope (the board's DAC-08 discharge circuit).

## Third-party additions

| File                                        | Function                   | Author  |
|---------------------------------------------|----------------------------|---------|
| `tools/tools_prom_src/src/make_vhdl_prom.c` | PROM-to-VHDL converter     | darfpga |
| `src/dkong/dkongjr_wav_dma.v`               | sample player              | gaz68   |
| `tools/dk_wave.bin` (re-authored)           | walk, jump, stomp samples  | MAME    |

- `make_vhdl_prom.c`: unmodified, from <https://github.com/pinballwizz/DE2-Xevious>
  (commit `a5d9eed`).
- `dkongjr_wav_dma.v`: `dkongjr_wav_sound.v` of that core (commit `c38f456`), module
  renamed, volume multiply optional (off, no DSP), as in the Donkey Kong Jr. port.
- `dk_wave.bin`: MAME `dkong` sample set dated 2004-09-24, unmodified sample data, new
  layout. Source used: <https://github.com/douglaslassance/mame-setup> `samples/dkong.zip`
  (SHA-256 `28949f4b...625725`). `make_dkong_samples.py` checks each WAV's SHA-256 and
  warns on a different set.

## License

- The additions and changes made for the Basys 3 port are MIT licensed.
- Core files (`src/dkong/*.vhd`): as stated in their headers, (c) 2012 d18c7db, GNU
  General Public License version 3 or later, originally by Katsumi Degawa in Verilog.
- Other code keeps the terms stated in its files. `make_vhdl_prom.c`, `dkongjr_wav_dma.v`
  and the sample data state no license.
- Roms and anything generated from them (PROM VHDL, bitstreams) are not distributed.
