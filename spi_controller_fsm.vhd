library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity spi_controller_fsm is
  Port (XAXIS_DATA_OUT, YAXIS_DATA_OUT, ZAXIS_DATA_OUT : out std_logic_vector(15 downto 0);
  
        i_clk, i_rstb : in std_logic;
        i_data_parallel : in std_logic_vector(15 downto 0);
        o_data_parallel : out std_logic_vector(15 downto 0);
        o_data_ready : out std_logic;
        o_tx_start : out std_logic;
        i_tx_end : in std_logic;
        START : in std_logic);
end spi_controller_fsm;

architecture Behavioral of spi_controller_fsm is
    TYPE state_type is (START_WAIT, START_TRANS, TRANS_WAIT, END_TRANS, END_TRANS_WAIT, END_WAIT);
    
    SIGNAL present_state, next_state : state_type;
    
    type output_value_array is array (1 to 8) of std_logic_vector(15 downto 0);
                                                
    constant i_data_values : output_value_array := (std_logic_vector(to_unsigned(16#2C08#,16)),
                                                std_logic_vector(to_unsigned(16#2D08#,16)),
                                                std_logic_vector(to_unsigned(16#B201#,16)),
                                                std_logic_vector(to_unsigned(16#B302#,16)),
                                                std_logic_vector(to_unsigned(16#B403#,16)),
                                                std_logic_vector(to_unsigned(16#B504#,16)),
                                                std_logic_vector(to_unsigned(16#B605#,16)),
                                                std_logic_vector(to_unsigned(16#B706#,16)));
                                                
    SIGNAL present_count, next_count : integer RANGE 1 to 8;
    
BEGIN
    
    -- Memory process
    clocked : PROCESS (i_clk, i_rstb)
    BEGIN
        IF (i_rstb = '0') THEN
            present_state <= START_WAIT;
            present_count <= 1;
        ELSIF (rising_edge(i_clk)) THEN
            present_state <= next_state;
            present_count <= next_count;
        END IF;
    END PROCESS clocked;
    
    -- Main state machine - control transitions
    nextstate : PROCESS (present_state, START, i_tx_end, present_count)
    BEGIN
        next_count <= present_count;
        CASE present_state is
        WHEN START_WAIT => -- Wait for transmission to begin
            IF (START = '1') THEN
                next_state <= START_TRANS;
                next_count <= 1; 
            ELSE
                next_state <= present_state;
            END IF;
        WHEN START_TRANS => -- Just wait a clock cycle
                next_state <= TRANS_WAIT;
        WHEN TRANS_WAIT => -- Also just wait a clock cycle
                next_state <= END_TRANS;
        WHEN END_TRANS => -- Wait for core to send back signal that data is ready and then read the data
            IF (i_tx_end = '1') THEN
                IF (present_count = 8) THEN
                    next_state <= END_WAIT;
                ELSE
                     next_state <= END_TRANS_WAIT;
                 END IF;
            ELSE
                next_state <= END_TRANS;
            END IF;
        WHEN END_TRANS_WAIT =>
            next_count <= present_count + 1;
            next_state <= START_TRANS;
        WHEN END_WAIT => -- Wait for start to go low again since its a longer signal
            IF (START = '0') THEN
                next_state <= START_WAIT;
            ELSE
                next_state <= present_state;
            END IF;
        END CASE;
    END PROCESS nextstate;
    
    -- Output for the core to go off of
    output : PROCESS (present_state)
    BEGIN
        o_data_parallel <= i_data_values(present_count);
        o_tx_start <= '0';
        o_data_ready <= '0';
        CASE present_state IS
            WHEN START_WAIT =>
            WHEN START_TRANS =>
                o_tx_start <= '1';
            WHEN TRANS_WAIT =>
            WHEN END_TRANS =>
            WHEN END_TRANS_WAIT =>
                o_data_ready <= '1';
            WHEN END_WAIT =>             
        END CASE;
    END PROCESS output;
    
    -- Output for the axis data
    data_output : PROCESS (i_clk)
    BEGIN
        IF rising_edge(i_clk) THEN
            IF (present_state = END_TRANS AND i_tx_end = '1') THEN
                    CASE present_count IS
                        WHEN 3 =>
                            XAXIS_DATA_OUT(7 downto 0) <= i_data_parallel(7 downto 0);
                        WHEN 4 =>
                            XAXIS_DATA_OUT(15 downto 8) <= i_data_parallel(7 downto 0);
                        WHEN 5 =>
                            YAXIS_DATA_OUT(7 downto 0) <= i_data_parallel(7 downto 0);
                        WHEN 6 =>
                            YAXIS_DATA_OUT(15 downto 8) <= i_data_parallel(7 downto 0);
                        WHEN 7 =>
                            ZAXIS_DATA_OUT(7 downto 0) <= i_data_parallel(7 downto 0);
                        WHEN 8 =>
                            ZAXIS_DATA_OUT(15 downto 8) <= i_data_parallel(7 downto 0);
                        WHEN OTHERS =>
                     END CASE;
                 END IF;
             END IF;
     END PROCESS data_output;
end Behavioral;
