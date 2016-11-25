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

-- Custom libraries and packages:
use work.gbt_bank_package.all;
use work.vendor_specific_gbt_bank_package.all;
use work.gbt_banks_user_setup.all;

entity main is
    Port (
-- Asynchronous reset
      CPU_RESET                    : in  std_logic;
      -- Marvel PHY is unhappy when reset is left dangling.
      PHY_RESET					 : out std_logic;
      --An independent clock source used as the reference clock for an
      --IDELAYCTRL (if present) and for the main GT transceiver reset logic.
      --This example design assumes that this is of frequency 200MHz.
      SYSCLK_P    : in std_logic;
      SYSCLK_N    : in std_logic;

-- Tranceiver Interface ( Ethernet Part )

      gtrefclk_p           : in std_logic;                     -- Differential +ve of reference clock for tranceiver: , very high quality
      gtrefclk_n           : in std_logic;                     -- Differential -ve of reference clock for tranceiver: , very high quality
      txp                  : out std_logic;                    -- Differential +ve of serial transmission from PMA to PMD.
      txn                  : out std_logic;                    -- Differential -ve of serial transmission from PMA to PMD.
      rxp                  : in std_logic;                     -- Differential +ve for serial reception from PMD to PMA.
      rxn                  : in std_logic;                    -- Differential -ve for serial reception from PMD to PMA.
	--led_o                : out std_logic_vector(7 downto 0)

-- GBT Part
      -- Fabric clock:
      ----------------     

      USER_CLOCK_P                                   : in  std_logic;
      USER_CLOCK_N                                   : in  std_logic;      
      
      -- MGT(GTX) reference clock:
      ----------------------------
      
      -- Comment: * The MGT reference clock MUST be provided by an external clock generator.
      --
      --          * The MGT reference clock frequency must be 120MHz for the latency-optimized GBT Bank.      
      
      SMA_MGT_REFCLK_P                               : in  std_logic;
      SMA_MGT_REFCLK_N                               : in  std_logic; 
      
      --==========--
      -- MGT(GTX) --
      --==========--                   
      
      -- Serial lanes:
      ----------------
      
      SFP_TX_P                                       : out std_logic;
      SFP_TX_N                                       : out std_logic;
      SFP_RX_P                                       : in  std_logic;
      SFP_RX_N                                       : in  std_logic;    
      
      -- SFP control:
      ---------------
      
      SFP_TX_DISABLE                                 : out std_logic
);
end main;

architecture Behavioral of main is

--component ila_0
--PORT (
--clk : IN STD_LOGIC;


--probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--    probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--    probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--    probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--    probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--    probe5 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--    probe6 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--    probe7 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)

--);
--END component;

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

----------------------------------
-- Signal Declaration
----------------------------------
   --===============--     
   -- General reset --     
   --===============--     

   signal reset_from_genRst                          : std_logic;    
   
   --===============--
   -- Clocks scheme -- 
   --===============--   
   
   -- Fabric clock:
   ----------------
   
   signal fabricClk_from_userClockIbufgds            : std_logic;     

   -- MGT(GTX) reference clock:     
   ----------------------------     
  
   signal mgtRefClk_from_smaMgtRefClkIbufdsGtxe2     : std_logic;   

    -- Frame clock:
    ---------------
    signal txFrameClk_from_txPll                     : std_logic;
    
   --================--
   -- Clock component--
   --================--
   COMPONENT xlx_k7v7_tx_pll PORT(
      clk_in1: in std_logic;
      RESET: in std_logic;
      CLK_OUT1: out std_logic;
      LOCKED: out std_logic
   );
   END COMPONENT;
       
   --=========================--
   -- GBT Bank --
   --=========================--   
   -- Control:
   -----------
   signal not_cpu_reset                              : std_logic;   
   signal txIsData_to_gbt                                   : std_logic := '0';
   signal waitDataBack                               : std_logic := '0';   
   --------------------------------------------------       
   signal rxIsData_from_gbt                 : std_logic;        

   -- Data:
   --------
   
   signal txData_to_gbt                   : std_logic_vector(83 downto 0) := (others => '0');
   signal rxData_from_gbt                   : std_logic_vector(83 downto 0);
   --------------------------------------------------      
   signal txExtraDataWidebus_to_gbt       : std_logic_vector(31 downto 0) := (others => '0');
   signal rxExtraDataWidebus_from_gbt       : std_logic_vector(31 downto 0);

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
  signal tx_data_length            : std_logic_vector(15 downto 0);
  signal tx_data                   : std_logic_vector(1023 downto 0) ;
    -- input data
  shared variable bit_counter      : integer := 0;
  signal rx_data_length            : std_logic_vector(15 downto 0); 
  signal rx_data                   : std_logic_vector(1023 downto 0) ;

begin

   --=============--
   -- SFP control -- 
   --=============-- 
   
   SFP_TX_DISABLE                                    <= '0';  
   not_cpu_reset                                     <= not reset_i; 
   
   --===============--
   -- General reset -- 
   --===============--
   
   genRst: entity work.xlx_k7v7_reset
      generic map (
         CLK_FREQ                                    => 156e6)
      port map (     
         CLK_I                                       => fabricClk_from_userClockIbufgds,
         RESET1_B_I                                  => not_cpu_reset, 
         RESET_O                                     => reset_from_genRst 
      ); 

	-- Reset input buffer
	reset_ibuf : IBUF 
	    port map (
	      I => CPU_RESET,
	      O => reset_i
	    );
	PHY_RESET <= not reset_i;

	diff_clk_buffer: IBUFGDS
	    port map (  I => SYSCLK_P,
		       IB => SYSCLK_N,
		        O => clk200);
		        
	--ref_clk_buffer: IBUFGDS
	--    port map (  I => gtrefclk_p,
	--                IB => gtrefclk_n,
	--                 O => userclk2);
             
	bufg_independent_clock : BUFG
	    port map (        I         => clk200,
		              O         => independent_clock_bufg); 

   -- Fabric clock:
   ----------------
   
   -- Comment: USER_CLOCK frequency: 156MHz 
   
   userClockIbufgds: ibufgds
      generic map (
         IBUF_LOW_PWR                                => FALSE,      
         IOSTANDARD                                  => "LVDS_25")
      port map (     
         O                                           => fabricClk_from_userClockIbufgds,   
         I                                           => USER_CLOCK_P,  
         IB                                          => USER_CLOCK_N 
      );
   
   -- MGT(GTX) reference clock:
   ----------------------------
   
   -- Comment: * The MGT reference clock MUST be provided by an external clock generator.
   --
   --          * The MGT reference clock frequency must be 120MHz for the latency-optimized GBT Bank. 
   
   smaMgtRefClkIbufdsGtxe2: ibufds_gte2
      port map (
         O                                           => mgtRefClk_from_smaMgtRefClkIbufdsGtxe2,
         ODIV2                                       => open,
         CEB                                         => '0',
         I                                           => SMA_MGT_REFCLK_P,
         IB                                          => SMA_MGT_REFCLK_N
      );

    -- Frame clock
    txPll: xlx_k7v7_tx_pll
      port map (
         clk_in1                                  => mgtRefClk_from_smaMgtRefClkIbufdsGtxe2,
         CLK_OUT1                                 => txFrameClk_from_txPll,
         -----------------------------------------  
         RESET                                    => '0',
         LOCKED                                   => open
      );                    

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
   
   gbtTestInterface: entity work.gbt_interface
       generic map(
           GBT_BANK_ID                                            => 1,
           NUM_LINKS                                              => GBT_BANKS_USER_SETUP(1).NUM_LINKS,
           TX_OPTIMIZATION                                        => GBT_BANKS_USER_SETUP(1).TX_OPTIMIZATION,
           RX_OPTIMIZATION                                        => GBT_BANKS_USER_SETUP(1).RX_OPTIMIZATION,
           TX_ENCODING                                            => GBT_BANKS_USER_SETUP(1).TX_ENCODING,
           RX_ENCODING                                            => GBT_BANKS_USER_SETUP(1).RX_ENCODING
       )
     port map (

       --==============--
       -- Clocks       --
       --==============--
       FRAMECLK_40MHZ                                             => txFrameClk_from_txPll,
       XCVRCLK                                                    => mgtRefClk_from_smaMgtRefClkIbufdsGtxe2,
       --==============--
       -- Reset        --
       --==============--
       GBTBANK_GENERAL_RESET_I                                    => reset_from_genRst,

       --==============--
       -- Serial lanes --
       --==============--
       GBTBANK_MGT_RX_P(1)                                        => SFP_RX_P,
       GBTBANK_MGT_RX_N(1)                                        => SFP_RX_N,
       GBTBANK_MGT_TX_P(1)                                        => SFP_TX_P,
       GBTBANK_MGT_TX_N(1)                                        => SFP_TX_N,
       
       --==============--
       -- Data             --
       --==============--        
       GBTBANK_GBT_DATA_I(1)                                      => txData_to_gbt,
       GBTBANK_WB_DATA_I(1)                                       => txExtraDataWidebus_to_gbt,
      
       GBTBANK_GBT_DATA_O(1)                                      => rxData_from_gbt,
       GBTBANK_WB_DATA_O(1)                                       => rxExtraDataWidebus_from_gbt,
       
       --==============--
       -- Reconf.         --
       --==============--
       GBTBANK_MGT_DRP_CLK                                        => fabricClk_from_userClockIbufgds,
       
       --==============--
       -- TX ctrl        --
       --==============--
       GBTBANK_TX_ISDATA_SEL_I(1)                                => txIsData_to_gbt,

       --==============--
       -- RX Status    --
       GBTBANK_RX_ISDATA_SEL_O(1)                                => rxIsData_from_gbt
  );
	   
	   process (userclk2)
	   begin
		if userclk2'event and userclk2 = '1' then
		    if waitDataBack <= '1' then
		        txIsData_to_gbt <= '0';
		        if rxIsData_from_gbt = '1' then
		          waitDataBack <= '0';
		          StartSending <= not StartSending;
		          tx_data_length <= x"001F"; -- 30+1 bytes
                  tx_data(247 downto 0) <= x"02_5265636569766564204261636b20446174613a20" & rxData_from_gbt(79 downto 0);
		        end if;
		    end if;      
		    if ReceivedData /= ReceivedDataLoc then
		        ReceivedDataLoc <= ReceivedData;
		        bit_counter := TO_INTEGER(unsigned(rx_data_length))*8-1;
		        -- first 1 byte defines the command
		        case rx_data(bit_counter downto (bit_counter-7)) is
		            -- welcome message
		            when x"00" =>
		                StartSending <= not StartSending;
		                tx_data_length <= x"0063"; -- 98+1 bytes
		                tx_data(791 downto 0) <= x"00_58696c696e78204b43373035204576616c756174696f6e20426f6172642e204445535920434d5320547261636b657220557067726164652050686173652049492e204469676974616c2044657369676e206279204d796b797461202862657461292e";
		            -- 16 bit counter increment
		            when x"01" =>
		                StartSending <= not StartSending;
		                tx_data_length <= x"0003"; -- 2+1 bytes
		                tx_data(23 downto 0) <= x"01" & (rx_data((bit_counter-8) downto (bit_counter-23))+x"00_01");
		            -- check GBT interface  
		            when x"02" =>
		                StartSending <= not StartSending;
		                if (bit_counter = 87) then
		                    tx_data_length <= x"003e"; -- 61+1 bytes
                            tx_data(495 downto 0) <= x"02_53656e64696e67206e657874206461746120746f20636865636b3a20" & rx_data(79 downto 0) & x"0d0a57616974696e6720666f7220726573706f6e73652e";
                        
                            txIsData_to_gbt <= '1';
                            txData_to_gbt(79 downto 0) <= rx_data(79 downto 0);
                            waitDataBack <= '1';
                        else
                            tx_data_length <= x"0024"; -- 35+1 bytes
                            -- Wrong command length
                            tx_data(287 downto 0) <= x"02_57726f6e672064617461206c656e6774682e204d75737420626520383820626974732e";
                        end if;
		            -- command was not recognised
		            when others =>
		                StartSending <= not StartSending;
		                tx_data_length <= x"0001"; -- 1 byte
		                tx_data(7 downto 0) <= x"ff";
		        end case; 
		    end if;
		end if;
	   end process;
   
--   U_ILA : ila_0
--    port map
--    (
--        clk => userclk2,
--        probe0(0) => StartSending,
--        probe1(0) => ReceivedData,
--        probe2(0) => gtrefclk_bufg_out,
--        probe3(0) => gmii_tx_en_int,
--        probe4(0) => gmii_rx_dv_int,
--        probe5    => gmii_rxd_int,
--        probe6    => gmii_txd_int,
--        probe7    => rx_data_length
--    );                          

end Behavioral;
