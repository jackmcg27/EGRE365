library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity top_level is
    Port (CPU_RESETN  : in  STD_LOGIC;
		  SYS_CLK : in STD_LOGIC;
		  LED       : out  STD_LOGIC_VECTOR(15 downto 0);
		  SW       : in  STD_LOGIC_VECTOR(15 downto 0);
		  SCK       : out  STD_LOGIC;
		  CS       : out  STD_LOGIC;
		  MOSI       : out  STD_LOGIC;
          MISO        : in STD_LOGIC;
          BTNC, BTNL, BTNR : in std_logic);
end top_level;

architecture Behavioral of top_level is
COMPONENT spi_controller
	GENERIC (
		N : INTEGER := 8; -- number of bit to serialize
	    CLK_DIV : INTEGER := 100); -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(2*CLK_DIV)
	PORT (
		i_clk : IN std_logic;
		i_rstb : IN std_logic;
		i_tx_start : IN std_logic; -- start TX on serial line
		o_tx_end : OUT std_logic; -- TX data completed; o_data_parallel available
		i_data_parallel : IN std_logic_vector(N - 1 DOWNTO 0); -- data to send
		o_data_parallel : OUT std_logic_vector(N - 1 DOWNTO 0); -- received data
		o_sclk : OUT std_logic;
		o_ss : OUT std_logic;
		o_mosi : OUT std_logic;
		i_miso : IN std_logic
	);
END COMPONENT;

COMPONENT spi_controller_fsm
	PORT (
		XAXIS_DATA_OUT, YAXIS_DATA_OUT, ZAXIS_DATA_OUT : OUT std_logic_vector(15 DOWNTO 0); 
		i_clk, i_rstb : IN std_logic;
		i_data_parallel : IN std_logic_vector(15 DOWNTO 0);
		o_data_parallel : OUT std_logic_vector(15 DOWNTO 0);
		o_data_ready : OUT std_logic;
		o_tx_start : OUT std_logic;
		i_tx_end : IN std_logic;
		START : IN std_logic
	);
END COMPONENT;

COMPONENT clock_divider
    GENERIC (
        divisor : integer := 50000000);
    PORT (
        mclk : in std_logic;
        sclk : out std_logic
    );
END COMPONENT;

COMPONENT LED_controller
    PORT (
        clk : in std_logic;
        SW : in std_logic_vector(3 downto 0);
        XAXIS_DATA, YAXIS_DATA, ZAXIS_DATA : in std_logic_vector(15 downto 0);
        LED : out std_logic_vector(15 downto 0);
        BTNC, BTNR, BTNL : in std_logic;
        START : in std_logic;
        reset : in std_logic
        );
END COMPONENT;

COMPONENT switchDebouncer
    GENERIC (
        CLK_FREQ : positive := 100_000_000);
    PORT (
        clk       : in  std_logic;
        reset     : in  std_logic;
        switchIn  : in  std_logic;
        switchOut	 : out std_logic
        );
END COMPONENT;

SIGNAL tx_start_s : std_logic := '0';
SIGNAL tx_end_s : std_logic;
SIGNAL XAXIS_DATA_SIG : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL YAXIS_DATA_SIG : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL ZAXIS_DATA_SIG : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL o_data_parallel_s : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL i_data_parallel_s : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL START_sig : std_logic := '0';
SIGNAL CENTER_sig, LEFT_sig, RIGHT_sig : std_logic;
SIGNAL X_CENTER_SIG, X_LEFT_SIG, X_RIGHT_SIG : std_logic_vector(15 downto 0);
		
begin
    spi_controller_1 : spi_controller
        GENERIC MAP  (
            N => 16,
            CLK_DIV => 100)
        PORT MAP (
            i_clk => SYS_CLK,
            i_rstb => CPU_RESETN,
            i_tx_start => tx_start_s,
            o_tx_end => tx_end_s, 
			i_data_parallel => i_data_parallel_s, 
			o_data_parallel => o_data_parallel_s, 
			o_sclk => SCK, 
			o_ss => CS, 
			o_mosi => MOSI, 
			i_miso => MISO
        );
        
    spi_controller_fsm_1 : spi_controller_fsm
        PORT MAP (
            i_clk => SYS_CLK, 
			i_rstb => CPU_RESETN, 
			START => START_SIG, 
			o_tx_start => tx_start_s, 
			o_data_parallel => i_data_parallel_s, 
			i_tx_end => tx_end_s, 
			i_data_parallel => o_data_parallel_s, 
			XAXIS_DATA_OUT => XAXIS_DATA_SIG, 
			YAXIS_DATA_OUT => YAXIS_DATA_SIG, 
			ZAXIS_DATA_OUT => ZAXIS_DATA_SIG
		);
		
	clock_divider_1 : clock_divider
	   PORT MAP (
	       mclk => SYS_CLK,
	       sclk => START_sig
	   );
	   
	center_button : switchDebouncer
	   PORT MAP (
	       clk => SYS_CLK,
	       reset => CPU_RESETN,
	       switchIn => BTNC,
	       switchOut => CENTER_sig
	   );
	   
	left_button : switchDebouncer
	   PORT MAP (
	       clk => SYS_CLK,
	       reset => CPU_RESETN,
	       switchIn => BTNL,
	       switchOut => LEFT_sig
	   );
	   
	right_button : switchDebouncer
	   PORT MAP (
	       clk => SYS_CLK,
	       reset => CPU_RESETN,
	       switchIn => BTNR,
	       switchOut => RIGHT_sig
	   );
	   
	LED_conroller_1 : LED_controller
	   PORT MAP (
	       clk => SYS_CLK,
	       LED => LED,
	       XAXIS_DATA => XAXIS_DATA_SIG,
	       YAXIS_DATA => YAXIS_DATA_SIG,
	       ZAXIS_DATA => ZAXIS_DATA_SIG,
	       SW => SW(3 downto 0),
	       BTNC => CENTER_sig,
	       BTNL => LEFT_sig,
	       BTNR => RIGHT_sig,
	       START => START_sig,
	       reset => CPU_RESETN
	   );
	   
end Behavioral;
