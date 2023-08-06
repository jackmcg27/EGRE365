library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity LED_Controller is
  Port (clk : in std_logic;
        SW : in std_logic_vector(3 downto 0);
        XAXIS_DATA, YAXIS_DATA, ZAXIS_DATA : in std_logic_vector(15 downto 0);
        LED : out std_logic_vector(15 downto 0);
        BTNC : in std_logic;
        BTNL : in std_logic;
        BTNR : in std_logic;
        START : in std_logic;
        reset : in std_logic 
        );
end LED_Controller;

architecture Behavioral of LED_Controller is
SIGNAL left_delta, right_delta : std_logic_vector(15 downto 0);
SIGNAL tiltmeter : std_logic_vector(15 downto 0);
SIGNAL X_center, X_left, X_right : std_logic_vector(15 downto 0);
SIGNAL center_int, left_int, right_int : integer;
SIGNAL left_delta_int, right_delta_int : integer;
begin
    -- make integer signals for ease of simulation view
    center_int <= to_integer(signed(X_center));
    left_int <= to_integer(signed(X_left));
    right_int <= to_integer(signed(X_right));
    left_delta_int <= to_integer(signed(left_delta));
    right_delta_int <= to_integer(signed(right_delta));
    
    -- D registers to store left, right and center data
    load_center : PROCESS (clk, reset)
    BEGIN
        IF (reset = '0') THEN
            X_center <= "0000000000000000";
        ELSIF (rising_edge(clk)) THEN
            IF (START = '0' AND BTNC = '1') THEN
                X_center <= XAXIS_DATA;
            END IF;
        END IF;
    END PROCESS load_center;
    
    load_left : PROCESS (clk, reset)
    BEGIN
        IF (reset = '0') THEN
            X_left <= "0000000000000000";
        ELSIF (rising_edge(clk)) THEN
            IF (START = '0' AND BTNL = '1') THEN
                X_left <= XAXIS_DATA;
            END IF;
        END IF;
    END PROCESS load_left;
    
    load_right : PROCESS (clk, reset)
    BEGIN
        IF (reset = '0') THEN
            X_right <= "0000000000000000";
        ELSIF (rising_edge(clk)) THEN
            IF (START = '0' AND BTNR = '1') THEN
                X_right <= XAXIS_DATA;
            END IF;
        END IF;
    END PROCESS load_right;
    
    -- Difference between left and center values
    CALC_LEFT_DELTA : PROCESS (X_center, X_left)
    variable left_int, center_int : integer;
    BEGIN
        left_int := to_integer(signed(X_left));
        center_int := to_integer(signed(X_center));
        left_delta <= std_logic_vector(to_signed(left_int - center_int, 16));
    END PROCESS CALC_LEFT_DELTA;
    
    -- Difference between center and right values
    CALC_RIGHT_DELTA : PROCESS (X_center, X_right)
    variable right_int, center_int : integer;
    BEGIN
        right_int := to_integer(signed(X_right));
        center_int := to_integer(signed(X_center));
        right_delta <= std_logic_vector(to_signed(center_int - right_int, 16));
    END PROCESS CALC_RIGHT_DELTA;
    
    interpolation : PROCESS (left_delta, right_delta, X_center, XAXIS_DATA)
    variable left_delta_int, right_delta_int, current_int, left_step, right_step, center_int : integer;
    BEGIN
        -- Make data into integers to work with
        center_int := to_integer(signed(X_center));
        left_delta_int := to_integer(signed(left_delta));
        right_delta_int := to_integer(signed(right_delta));
        current_int := to_integer(signed(XAXIS_DATA));
        left_step := left_delta_int / 7;
        right_step := right_delta_int / 7;
        
        -- Default value at center
        tiltmeter <= "0000000010000000"; 
        
        IF current_int > center_int THEN -- current int > center means left tilt
            IF (current_int > center_int + (7 * abs(left_step))) THEN
                tiltmeter <= "0100000010000000";
            ELSIF (current_int > center_int + (6 * abs(left_step))) THEN
                tiltmeter <= "0010000010000000";
            ELSIF (current_int > center_int + (5 * abs(left_step))) THEN
                tiltmeter <= "0001000010000000";
            ELSIF (current_int > center_int + (4 * abs(left_step))) THEN
                tiltmeter <= "0000100010000000";
            ELSIF (current_int > center_int + (3 * abs(left_step))) THEN
                tiltmeter <= "0000010010000000";
            ELSIF (current_int > center_int + (2 * abs(left_step))) THEN
                tiltmeter <= "0000001010000000";    
            ELSIF (current_int > center_int + abs(left_step)) THEN
                tiltmeter <= "0000000110000000";
            END IF;          
        ELSIF current_int < center_int THEN -- current int < center means right tilt
            IF (current_int < center_int - (7 * abs(right_step))) THEN
                tiltmeter <= "0000000010000001";
            ELSIF (current_int < center_int - (6 * abs(right_step))) THEN
                tiltmeter <= "0000000010000010";
            ELSIF (current_int < center_int - (5 * abs(right_step))) THEN
                tiltmeter <= "0000000010000100";
            ELSIF (current_int < center_int - (4 * abs(right_step))) THEN
                tiltmeter <= "0000000010001000";
            ELSIF (current_int < center_int - (3 * abs(right_step))) THEN
                tiltmeter <= "0000000010010000";
            ELSIF (current_int < center_int - (2 * abs(right_step))) THEN
                tiltmeter <= "0000000010100000";
            ELSIF (current_int < center_int - abs(right_step)) THEN
                tiltmeter <= "0000000011000000";
            END IF;
        END IF;   
    END PROCESS interpolation;

    LED_select : PROCESS (SW, XAXIS_DATA, YAXIS_DATA, ZAXIS_DATA, X_center, X_left, X_right, BTNC, tiltmeter, left_delta, right_delta)
    BEGIN
        CASE SW IS
        WHEN "0000" => -- Live x axis data
            LED <= XAXIS_DATA;
        WHEN "0001" => -- Live Y axis data
            LED <= YAXIS_DATA;
        WHEN "0010" => -- Live Z axis data
            LED <= ZAXIS_DATA;
        When "0011" => -- Stored center value
            LED <= X_center;
        WHEN "0100" => -- Stored left value
            LED <= X_left;
        WHEN "0101" => -- Stored right value
            LED <= X_right;
        WHEN "0110" => -- Left - center
            LED <= left_delta;
        WHEN "0111" => -- center - right
            LED <= right_delta;
        WHEN "1000" => -- LED moves based on tilt
            LED <= tiltmeter;
        WHEN "1111" => -- Debugging to make sure button works
            LED(15) <= BTNC;
        WHEN others => -- Any other input gets all 0 (lights off)
            LED <= (others => '0');
        END CASE;    
    END PROCESS LED_select;

end Behavioral;
