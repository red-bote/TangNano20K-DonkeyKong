---------------------------------------------------------------------------------
-- Vivado RAM for the Basys 3 project
--
-- Replaces the Gowin RAM IP (Gowin_SP, Gowin_SP2, Gowin_SP3, Gowin_SP5, Gowin_DPB)
-- used by the core, with the same entity names and ports. One-cycle read, output held
-- during a write (Gowin READ_MODE 0, WRITE_MODE 00). reset and oce are not used.
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xilinx_sp_ram is
    generic (
        AW : integer := 8;
        DW : integer := 8
    );
    port (
        dout : out std_logic_vector(DW-1 downto 0);
        clk  : in  std_logic;
        ce   : in  std_logic;
        wre  : in  std_logic;
        ad   : in  std_logic_vector(AW-1 downto 0);
        din  : in  std_logic_vector(DW-1 downto 0)
    );
end xilinx_sp_ram;

architecture rtl of xilinx_sp_ram is
    type mem_t is array(0 to 2**AW-1) of std_logic_vector(DW-1 downto 0);
    signal mem : mem_t := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if ce = '1' then
                if wre = '1' then
                    mem(to_integer(unsigned(ad))) <= din;
                else
                    dout <= mem(to_integer(unsigned(ad)));
                end if;
            end if;
        end if;
    end process;
end rtl;

---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity Gowin_SP is
    port (
        dout  : out std_logic_vector(8 downto 0);
        clk   : in  std_logic;
        oce   : in  std_logic;
        ce    : in  std_logic;
        reset : in  std_logic;
        wre   : in  std_logic;
        ad    : in  std_logic_vector(5 downto 0);
        din   : in  std_logic_vector(8 downto 0)
    );
end Gowin_SP;

architecture rtl of Gowin_SP is
begin
    sp : entity work.xilinx_sp_ram
    generic map (AW => 6, DW => 9)
    port map (dout => dout, clk => clk, ce => ce, wre => wre, ad => ad, din => din);
end rtl;

---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity Gowin_SP2 is
    port (
        dout  : out std_logic_vector(5 downto 0);
        clk   : in  std_logic;
        oce   : in  std_logic;
        ce    : in  std_logic;
        reset : in  std_logic;
        wre   : in  std_logic;
        ad    : in  std_logic_vector(7 downto 0);
        din   : in  std_logic_vector(5 downto 0)
    );
end Gowin_SP2;

architecture rtl of Gowin_SP2 is
begin
    sp : entity work.xilinx_sp_ram
    generic map (AW => 8, DW => 6)
    port map (dout => dout, clk => clk, ce => ce, wre => wre, ad => ad, din => din);
end rtl;

---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity Gowin_SP3 is
    port (
        dout  : out std_logic_vector(7 downto 0);
        clk   : in  std_logic;
        oce   : in  std_logic;
        ce    : in  std_logic;
        reset : in  std_logic;
        wre   : in  std_logic;
        ad    : in  std_logic_vector(10 downto 0);
        din   : in  std_logic_vector(7 downto 0)
    );
end Gowin_SP3;

architecture rtl of Gowin_SP3 is
begin
    sp : entity work.xilinx_sp_ram
    generic map (AW => 11, DW => 8)
    port map (dout => dout, clk => clk, ce => ce, wre => wre, ad => ad, din => din);
end rtl;

---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity Gowin_SP5 is
    port (
        dout  : out std_logic_vector(7 downto 0);
        clk   : in  std_logic;
        oce   : in  std_logic;
        ce    : in  std_logic;
        reset : in  std_logic;
        wre   : in  std_logic;
        ad    : in  std_logic_vector(5 downto 0);
        din   : in  std_logic_vector(7 downto 0)
    );
end Gowin_SP5;

architecture rtl of Gowin_SP5 is
begin
    sp : entity work.xilinx_sp_ram
    generic map (AW => 6, DW => 8)
    port map (dout => dout, clk => clk, ce => ce, wre => wre, ad => ad, din => din);
end rtl;

---------------------------------------------------------------------------------
-- Dual port, two clocks. Shared variable for the Vivado true dual port template.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Gowin_DPB is
    port (
        douta  : out std_logic_vector(7 downto 0);
        doutb  : out std_logic_vector(7 downto 0);
        clka   : in  std_logic;
        ocea   : in  std_logic;
        cea    : in  std_logic;
        reseta : in  std_logic;
        wrea   : in  std_logic;
        clkb   : in  std_logic;
        oceb   : in  std_logic;
        ceb    : in  std_logic;
        resetb : in  std_logic;
        wreb   : in  std_logic;
        ada    : in  std_logic_vector(10 downto 0);
        dina   : in  std_logic_vector(7 downto 0);
        adb    : in  std_logic_vector(10 downto 0);
        dinb   : in  std_logic_vector(7 downto 0)
    );
end Gowin_DPB;

architecture rtl of Gowin_DPB is
    type mem_t is array(0 to 2047) of std_logic_vector(7 downto 0);
    shared variable mem : mem_t := (others => (others => '0'));
begin
    process(clka)
    begin
        if rising_edge(clka) then
            if cea = '1' then
                if wrea = '1' then
                    mem(to_integer(unsigned(ada))) := dina;
                else
                    douta <= mem(to_integer(unsigned(ada)));
                end if;
            end if;
        end if;
    end process;

    process(clkb)
    begin
        if rising_edge(clkb) then
            if ceb = '1' then
                if wreb = '1' then
                    mem(to_integer(unsigned(adb))) := dinb;
                else
                    doutb <= mem(to_integer(unsigned(adb)));
                end if;
            end if;
        end if;
    end process;
end rtl;
