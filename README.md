# Tang Nano 20K - Donkey Kong

Donkey Kong Arcade vhdl code ported to a Tang Nano 20K FPGA Board by PinballWiz.org 2025.  
Works with VGA Monitor. Original code by Katsumi Degawa.

## Basys 3 port

Digilent Basys 3 version on branch `Port-to-Basys-3`: see
[TN20K-DonkeyKong/basys3/README.md](TN20K-DonkeyKong/basys3/README.md).

The port changes core files shared with the Tang Nano 20K project, replaces
`tools/dk_wave.bin` and `proms/snd/dkong_wav.vhd` with a re-authored sample ROM (three
walk sounds) and adds a three-channel sample player, used by both projects. The Tang Nano
20K project builds with the Gowin EDA, but has not been tested on Tang Nano 20K hardware.
