----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/10/2016 11:27:24 AM
-- Design Name: 
-- Module Name: udp_tx - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity udp_tx is
  Generic ( mac_dest    : std_logic_vector(47 downto 0) := x"ff_ff_ff_ff_ff_ff";
            ip_src   : std_logic_vector(31 downto 0);
            ip_dest   : std_logic_vector(31 downto 0)
  );
  Port (    userclk2    :   in std_logic;
            gmii_txd    :   out std_logic_vector(7 downto 0);
            gmii_tx_en  :   out std_logic;
            
            ifdata      :   in std_logic; -- enablement of sending
            data_length :   in std_logic_vector(15 downto 0);
            data        :   in std_logic_vector(1023 downto 0)        
  );
end udp_tx;

architecture Behavioral of udp_tx is

component crc32_gen 
  port ( data_in : in std_logic_vector (7 downto 0);
    crc_en , rst, clk : in std_logic;
    crc_out : out std_logic_vector (31 downto 0));
end component;

    signal mac_src       : std_logic_vector(47 downto 0) := X"00_0A_35_03_30_9C";
    signal payload_length   : std_logic_vector(15 downto 0);
    signal ip_length   : std_logic_vector(15 downto 0);
    signal gmii_txd_int    :  std_logic_vector(7 downto 0);
        
    type type_state is ( WaitData, Preamble, MAC_Destination, MAC_Source, IP_Header, IP_Check, IP_Source, IP_Destination, UDP_Header, UDP_Data, PostData, FrameCheck, FinishedSending);
    signal state           : type_state := WaitData;
    signal ifdata_loc      : std_logic := '0';
    
    signal ip_checksum : std_logic_vector(31 downto 0) := x"00000000";
    signal ip_checksum01 : std_logic_vector(31 downto 0) := x"00000000";
    signal ip_checksum02 : std_logic_vector(31 downto 0) := x"00000000";
    signal ip_checksum01_shifted : std_logic_vector(31 downto 0) := x"00000000";
    signal ip_checksum02_shifted : std_logic_vector(31 downto 0) := x"00000000";
    signal ip_source12 : std_logic_vector(31 downto 0);
    signal ip_source34 : std_logic_vector(31 downto 0);
    signal ip_dest12 : std_logic_vector(31 downto 0);
    signal ip_dest34 : std_logic_vector(31 downto 0);
    signal null_16 : std_logic_vector(15 downto 0) := x"0000";
    
    signal crc_en       : std_logic := '0';   
    signal crc_rst       : std_logic := '0';
    signal crc32       : std_logic_vector(31 downto 0) := x"00_00_00_00";
    --signal crc32       : std_logic_vector(31 downto 0) := x"af_d3_ca_1e";   

    

begin
    
    
    payload_length <= data_length + X"0008";
    ip_length <= data_length + X"001C";
    
    -- calculating the ip header checksum
    ip_source12 <= null_16 & ip_src(31 downto 16);
    ip_source34 <= null_16 & ip_src(15 downto 0);
    ip_dest12 <= null_16 & ip_dest(31 downto 16);
    ip_dest34 <= null_16 & ip_dest(15 downto 0);
    ip_checksum01 <= x"0000C53F" + ip_source12 + ip_source34 + ip_dest12 + ip_dest34;
    ip_checksum02 <= null_16 & ((ip_checksum01(31 downto 16)) + (ip_checksum01(15 downto 0)));
    ip_checksum <= not (ip_checksum02);
    
map_crc32: crc32_gen port map(
    data_in     => gmii_txd_int,
    crc_en      => crc_en,
    rst         => crc_rst,
    clk         => userclk2,
    crc_out     => crc32
);
    
process(userclk2)
    --variable byte_counter : natural range 0 to 1023 := 0;
    variable byte_counter : integer := 0;
begin
    if rising_edge(userclk2) then
        if (state /= FrameCheck) and (state /= FinishedSending) then
            gmii_txd <= gmii_txd_int;
        end if;
        case state is
            when WaitData =>
                gmii_tx_en <= '0';
                gmii_txd_int <= x"00";
                if ifdata /= ifdata_loc then
                    ifdata_loc <= ifdata;
                    byte_counter := 7;
                    state <= Preamble;
                end if;
            when Preamble =>
                if byte_counter = 6 then
                    gmii_tx_en <= '1';
                end if;
                if byte_counter > 0 then
                    gmii_txd_int <= x"55";
                    byte_counter := byte_counter - 1;
                else
                    crc_rst <= '1';
                    gmii_txd_int <= x"D5";
                    byte_counter := 47;
                    state <= MAC_Destination;
                end if;
            when MAC_Destination =>
                gmii_txd_int <= mac_dest(byte_counter downto (byte_counter-7));                
                if byte_counter = 47 then
                    crc_rst <= '0';
                    crc_en <= '1';
                end if;
                if byte_counter > 7 then
                    byte_counter := byte_counter - 8;
                else
                    byte_counter := 47;
                    state <= MAC_Source;
                end if;
            when MAC_Source =>
                gmii_txd_int <= mac_src(byte_counter downto (byte_counter-7));
                if byte_counter > 7 then
                    byte_counter := byte_counter - 8;
                else
                    byte_counter := 11;
                    state <= IP_Header;
                end if;
            when IP_Header =>
                if byte_counter = 11 then
                    gmii_txd_int <= x"08";
                    byte_counter := byte_counter - 1;
                elsif byte_counter = 9 then
                    gmii_txd_int <= x"45";
                    byte_counter := byte_counter - 1;
		        elsif byte_counter = 7 then
                    gmii_txd_int <= ip_length(15 downto 8);
                    byte_counter := byte_counter - 1;
                elsif byte_counter = 6 then
                    gmii_txd_int <= ip_length(7 downto 0);
                    byte_counter := byte_counter - 1;
		        elsif byte_counter = 1 then
                    gmii_txd_int <= x"80";
                    byte_counter := byte_counter - 1;
		        elsif byte_counter = 0 then
                    gmii_txd_int <= x"11";
                    byte_counter := 15;
                    state <= IP_Check;
		        else
                    gmii_txd_int <= x"00";
                    byte_counter := byte_counter - 1;
                end if;
            when IP_Check =>
                gmii_txd_int <= ip_checksum(byte_counter downto (byte_counter-7));
                if byte_counter > 7 then
                    byte_counter := byte_counter - 8;
                else
                    byte_counter := 31;
                    state <= IP_Source;
                end if;
            when IP_Source =>
                gmii_txd_int <= ip_src(byte_counter downto (byte_counter-7));
                if byte_counter > 7 then
                    byte_counter := byte_counter - 8;
                else
                    byte_counter := 31;
                    state <= IP_Destination;
                end if;
            when IP_Destination =>
                gmii_txd_int <= ip_dest(byte_counter downto (byte_counter-7));
                if byte_counter > 7 then
                    byte_counter := byte_counter - 8;
                else
                    byte_counter := 7;
                    state <= UDP_Header;
                end if;
            when UDP_Header =>
                if (byte_counter = 7) or (byte_counter = 5) then
                    gmii_txd_int <= x"04";
                    byte_counter := byte_counter - 1;
                elsif byte_counter = 3 then
                    gmii_txd_int <= payload_length(15 downto 8);
                    byte_counter := byte_counter - 1;
                elsif byte_counter = 2 then
                    gmii_txd_int <= payload_length(7 downto 0);
                    byte_counter := byte_counter - 1;
                elsif byte_counter = 0 then
                    gmii_txd_int <= x"00";
                    byte_counter := (TO_INTEGER(unsigned(data_length))*8)-1;
                    state <= UDP_Data;
                else
                    gmii_txd_int <= x"00";
                    byte_counter := byte_counter - 1;
                end if;
            when UDP_Data =>
                gmii_txd_int <= data(byte_counter downto (byte_counter-7));
                if byte_counter > 7 then
                    byte_counter := byte_counter - 8;
                else
                    state <= PostData;
                end if;
            when PostData =>
                gmii_txd_int <= x"00";
                byte_counter := 24;
                crc_en <= '0';
                state <= FrameCheck;
            when FrameCheck =>
                gmii_txd(7) <= crc32(byte_counter) xor '1';
                gmii_txd(6) <= crc32(byte_counter+1) xor '1';
                gmii_txd(5) <= crc32(byte_counter+2) xor '1';
                gmii_txd(4) <= crc32(byte_counter+3) xor '1';
                gmii_txd(3) <= crc32(byte_counter+4) xor '1';
                gmii_txd(2) <= crc32(byte_counter+5) xor '1';
                gmii_txd(1) <= crc32(byte_counter+6) xor '1';
                gmii_txd(0) <= crc32(byte_counter+7) xor '1';
                if byte_counter > 0 then
                    byte_counter := byte_counter - 8;
                else
                    byte_counter := 3;
                    state <= FinishedSending;
                end if;
            when FinishedSending =>
                gmii_txd <= x"00";
                if byte_counter > 0 then
                    byte_counter := byte_counter - 1;
                else
                    state <= WaitData;
                end if;
            when others =>
                gmii_txd_int <= x"00";
		        state <= WaitData;                                  
        end case;
    end if;
end process;  
    
    


end Behavioral;
