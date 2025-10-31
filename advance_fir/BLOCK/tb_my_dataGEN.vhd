library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.fir_adv_package.all;

entity dataGen is
	port(
		CLK      : in  std_logic;					
		RST      : in  std_logic; 
		IN_VALID : in  std_logic;
		VOUT     : out std_logic;                       
		DOUT     : out p_data;   
		COEF	 : out p_data;  
		END_SIM  : out std_logic              
	);
end entity dataGen;
	
	
	
	
architecture dataMaker of dataGen is	
	constant tco 	: time := 0.5 ns;
	signal endsim_i: std_logic := '0';
	signal END_SIM_i: std_logic_vector(0 to 10);
	signal data_arr: p_data := (others => (others => '0'));
	signal indata: std_logic_vector(13 downto 0);
begin	
	
	COEF(0)  <= std_logic_vector(to_signed(0,    14));
	COEF(1)  <= std_logic_vector(to_signed(76,   14));
	COEF(2)  <= std_logic_vector(to_signed(389,  14));
	COEF(3)  <= std_logic_vector(to_signed(1002, 14));
	COEF(4)  <= std_logic_vector(to_signed(1656, 14));
	COEF(5)  <= std_logic_vector(to_signed(1941, 14));
	COEF(6)  <= std_logic_vector(to_signed(1656, 14));
	COEF(7)  <= std_logic_vector(to_signed(1002, 14));
	COEF(8) <= std_logic_vector(to_signed(389,  14));
	COEF(9) <= std_logic_vector(to_signed(76,   14));	
	COEF(10) <= std_logic_vector(to_signed(0,    14));
	
	
				
	main: process(CLK, RST)
		file in_file : text open read_mode is "samples.txt";
		variable in_line  : line;
		variable in_14bit : integer;
		variable counter: integer := 0;
	begin
	
		if RST = '1' then
			DOUT <= (others => (others => '0'));      
			VOUT <= '0';
			endsim_i <= '0';
		elsif CLK'event and CLK = '1' then
			if IN_VALID = '1' then	-- read data	
				if not endfile(in_file) then	-- read from txt and give it to output
					readline(in_file,in_line);
					read(in_line,in_14bit);
					data_arr(0) <= std_logic_vector(to_signed(in_14bit, data_arr(0)'length));
					VOUT <= '1';				
					endsim_i <= '0';
					r: for i in 0 to 9 loop
						data_arr(i+1) <= data_arr(i);
					end loop r;				
				else
					VOUT <= '0';
					endsim_i <= '1';
				end if;
				DOUT <= data_arr;
			else
				VOUT <= '0' after 1 ns;
				DOUT <= (others => (others =>'U'));
			end if;
		end if;
	end process main;
	
	process (CLK, RST)
		begin  -- process
			if RST = '1' then                 			-- asynchronous reset (active low)
				END_SIM_i <= (others => '0') after tco;
			elsif rising_edge(CLK) then  					-- rising clock edge
				END_SIM_i(0) <= endsim_i after tco;
				END_SIM_i(1 to 10) <= END_SIM_i(0 to 9) after tco;
			end if;
	end process;
	END_SIM <= END_SIM_i(10);  
	
end architecture dataMaker;