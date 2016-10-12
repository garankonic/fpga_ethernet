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

entity simul is
--  Port ( );
end simul;

architecture Behavioral of simul is
component main
    Port (       
    -- Asynchronous reset
    RESET                    : in  std_logic;
    -- Marvel PHY is unhappy when reset is left dangling.
    PHY_RESET                     : out std_logic;
--An independent clock source used as the reference clock for an
--IDELAYCTRL (if present) and for the main GT transceiver reset logic.
--This example design assumes that this is of frequency 200MHz.
clk_in_p    : in std_logic;
clk_in_n    : in std_logic;

-- Tranceiver Interface
-----------------------

gtrefclk_p           : in std_logic;                     -- Differential +ve of reference clock for tranceiver: , very high quality
gtrefclk_n           : in std_logic;                     -- Differential -ve of reference clock for tranceiver: , very high quality
txp                  : out std_logic;                    -- Differential +ve of serial transmission from PMA to PMD.
txn                  : out std_logic;                    -- Differential -ve of serial transmission from PMA to PMD.
rxp                  : in std_logic;                     -- Differential +ve for serial reception from PMD to PMA.
rxn                  : in std_logic;                     -- Differential -ve for serial reception from PMD to PMA.
led_o                : out std_logic_vector(7 downto 0)
);
end component;

signal clk_in_p, clk_in_n, gtrefclk_p, gtrefclk_n, txp, txn, rxp, rxn : std_logic;
constant clk200_period : time := 5 ns;
constant clk125_period : time := 8 ns;


begin

    UUT: main port map('0',open,clk_in_p, clk_in_n, gtrefclk_p, gtrefclk_n, txp, txn, rxp, rxn, open);
    
    clk200_process: process
    begin
        clk_in_p <= '1';
        clk_in_n <= '0';
        wait for clk200_period/2;
        clk_in_p <= '0';
        clk_in_n <= '1';
        wait for clk200_period/2;
     end process;
     
     clk125_process: process
     begin
         gtrefclk_p <= '1';
         gtrefclk_n <= '0';
         wait for clk125_period/2;
         gtrefclk_p <= '0';
         gtrefclk_n <= '1';
         wait for clk125_period/2;
      end process;

end Behavioral;