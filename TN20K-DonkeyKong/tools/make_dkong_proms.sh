#!/bin/bash
# Generate the PROM VHDL from the dkong.zip romset into ../proms/ (port of
# make_dkong_proms.bat):
#   1. compile make_vhdl_prom into tools_prom_src/bin/
#   2. unzip ROMZIP (comma-separated) or ${ROMDIR:-~/roms}/dkong.zip into unzip/
#   3. write the PROM VHDL and the stamp .done into ../proms/
#   4. sample ROM: re-author dk_wave.bin from SAMPLEZIP or
#      ${ROMDIR:-~/roms}/samples/dkong.zip (MAME sample set: run01-03, jump, dkstomp)
#      when present, else keep the tracked dk_wave.bin, then write
#      ../proms/snd/dkong_wav.vhd from it
# make_vhdl_prom names the entity after the output file, so it writes into unzip/ and
# the result is moved.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PROM_DIR="$HERE/../proms"
UNZIP="$HERE/unzip"
TOOL="$HERE/tools_prom_src/bin/make_vhdl_prom"

if [ -n "${ROMZIP:-}" ]; then
    IFS=, read -r -a romzips <<< "$ROMZIP"
else
    romzips=("${ROMDIR:-$HOME/roms}/dkong.zip")
fi
samplezip="${SAMPLEZIP:-${ROMDIR:-$HOME/roms}/samples/dkong.zip}"
for z in "${romzips[@]}"; do
    if [ ! -f "$z" ]; then
        echo "error: romset not found: $z (set ROMDIR or ROMZIP)" >&2
        exit 1
    fi
done

mkdir -p "$(dirname "$TOOL")" "$UNZIP" "$PROM_DIR"
gcc -w "$HERE/tools_prom_src/src/make_vhdl_prom.c" -lm -o "$TOOL"

for z in "${romzips[@]}"; do
    unzip -q -o "$z" -d "$UNZIP"
done
cd "$UNZIP"

prom() {
    "$TOOL" "$1" "$2"
    mv -f "$2" "$PROM_DIR/$2"
}

cat c_5et_g.bin c_5ct_g.bin c_5bt_g.bin c_5at_g.bin > dkong_prog.bin
prom dkong_prog.bin dkong_prog.vhd

prom c-2j.bpr pal1_rom.vhd
prom c-2k.bpr pal2_rom.vhd
prom v-5e.bpr col_rom.vhd

prom v_3pt.bin ROM3P.vhd
prom v_5h_b.bin ROM3N.vhd

prom l_4m_b.bin ROM7C.vhd
prom l_4n_b.bin ROM7D.vhd
prom l_4r_b.bin ROM7E.vhd
prom l_4s_b.bin ROM7F.vhd

# sound CPU ROMs in proms/snd/, as the Tang Nano 20K project expects
prom s_3i_b.bin dkong_cpu1.vhd
prom s_3j_b.bin dkong_cpu2.vhd
mv -f "$PROM_DIR/dkong_cpu1.vhd" "$PROM_DIR/dkong_cpu2.vhd" "$PROM_DIR/snd/"

if [ -f "$samplezip" ]; then
    mkdir -p samples
    unzip -q -o "$samplezip" -d samples
    python3 "$HERE/make_dkong_samples.py" samples "$HERE/dk_wave.bin"
else
    echo "note: $samplezip not found, using the tracked dk_wave.bin"
fi
"$TOOL" "$HERE/dk_wave.bin" dkong_wav.vhd
mv -f dkong_wav.vhd "$PROM_DIR/snd/dkong_wav.vhd"

touch "$PROM_DIR/.done"   # stamp for the Makefile bitstream prerequisite
echo "PROM VHDL in $PROM_DIR:"
ls -1 "$PROM_DIR"
