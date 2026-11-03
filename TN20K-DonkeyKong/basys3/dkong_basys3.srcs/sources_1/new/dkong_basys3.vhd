---------------------------------------------------------------------------------
-- Basys 3 top level for Donkey Kong
-- Source: TN20K-DonkeyKong.vhd by pinballwiz.org
--   (https://github.com/pinballwizz/TangNano20K-DonkeyKong). See that file for its
--   history.
-- Core: Katsumi Degawa, VHDL translation by d18c7db
---------------------------------------------------------------------------------
--
-- 11/02/2026: initial Basys 3 release by Red~Bote
--
---------------------------------------------------------------------------------
-- License:
--  - Basys 3 changes: MIT (see LICENSE)
--  - Code from TN20K-DonkeyKong.vhd: no license stated
--  - Core (dkong_*.vhd): GPL-3.0 or later as stated in the file headers (d18c7db)
---------------------------------------------------------------------------------
--
-- Main features:
--  Connections:
--   VGA monitor, 31 kHz (scandoubler). 15 kHz RGB with sw13 up (not tested)
--   USB keyboard on the USB-HID host connector (MAME default keys)
--   Atari-type joystick on Pmod JA, pins 1/2/3/4/7 = right/left/down/up/jump
--   PmodAMP2 with speaker on Pmod JXADC, pins 1/2/4
--  Controls       keyboard       stick          button
--   move          arrows         stick
--   jump          Left Ctrl      fire
--   coin          5                             btnU, btnD
--   start1/2      1, 2                          btnL, btnR
--   reset                                       btnC
--  Switches: sw15 audio off, sw14 gain, sw13 15 kHz RGB, sw0-sw7 DIP
--  DIP bits: lives 1:0, bonus 3:2, coinage 6:4, cabinet 7, switch down = default
--  Sound: walk, jump and stomp samples on three channels (MAME sample set)
--  Clock: 1 MMCM, 24.576 MHz from 100 MHz
--
-- DIP values and other details: see basys3/README.md
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

---------------------------------------------------------------------------------
entity dkong_basys3 is
port(
    clk         : in  std_logic;
    btnC        : in  std_logic;
    btnU        : in  std_logic;
    btnD        : in  std_logic;
    btnL        : in  std_logic;
    btnR        : in  std_logic;
    sw          : in  std_logic_vector(15 downto 0);
    vga_r       : out std_logic_vector(3 downto 0);
    vga_g       : out std_logic_vector(3 downto 0);
    vga_b       : out std_logic_vector(3 downto 0);
    hsync       : out std_logic;
    vsync       : out std_logic;
    ps2_clk     : in  std_logic;
    ps2_dat     : inout std_logic;
    JA          : in  std_logic_vector(4 downto 0);
    JXADC       : out std_logic_vector(3 downto 0);
    led         : out std_logic_vector(15 downto 0)
);
end dkong_basys3;

------------------------------------------------------------------------------
architecture struct of dkong_basys3 is

    signal clk_sys         : std_logic;
    signal locked          : std_logic;
    signal mmcm_reset      : std_logic := '0';
    signal clock_12        : std_logic := '0';
    --
    signal video_r         : std_logic_vector(2 downto 0);
    signal video_g         : std_logic_vector(2 downto 0);
    signal video_b         : std_logic_vector(1 downto 0);
    signal h_sync          : std_logic;
    signal v_sync          : std_logic;
    --
    signal native_r        : std_logic_vector(5 downto 0);
    signal native_g        : std_logic_vector(5 downto 0);
    signal native_b        : std_logic_vector(5 downto 0);
    signal native_hs       : std_logic;
    signal native_vs       : std_logic;
    --
    signal audio           : std_logic;
    --
    signal reset           : std_logic;
    --
    signal kbd_intr        : std_logic;
    signal kbd_scancode    : std_logic_vector(7 downto 0);
    signal joy_BBBBFRLDU   : std_logic_vector(8 downto 0);
    signal ps2_clk_meta    : std_logic;
    signal ps2_clk_s       : std_logic;
    signal ps2_dat_meta    : std_logic;
    signal ps2_dat_s       : std_logic;
    signal kbd_joy         : std_logic_vector(8 downto 0);
    signal btn_meta        : std_logic_vector(3 downto 0);
    signal btn_s           : std_logic_vector(3 downto 0);
    signal stick_meta      : std_logic_vector(4 downto 0);
    signal stick_s         : std_logic_vector(4 downto 0);
    attribute ASYNC_REG    : string;
    attribute ASYNC_REG of btn_meta, btn_s, stick_meta, stick_s : signal is "TRUE";
    attribute ASYNC_REG of ps2_clk_meta, ps2_clk_s, ps2_dat_meta, ps2_dat_s : signal is "TRUE";
    --
    constant CLOCK_FREQ    : integer := 27E6;
    signal counter_clk     : std_logic_vector(25 downto 0);
    signal clock_4hz       : std_logic;
    signal AD              : std_logic_vector(15 downto 0);
    signal dip_sw          : std_logic_vector(7 downto 0);

---------------------------------------------------------------------------
begin

    -- btnC reset, held until the MMCM locks
    reset <= btnC or (not locked);

---------------------------------------------------------------------------
    -- Clock: MMCM 24.576 MHz from the 100 MHz board clock
    clk_wiz_0 : entity work.clk_wiz_0
    port map (
        clk_in1  => clk,
        reset    => mmcm_reset,
        clk_out1 => clk_sys,
        locked   => locked
    );

---------------------------------------------------------------------------
    process(clk_sys)
    begin
        if rising_edge(clk_sys) then
            clock_12 <= not clock_12;
        end if;
    end process;

---------------------------------------------------------------------------
    -- DIP switches: switch up inverts the default bit (upright cabinet)
    dip_sw <= "10000000" xor sw(7 downto 0);

---------------------------------------------------------------------------
    dkong : entity work.dkong_main
    generic map (
        SND_EXT => 1 -- multi-channel sample player (walk run01-03, jump, stomp)
    )
    port map (
        I_CLK_24576M   => clk_sys,
        WB_CLK_12288M  => clock_12,
        I_RESETn       => not reset,
        I_U1           => not joy_BBBBFRLDU(0),    -- P1 up
        I_D1           => not joy_BBBBFRLDU(1),    -- P1 down
        I_L1           => not joy_BBBBFRLDU(2),    -- P1 left
        I_R1           => not joy_BBBBFRLDU(3),    -- P1 right
        I_J1           => not joy_BBBBFRLDU(4),    -- P1 jump
        I_S1           => not joy_BBBBFRLDU(5),    -- P1 start
        I_U2           => not joy_BBBBFRLDU(0),    -- P2 up
        I_D2           => not joy_BBBBFRLDU(1),    -- P2 down
        I_L2           => not joy_BBBBFRLDU(2),    -- P2 left
        I_R2           => not joy_BBBBFRLDU(3),    -- P2 right
        I_J2           => not joy_BBBBFRLDU(4),    -- P2 jump
        I_S2           => not joy_BBBBFRLDU(6),    -- P2 start
        I_C1           => joy_BBBBFRLDU(7),        -- Coin
        O_SOUND_OUT_L  => audio,
        O_SOUND_OUT_R  => open,
        O_VGA_R        => video_r,
        O_VGA_G        => video_g,
        O_VGA_B        => video_b,
        O_VGA_H_SYNCn  => h_sync,
        O_VGA_V_SYNCn  => v_sync,
        O_R            => native_r,
        O_G            => native_g,
        O_B            => native_b,
        O_H_SYNCn      => native_hs,
        O_V_SYNCn      => native_vs,
        I_DIP_SW       => dip_sw,
        AD             => AD
    );

-----------------------------------------------------------------
    -- vga outputs

    -- sw13 down: 31 kHz VGA (scandoubler), up: 15 kHz TV with composite sync on HS
    process(clk_sys)
    begin
        if rising_edge(clk_sys) then
            if sw(13) = '0' then
                vga_r <= video_r & video_r(2);
                vga_g <= video_g & video_g(2);
                vga_b <= video_b & video_b;
                hsync <= h_sync;
                vsync <= v_sync;
            else
                vga_r <= native_r(5 downto 2);
                vga_g <= native_g(5 downto 2);
                vga_b <= native_b(5 downto 2);
                hsync <= native_hs and native_vs;
                vsync <= '1';
            end if;
        end if;
    end process;

-----------------------------------------------------------------
    -- sound: 1-bit DAC output of the core to the PmodAMP2

    -- PmodAMP2

    JXADC(0) <= audio;
    JXADC(1) <= not sw(14); -- PmodAMP2 GAIN (JXADC2), active low: sw14 up = gain
    JXADC(2) <= '0';
    JXADC(3) <= not sw(15); -- PmodAMP2 SHUTD (JXADC4), active low: sw15 up = shut down

-----------------------------------------------------------------
    -- get scancode from keyboard

    process(clk_sys)
    begin
        if rising_edge(clk_sys) then
            ps2_clk_meta <= ps2_clk;
            ps2_clk_s    <= ps2_clk_meta;
            ps2_dat_meta <= ps2_dat;
            ps2_dat_s    <= ps2_dat_meta;
        end if;
    end process;

    keyboard : entity work.io_ps2_keyboard
    port map (
        clk       => clk_sys,
        kbd_clk   => ps2_clk_s,
        kbd_dat   => ps2_dat_s,
        interrupt => kbd_intr,
        scancode  => kbd_scancode
    );

-----------------------------------------------------------------
    -- translate scancode to joystick

    joystick : entity work.kbd_joystick
    port map (
        clk           => clk_sys,
        kbdint        => kbd_intr,
        kbdscancode   => std_logic_vector(kbd_scancode),
        joy_BBBBFRLDU => kbd_joy
    );

-----------------------------------------------------------------
    -- buttons and JA joystick (active low, pins 1/2/3/4/7 = R/L/D/U/fire):
    -- 2-FF synchronizers, ORed with the keyboard
    process(clk_sys)
    begin
        if rising_edge(clk_sys) then
            btn_meta   <= btnU & btnD & btnL & btnR;
            btn_s      <= btn_meta;
            stick_meta <= JA;
            stick_s    <= stick_meta;
        end if;
    end process;

    joy_BBBBFRLDU(0) <= kbd_joy(0) or not stick_s(3); -- up
    joy_BBBBFRLDU(1) <= kbd_joy(1) or not stick_s(2); -- down
    joy_BBBBFRLDU(2) <= kbd_joy(2) or not stick_s(1); -- left
    joy_BBBBFRLDU(3) <= kbd_joy(3) or not stick_s(0); -- right
    joy_BBBBFRLDU(4) <= kbd_joy(4) or not stick_s(4); -- jump
    joy_BBBBFRLDU(5) <= kbd_joy(5) or btn_s(1); -- start 1: btnL
    joy_BBBBFRLDU(6) <= kbd_joy(6) or btn_s(0); -- start 2: btnR
    joy_BBBBFRLDU(7) <= kbd_joy(7) or btn_s(3) or btn_s(2); -- coin: btnU, btnD
    joy_BBBBFRLDU(8) <= kbd_joy(8);

-----------------------------------------------------------------
    -- debug

    led(15 downto 6) <= (others => '0');

    process(reset, clk_sys)
    begin
        if reset = '1' then
            clock_4hz <= '0';
            counter_clk <= (others => '0');
        else
            if rising_edge(clk_sys) then
                if counter_clk = CLOCK_FREQ/8 then
                    counter_clk <= (others => '0');
                    clock_4hz <= not clock_4hz;
                    led(5 downto 0) <= not AD(9 downto 4);
                else
                    counter_clk <= counter_clk + 1;
                end if;
            end if;
        end if;
    end process;

------------------------------------------------------------------------
end struct;
