# Donkey Kong - Digilent Basys 3

Donkey Kong (1981 Nintendo), FPGA core by Katsumi Degawa, VHDL translation by d18c7db,
based on Tang Nano 20K port by pinballwiz.org
(<https://github.com/pinballwizz/TangNano20K-DonkeyKong>).

## Hardware

- Digilent Basys 3 (Artix-7 `xc7a35tcpg236-1`).
- VGA monitor (31 kHz), or a 15 kHz TV/CRT (sw13, not tested).
- USB keyboard on the Basys 3 USB-HID host port.
- Optional: Atari-style joystick on Pmod JA, Digilent PmodAMP2 on Pmod JXADC.

## Build

Requirements:

- Vivado 2020.2, gcc, make, unzip, python3, openFPGALoader.
- Romset `dkong.zip`.
- Optional: MAME sample set `samples/dkong.zip` (run01-03, jump, dkstomp), see Sound.

```
make roms        # compile make_vhdl_prom, unzip ~/roms/dkong.zip, generate PROM VHDL
make bitstream   # Vivado batch build of basys3/dkong_basys3.xpr
make load        # program the xc7 in JTAG mode (jumper JP1 in the JTAG position)
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
| sw10 up         | sound CPU decay off (see Sound)               |
| sw11 up         | low-pass filter off (see Sound)               |
| sw12            | reserved                                      |
| sw13 down       | 31 kHz VGA                                    |
| sw13 up         | 15 kHz TV, composite sync on HS (not tested)  |
| sw14 up         | scanlines, alternate lines at 50 %, 31 kHz    |
| sw15 up         | audio off (PmodAMP2 shutdown)                 |

DIP switches (switch up inverts the default bit):

| Bits | Setting | Default         |
|------|---------|-----------------|
| 1:0  | lives   | 3               |
| 3:2  | bonus   | 7000            |
| 6:4  | coinage | 1 coin 1 credit |
| 7    | cabinet | upright         |

## Resource use

From a Vivado 2020.2 build:

| Resource  | Used       | Util.                          |
|-----------|------------|--------------------------------|
| LUTs      | 3337       | 16.04%                         |
| Registers | 1350       | 3.25%                          |
| Block RAM | 19 tiles   | 38.00%                         |
| DSPs      | 0          | 0.00%                          |
| Clock     | 24.576 MHz | WNS +15.453 ns, WHS +0.080 ns  |

## Core changes for the Basys 3 port

Changes to the core files in `src/dkong/` (shared with the Tang Nano 20K project):

- DIP switch input, native video and sound source outputs of `dkong_main` for the Basys 3
  top.
- Vivado elaboration error: colour PROM data port connected in full (`dkong_vram.vhd`).
- Vivado synthesis error: scan doubler `scanlines` input through a signal
  (`dkong_main.vhd`).
- Re-authored sample ROM: address width and slot addresses of the core sample player
  (`dkong_main.vhd`, `dkong_wav_sound.vhd`), see Sound.
- Sound: `dkong_main` generic `SND_EXT` selects `dkong_snd_ext.v`
  (multi-channel sample player, sound CPU decay and low-pass filter, 16-bit mixer) in
  place of the core sample player and mixer. Options `I_SND_OPT` (sw11, sw10).
- Scanlines: `dkong_main` input `I_SCANLINES` to the scan doubler (sw14, 50 %).

## Sound

Walk, jump and stomp are played from samples in place of the original board's analog
sound circuits. `tools/dk_wave.bin` (8-bit, 11,025 Hz) holds the three walk sounds run01,
run02, run03, stomp and jump of MAME's former `dkong` sample set (2004 set, separate from
the `dkong.zip` ROM set). `make roms` re-authors it from `samples/dkong.zip` when present,
else uses the tracked file, and writes `proms/snd/dkong_wav.vhd`. The upstream file held
run03 only.

They play on three channels of the sample player of the gaz68 MiSTer core
(<https://github.com/gaz68/Arcade-DonkeyKongJunior_MiSTer>), as in the Donkey Kong Jr.
Basys 3 version: walk, jump and stomp overlap, walk rotates over run01-03 in MAME's order.

Known differences from the arcade board (TKG4-13 CPU board schematic, MAME discrete
sound model):

- The board starts each sound on the sound request (latch bit 0 to 1). The sample player
  starts it when the request ends (1 to 0), about 50 ms later, as the upstream core.
- Power-on: the board plays jump and stomp once (their envelope capacitors start empty),
  MAME emulates this. The sample player plays walk, jump and stomp after every reset
  (power-on and btnC), a side effect of its trigger detection.
- Samples are fixed recordings: no variation per trigger, retriggers restart the sample.
- Sound CPU decay (the board's DAC-08 discharge circuit) and the low-pass filter follow
  the gaz68 MiSTer core models, as in the Donkey Kong Jr. port. sw11 and sw10 turn them
  off.

## Third-party additions

- `tools/tools_prom_src/src/make_vhdl_prom.c` (darfpga): PROM-to-VHDL converter,
  unmodified, from <https://github.com/pinballwizz/DE2-Xevious>.
- Sound, in `src/dkong/`, from the gaz68 MiSTer core
  <https://github.com/gaz68/Arcade-DonkeyKongJunior_MiSTer>, multiplies kept out of DSP
  blocks:
  - `dkongjr_wav_dma.v` (gaz68): sample player, `dkongjr_wav_sound.v` there, module
    renamed, volume multiply optional (off).
  - `dkongjr_dac.sv` (gaz68): sound CPU decay.
  - `dkongjr_iir_filter.v` (Gregory Hogan, MIT): low-pass filter.
- `tools/dk_wave.bin`: walk, jump and stomp samples from the MAME `dkong` sample set,
  unmodified sample data, new layout, from
  <https://github.com/douglaslassance/mame-setup>. `make_dkong_samples.py` warns on a
  different set.

## License

- The additions and changes made for the Basys 3 port are MIT licensed.
- Core files (`src/dkong/*.vhd`): as stated in their headers, (c) 2012 d18c7db, GNU
  General Public License version 3 or later, originally by Katsumi Degawa in Verilog.
- Other code keeps the terms stated in its files. `make_vhdl_prom.c`, `dkongjr_wav_dma.v`,
  `dkongjr_dac.sv` and the sample data state no license.
- Roms and anything generated from them (PROM VHDL, bitstreams) are not distributed.
