library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity d_register is
  Port (
        clk : IN std_logic;
        X_center, X_left, X_right : out std_logic_vector(15 downto 0);
        X_data : in std_logic_vector (15 downto 0);
        START : in std_logic;
        BTNC, BTNL, BTNR : in std_logic
        );
end d_register;

architecture Behavioral of d_register is
begin
    
    -- CAN MAKE 1 PROCESS, get rid of BTNx in sensitivity list
    load_center : PROCESS (clk)
    BEGIN
        IF (rising_edge(clk)) THEN
            IF (START = '0' AND BTNC = '1') THEN
                X_center <= X_DATA;
            END IF;
        END IF;
    END PROCESS load_center;
        
    load_left : PROCESS (clk)
    BEGIN
        IF (rising_edge(clk)) THEN
            IF (START = '0' AND BTNL = '1') THEN
                X_left <= X_DATA;
            END IF;
        END IF;
    END PROCESS load_left;
    
    load_right : PROCESS (clk)
    BEGIN
        IF (rising_edge(clk)) THEN
            IF (START = '0' AND BTNR = '1') THEN
                X_right <= X_DATA;
            END IF;
        END IF;
    END PROCESS load_right;


end Behavioral;
