----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/28/2016 04:16:52 PM
-- Design Name: 
-- Module Name: simul - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity simul_tx is
--  Port ( );
end simul_tx;

architecture Behavioral of simul_tx is
component udp_tx
Generic (   mac_dest    : std_logic_vector(47 downto 0) := x"ff_ff_ff_ff_ff_ff";
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
end component;

shared variable counter : integer := 0;
constant clk125_period : time := 8 ns;
signal data_int        :   std_logic_vector(1023 downto 0) := (others => '0');
signal StartSending     : std_logic := '0';
signal userclk2_int     : std_logic := '0';

begin
data_int(7 downto 0) <= x"aa";

UUT: udp_tx generic map (
      mac_dest      => x"ec_f4_bb_62_9f_b4",
      --mac_dest      => x"ff_ff_ff_ff_ff_ff",
      ip_src        => x"c0_a8_00_02",
      ip_dest       => x"c0_a8_00_01"
      )
      port map (
      userclk2      => userclk2_int,
      gmii_txd      => open,
      gmii_tx_en    => open,
      ifdata        => StartSending,
      data_length   => x"0001",
      data          => data_int
      );
      
      
     clk125_process: process
     begin
         userclk2_int <= '1';
         wait for clk125_period/2;
         userclk2_int <= '0';
         wait for clk125_period/2;
      end process;
      
      counter_process: process(userclk2_int)
      begin
        if rising_edge(userclk2_int) then
            counter := counter + 1;
            if counter = 500 then
                counter := 0;
                StartSending <= not StartSending;
            end if;
        end if;
      end process;

end Behavioral;