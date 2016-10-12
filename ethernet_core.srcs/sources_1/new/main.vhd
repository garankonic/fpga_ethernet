----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/28/2016 06:24:45 PM
-- Design Name: 
-- Module Name: main - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity main is
    Port (
-- Asynchronous reset
RESET                    : in  std_logic;
-- Marvel PHY is unhappy when reset is left dangling.
PHY_RESET					 : out std_logic;
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
rxn                  : in std_logic;                    -- Differential -ve for serial reception from PMD to PMA.
led_o                : out std_logic_vector(7 downto 0)

-- General IO's
---------------
-- status_vector        : out std_logic_vector(15 downto 0); -- Core status.
-- reset                : in std_logic                     -- Asynchronous reset for entire core.);
);
end main;

architecture Behavioral of main is

component ila_0
PORT (
clk : IN STD_LOGIC;


probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe5 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    probe6 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    probe7 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)

);
END component;

component gig_ethernet_core
      port(
      -- Transceiver Interface
      ---------------------

      gtrefclk_p               : in  std_logic;                          
      gtrefclk_n               : in  std_logic;                         


      gtrefclk_out             : out std_logic;                           -- Very high quality clock for GT transceiver.
      gtrefclk_bufg_out        : out std_logic;                           
      
      
      txp                  : out std_logic;                    -- Differential +ve of serial transmission from PMA to PMD.
      txn                  : out std_logic;                    -- Differential -ve of serial transmission from PMA to PMD.
      rxp                  : in std_logic;                     -- Differential +ve for serial reception from PMD to PMA.
      rxn                  : in std_logic;                     -- Differential -ve for serial reception from PMD to PMA.
      resetdone                : out std_logic;                           -- The GT transceiver has completed its reset cycle
      userclk_out              : out std_logic;                           
      userclk2_out             : out std_logic;                           
      rxuserclk_out              : out std_logic;                         
      rxuserclk2_out             : out std_logic;                         
      pma_reset_out            : out std_logic;                           -- transceiver PMA reset signal
      mmcm_locked_out          : out std_logic;                           -- MMCM Locked
      independent_clock_bufg : in std_logic;                   

      -- GMII Interface
      -----------------
      sgmii_clk_r            : out std_logic;              
      sgmii_clk_f            : out std_logic;              
      sgmii_clk_en           : out std_logic;                  -- Clock enable for client MAC
      gmii_txd             : in std_logic_vector(7 downto 0);  -- Transmit data from client MAC.
      gmii_tx_en           : in std_logic;                     -- Transmit control signal from client MAC.
      gmii_tx_er           : in std_logic;                     -- Transmit control signal from client MAC.
      gmii_rxd             : out std_logic_vector(7 downto 0); -- Received Data to client MAC.
      gmii_rx_dv           : out std_logic;                    -- Received control signal to client MAC.
      gmii_rx_er           : out std_logic;                    -- Received control signal to client MAC.
      gmii_isolate         : out std_logic;                    -- Tristate control to electrically isolate GMII.
      

      -- Management: Alternative to MDIO Interface
      --------------------------------------------

      configuration_vector : in std_logic_vector(4 downto 0);  -- Alternative to MDIO interface.


      an_interrupt         : out std_logic;                    -- Interrupt to processor to signal that Auto-Negotiation has completed
      an_adv_config_vector : in std_logic_vector(15 downto 0); -- Alternate interface to program REG4 (AN ADV)
      an_restart_config    : in std_logic;                     -- Alternate signal to modify AN restart bit in REG0

      -- Speed Control
      ----------------
      speed_is_10_100      : in std_logic;                     -- Core should operate at either 10Mbps or 100Mbps speeds
      speed_is_100         : in std_logic;                      -- Core should operate at 100Mbps speed


      -- General IO's
      ---------------
      status_vector        : out std_logic_vector(15 downto 0); -- Core status.
      reset                : in std_logic;                     -- Asynchronous reset for entire core.
     
      signal_detect         : in std_logic;                      -- Input from PMD to indicate presence of optical input.
      gt0_qplloutclk_out     : out std_logic;
      gt0_qplloutrefclk_out  : out std_logic

      );
end component;

component udp_tx
  Generic ( mac_dest    : std_logic_vector(47 downto 0);
            ip_src   : std_logic_vector(31 downto 0);
            ip_dest   : std_logic_vector(31 downto 0)
  );
  Port (    userclk2    :   in std_logic;
            gmii_txd    :   out std_logic_vector(7 downto 0);
            gmii_tx_en  :   out std_logic;
            
            ifdata      :   in std_logic; -- enablement of sending
            data_length :   in std_logic_vector(15 downto 0); -- for the moment maximum 128 bytes
            data        :   in std_logic_vector(1023 downto 0)        
  );
end component;

component udp_rx
  Port (    userclk2    :   in std_logic;
            gmii_rxd    :   in std_logic_vector(7 downto 0);
            gmii_rx_dv  :   in std_logic;
            
            ifdata      :   out std_logic; -- data is present
            data_length :   out std_logic_vector(15 downto 0); -- for the moment fixed 18 - 0x12
            data        :   out std_logic_vector(1023 downto 0)        
  );
end component;
  -- clock generation signals for tranceiver
  signal gtrefclk_bufg_out     : std_logic;
  signal clk200                : std_logic;
  signal reset_i                 : std_logic;

  signal userclk               : std_logic;                    
  signal userclk2              : std_logic;                    
  signal rxuserclk2_i          : std_logic;                    

  signal gmii_txd_int          : std_logic_vector(7 downto 0); -- Internal gmii_txd signal (between core and SGMII adaptation module).
  signal gmii_tx_en_int        : std_logic;                    -- Internal gmii_tx_en signal (between core and SGMII adaptation module).
  signal gmii_rxd_int          : std_logic_vector(7 downto 0); -- Internal gmii_rxd signal (between core and SGMII adaptation module).
  signal gmii_rx_dv_int        : std_logic;                    -- Internal gmii_rx_dv signal (between core and SGMII adaptation module).
 
  -- An independent clock source used as the reference clock for an
  -- IDELAYCTRL (if present) and for the main GT transceiver reset logic.
  signal independent_clock_bufg: std_logic;
 
  shared variable counter       : integer := 0;
  signal StartSending           : std_logic := '0';
  signal ReceivedData           : std_logic;
  signal ReceivedDataLoc           : std_logic := '0';
  
  -- output data
  signal tx_data_length            : std_logic_vector(15 downto 0); -- for the moment fixed 18 - 0x12
  signal tx_data                   : std_logic_vector(1023 downto 0) ;
    -- input data
  shared variable bit_counter      : integer := 0;
  signal rx_data_length            : std_logic_vector(15 downto 0); -- for the moment fixed 18 - 0x12
  signal rx_data                   : std_logic_vector(1023 downto 0) ;

begin

-- Reset input buffer
reset_ibuf : IBUF 
    port map (
      I => RESET,
      O => reset_i
    );
PHY_RESET <= not reset_i;

diff_clk_buffer: IBUFGDS
    port map (  I => clk_in_p,
               IB => clk_in_n,
                O => clk200);
                
--ref_clk_buffer: IBUFGDS
--    port map (  I => gtrefclk_p,
--                IB => gtrefclk_n,
--                 O => userclk2);
             
bufg_independent_clock : BUFG
    port map (        I         => clk200,
                      O         => independent_clock_bufg);                     

map_gig: gig_ethernet_core port map ( 

      gtrefclk_p             => gtrefclk_p,
      gtrefclk_n             => gtrefclk_n,
      gtrefclk_out           => open,
      gtrefclk_bufg_out      => gtrefclk_bufg_out,
      
      txp                  => txp,
      txn                  => txn,
      rxp                  => rxp,
      rxn                  => rxn,
      mmcm_locked_out          => open,
      userclk_out              => userclk,
      userclk2_out             => userclk2,
      --userclk2_out             => open,
      --rxuserclk_out              => open,
      rxuserclk2_out             => rxuserclk2_i,
      independent_clock_bufg => independent_clock_bufg,
      pma_reset_out              => open,
      resetdone                  => open,
      
      sgmii_clk_r            => open,
      sgmii_clk_f            => open,
      sgmii_clk_en           => open,
      gmii_txd             => gmii_txd_int,
      gmii_tx_en           => gmii_tx_en_int,
      gmii_tx_er           => '0',
      gmii_rxd             => gmii_rxd_int,
      gmii_rx_dv           => gmii_rx_dv_int,
      gmii_rx_er           => open,
      gmii_isolate         => open,
      configuration_vector => "10000",
      an_interrupt         => open,
      an_adv_config_vector => "1000100000000001",
      an_restart_config    => '0',
      speed_is_10_100      => '0',
      speed_is_100         => '0',

      status_vector        => open, --status_vector,
      reset                => reset_i,
   

      signal_detect        => '1',
      gt0_qplloutclk_out     => open,
      gt0_qplloutrefclk_out  => open  
      );

map_tx: udp_tx generic map (
      mac_dest      => x"ec_f4_bb_62_9f_b4",
      --mac_dest      => x"ff_ff_ff_ff_ff_ff",
      ip_src        => x"c0_a8_00_02",
      ip_dest       => x"c0_a8_00_01"
      )
      port map (
      userclk2      => userclk2,
      gmii_txd      => gmii_txd_int,
      gmii_tx_en    => gmii_tx_en_int,
      ifdata        => StartSending,
      data_length   => tx_data_length,
      data          => tx_data
      );
map_rx: udp_rx port map (
      userclk2      => userclk2,
      gmii_rxd      => gmii_rxd_int,
      gmii_rx_dv    => gmii_rx_dv_int,
      ifdata        => ReceivedData,
      data_length   => rx_data_length,
      data          => rx_data
      );

   process (userclk2)
   begin
      if userclk2'event and userclk2 = '1' then         
         counter := counter+1;
               
         if counter = 125_000_000 then
         --if counter = 500 then
--            StartSending <= not StartSending;
--            tx_data_length <= x"0012"; -- 18 bytes
--            tx_data <= (others => '0');
--            tx_data(143 downto 0) <= x"01_AA_BB_cc_dd_ee_ff_11_22_33_CC_CC_66_77_88_99_AA_BB";
            counter := 0;
         end if; 
         
      end if;
   end process;
   
   process (userclk2)
   begin
        if userclk2'event and userclk2 = '1' then      
            if ReceivedData /= ReceivedDataLoc then
                ReceivedDataLoc <= ReceivedData;
                bit_counter := TO_INTEGER(unsigned(rx_data_length))*8-1;
                -- first 2 bytes define the command
                case rx_data(bit_counter downto (bit_counter-15)) is
                    -- welcome message
                    when x"0000" =>
                        StartSending <= not StartSending;
                        tx_data_length <= x"0064"; -- 98+2 bytes
                        tx_data(799 downto 0) <= x"0000_58696c696e78204b43373035204576616c756174696f6e20426f6172642e204445535920434d5320547261636b657220557067726164652050686173652049492e204469676974616c2044657369676e206279204d796b797461202862657461292e";
                    -- 16 bit counter increment
                    when x"0001" =>
                        StartSending <= not StartSending;
                        tx_data_length <= x"0004"; -- 2+2 bytes
                        tx_data(31 downto 0) <= x"0001" & (rx_data((bit_counter-8) downto (bit_counter-23))+x"00_01");
                    -- command was not recognised
                    when others =>
                        StartSending <= not StartSending;
                        tx_data_length <= x"0002"; -- 2 bytes
                        tx_data(15 downto 0) <= x"ffff";
                end case; 
            end if;
        end if;
   end process;
   
   U_ILA : ila_0
    port map
    (
        clk => userclk2,
        probe0(0) => StartSending,
        probe1(0) => ReceivedData,
        probe2(0) => gtrefclk_bufg_out,
        probe3(0) => gmii_tx_en_int,
        probe4(0) => gmii_rx_dv_int,
        probe5    => gmii_rxd_int,
        probe6    => gmii_txd_int,
        probe7    => rx_data_length
    );                          

end Behavioral;
