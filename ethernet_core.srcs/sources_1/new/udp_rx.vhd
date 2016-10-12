----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/10/2016 11:27:24 AM
-- Design Name: 
-- Module Name: udp_rx - Behavioral
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

entity udp_rx is
  Port (    userclk2    :   in std_logic;
            gmii_rxd    :   in std_logic_vector(7 downto 0);
            gmii_rx_dv  :   in std_logic;
            
            ifdata      :   out std_logic; -- data is present
            data_length :   out std_logic_vector(15 downto 0); -- for the moment maximum 128 bytes
            data        :   out std_logic_vector(1023 downto 0)        
  );
end udp_rx;

architecture Behavioral of udp_rx is

component ila_1
PORT (
    clk : IN STD_LOGIC;
    probe0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    probe1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe5 : IN STD_LOGIC_VECTOR(3 DOWNTO 0)
);
END component;

component crc32_gen 
  port ( data_in : in std_logic_vector (7 downto 0);
    crc_en , rst, clk : in std_logic;
    crc_out : out std_logic_vector (31 downto 0));
end component;

    signal mac_xilinx       : std_logic_vector(47 downto 0) := X"00_0A_35_03_30_9C";
    signal payload_length   : std_logic_vector(15 downto 0);
    signal ip_length   : std_logic_vector(15 downto 0);
    signal gmii_rxd_int    :  std_logic_vector(7 downto 0);
    signal gmii_rx_dv_int  : std_logic;
    signal ifdata_int      : std_logic := '0';
    signal data_length_int :   std_logic_vector(15 downto 0); -- for the moment fixed 18 - 0x12
    signal data_int        :   std_logic_vector(1023 downto 0); 
        
    type type_state is ( WaitData, Preamble, MAC_Destination, MAC_Source, IP_Header, IP_Check, IP_Source, IP_Destination, UDP_Header, UDP_Data, FrameCheck, FinishedSending, RejectFrame);
    signal state           : type_state := WaitData;
    signal state_vector    :  std_logic_vector(3 downto 0);
    
--    signal ip_checksum : std_logic_vector(31 downto 0) := x"00000000";
--    signal ip_checksum01 : std_logic_vector(31 downto 0) := x"00000000";
--    signal ip_checksum02 : std_logic_vector(31 downto 0) := x"00000000";
--    signal ip_checksum01_shifted : std_logic_vector(31 downto 0) := x"00000000";
--    signal ip_checksum02_shifted : std_logic_vector(31 downto 0) := x"00000000";
--    signal ip_source12 : std_logic_vector(31 downto 0);
--    signal ip_source34 : std_logic_vector(31 downto 0);
--    signal ip_dest12 : std_logic_vector(31 downto 0);
--    signal ip_dest34 : std_logic_vector(31 downto 0);
--    signal null_16 : std_logic_vector(15 downto 0) := x"0000";
    
    signal crc_en       : std_logic := '0';
    signal crc_rst       : std_logic := '0';
    signal crc32       : std_logic_vector(31 downto 0) := x"00_00_00_00";
    signal crc32_received       : std_logic_vector(31 downto 0) := x"00_00_00_00";
    signal crc32_calculated       : std_logic_vector(31 downto 0) := x"00_00_00_00";
    
    signal PackageProcessed       : std_logic := '0';
    --signal crc32       : std_logic_vector(31 downto 0) := x"af_d3_ca_1e";   

    

begin

    ifdata <= ifdata_int;
    gmii_rxd_int <= gmii_rxd;
    gmii_rx_dv_int <= gmii_rx_dv;
       
--    -- calculating the ip header checksum
--    ip_source12 <= null_16 & ip_src(31 downto 16);
--    ip_source34 <= null_16 & ip_src(15 downto 0);
--    ip_dest12 <= null_16 & ip_dest(31 downto 16);
--    ip_dest34 <= null_16 & ip_dest(15 downto 0);
--    ip_checksum01 <= x"0000C53F" + ip_source12 + ip_source34 + ip_dest12 + ip_dest34;
--    ip_checksum02 <= null_16 & ((ip_checksum01(31 downto 16)) + (ip_checksum01(15 downto 0)));
--    ip_checksum <= not (ip_checksum02);
    
map_crc32: crc32_gen port map(
    data_in     => gmii_rxd_int,
    crc_en      => crc_en,
    rst         => crc_rst,
    clk         => userclk2,
    crc_out     => crc32
);

with state select state_vector(3 downto 0) <=
 	x"0" when WaitData,
 	x"1" when Preamble,
 	x"2" when MAC_Destination,
 	x"3" when MAC_Source,
 	x"4" when IP_Header,
 	x"5" when IP_Check,
 	x"6" when IP_Source,
 	x"7" when IP_Destination,
 	x"8" when UDP_Header,
 	x"9" when UDP_Data,
 	x"a" when FrameCheck,
 	x"b" when FinishedSending,
 	x"c" when RejectFrame,	
 	x"f" when OTHERS;
    
process(userclk2)
    --variable byte_counter : natural range 0 to 1023 := 0;
    variable byte_counter : integer := 0;
    variable any_address_counter : natural range 0 to 6 := 0;
begin
    if rising_edge(userclk2) then
        if (gmii_rx_dv_int = '0') then
            crc_en <= '0';
            state <= WaitData;
            PackageProcessed <= '0';
        end if;
        case state is
            when WaitData =>
                if (gmii_rx_dv_int = '1') and (PackageProcessed = '0') then
                    byte_counter := 0;
                    state <= Preamble;
                end if;
            when Preamble =>
                byte_counter := byte_counter + 1;
                if gmii_rxd_int = x"55" then
                    crc_rst <= '1';
                    crc_en <= '0';
                elsif gmii_rxd_int = x"D5" then
                    crc_rst <= '0';
                    crc_en <= '1';
                    any_address_counter := 0;
                    byte_counter := 47;
                    state <= MAC_Destination;
                elsif byte_counter > 8 then
                    state <= RejectFrame;
                end if;
            when MAC_Destination =>                
                if (byte_counter > 7) then
                    if (gmii_rxd_int = mac_xilinx(byte_counter downto (byte_counter-7))) then
                        byte_counter := byte_counter - 8;
                    elsif (gmii_rxd_int = x"ff") then
                        any_address_counter := any_address_counter + 1;
                        byte_counter := byte_counter - 8;
	                else 
			            state <= RejectFrame;
                    end if;
                else
                    if (gmii_rxd_int = mac_xilinx(byte_counter downto (byte_counter-7))) or ((gmii_rxd_int = x"ff") and (any_address_counter = 5)) then
                        byte_counter := 47;
                        state <= MAC_Source;
                    else
                        state <= RejectFrame;   
                    end if;                          
                end if;                 
            when MAC_Source =>
                -- here you can set source address restrictions
                if (byte_counter > 7) then
                    if true then
                        byte_counter := byte_counter - 8;
	                else 
			            state <= RejectFrame;
                    end if;
                else
                    if true then
                        byte_counter := 0;
                        state <= IP_Header;
                    else
                        state <= RejectFrame;   
                    end if;                          
                end if;                
            when IP_Header =>
                -- check for tcp/ip
                if byte_counter = 0 then
                    if gmii_rxd_int /= x"08" then
                        state <= RejectFrame;
                    else
                        byte_counter := byte_counter + 1;
                    end if;
                elsif byte_counter = 1 then
                    if gmii_rxd_int /= x"00" then
                        state <= RejectFrame;
                    else
                        byte_counter := byte_counter + 1;
                    end if;
                -- write ip length
                elsif byte_counter = 4 then
                    ip_length(15 downto 8) <= gmii_rxd_int;
                    byte_counter := byte_counter + 1;
                elsif byte_counter = 5 then
                    ip_length(7 downto 0) <= gmii_rxd_int;
                    byte_counter := byte_counter + 1;
                -- check the protocol and go to the checksum
                elsif byte_counter = 11 then
                    if gmii_rxd_int /= x"11" then
                        state <= RejectFrame;
                    else
                        byte_counter := 0;
                        state <= IP_Check;
                    end if;
                else
                    byte_counter := byte_counter + 1;
                end if;
            when IP_Check =>
                -- can check ip checksum there (not used)
                if byte_counter = 0 then
                    byte_counter := byte_counter + 1;
                else
                    byte_counter := 31;
                    state <= IP_Source;
                end if;
            when IP_Source =>
                -- here you can set source address restrictions
                if (byte_counter > 7) then
                    if true then
                        byte_counter := byte_counter - 8;
	                else 
			            state <= RejectFrame;
                    end if;
                else
                    if true then
                        byte_counter := 31;
                        state <= IP_Destination;
                    else
                        state <= RejectFrame;   
                    end if;                          
                end if;
            when IP_Destination =>
                -- here you can set destination address restrictions
                if (byte_counter > 7) then
                    if true then
                        byte_counter := byte_counter - 8;
	                else 
			            state <= RejectFrame;
                    end if;
                else
                    if true then
                        byte_counter := 0;
                        state <= UDP_Header;
                    else
                        state <= RejectFrame;   
                    end if;                          
                end if;
            when UDP_Header =>
                -- source and destination port MSB
                --if (byte_counter = 0) or (byte_counter = 2) then
                if (byte_counter = 2) then
                    if gmii_rxd_int /= x"04" then
                        state <= RejectFrame;
                    else
                        byte_counter := byte_counter + 1;
                    end if;
                -- source and destination port LSB
                --elsif (byte_counter = 1) or (byte_counter = 3) then
                elsif (byte_counter = 3) then
                    if gmii_rxd_int /= x"00" then
                        state <= RejectFrame;
                    else
                        byte_counter := byte_counter + 1;
                    end if;
                elsif byte_counter = 4 then
                    payload_length(15 downto 8) <= gmii_rxd_int;
                    byte_counter := byte_counter + 1;
                elsif byte_counter = 5 then
                    payload_length(7 downto 0) <= gmii_rxd_int;
                    byte_counter := byte_counter + 1;
                elsif byte_counter = 7 then
                    if (ip_length /= (payload_length+X"0014")) then
                        state <= RejectFrame;
                    else
                        byte_counter := TO_INTEGER(unsigned(payload_length-x"0008"))*8-1;
                        data_length_int <= payload_length-x"0008";
                        state <= UDP_Data;
                    end if;
                else
                    byte_counter := byte_counter + 1;
                end if;
            when UDP_Data =>
                data_int(byte_counter downto (byte_counter-7)) <= gmii_rxd_int;
                if byte_counter > 7 then
                    byte_counter := byte_counter - 8;
                else
                    byte_counter := 31;
                    crc_en <= '0';
                    state <= FrameCheck;
                end if;
            when FrameCheck =>
                crc32_received(byte_counter downto (byte_counter-7)) <= gmii_rxd_int;
                crc32_calculated(byte_counter-7) <= crc32(byte_counter) xor '1';
                crc32_calculated(byte_counter-6) <= crc32(byte_counter-1) xor '1';
                crc32_calculated(byte_counter-5) <= crc32(byte_counter-2) xor '1';
                crc32_calculated(byte_counter-4) <= crc32(byte_counter-3) xor '1';
                crc32_calculated(byte_counter-3) <= crc32(byte_counter-4) xor '1';
                crc32_calculated(byte_counter-2) <= crc32(byte_counter-5) xor '1';
                crc32_calculated(byte_counter-1) <= crc32(byte_counter-6) xor '1';
                crc32_calculated(byte_counter) <= crc32(byte_counter-7) xor '1';
                if byte_counter > 7 then
                    byte_counter := byte_counter - 8;
                else
                    state <= FinishedSending;
                end if;
            when FinishedSending =>
                if (crc32_calculated = crc32_received) or (crc32_received = x"00_00_00_00") then
                    data <= data_int;
                    data_length <= data_length_int;
                    ifdata_int <= not ifdata_int;
                    state <= WaitData;
                    PackageProcessed <= '1';
                else
                    state <= RejectFrame;
                end if;
            when RejectFrame =>
                if gmii_rx_dv_int = '1' then
                    PackageProcessed <= '1';
                end if;
                crc_en <= '0';
                state <= WaitData;
                                
            when others =>
		        state <= WaitData;                                  
        end case;
    end if;
end process;

   RX_ILA : ila_1
    port map
    (
        clk => userclk2,
        probe0 => data_length_int,
        probe1 => gmii_rxd_int,
        probe2(0) => gmii_rx_dv_int,
        probe3(0) => PackageProcessed,
        probe4(0) => '0',
        probe5    => state_vector
    );

end Behavioral;
