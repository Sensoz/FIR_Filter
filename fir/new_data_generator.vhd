library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;
use std.textio.all;

entity dataGen is
	port(
		CLK      : in  std_logic;					
		RST      : in  std_logic; 
		IN_VALID : in  std_logic;
		VOUT     : out std_logic;                       
		DOUT     : out std_logic_vector(13 downto 0);   
		COEF	 : out std_logic_vector(153 downto 0);  
		END_SIM  : out std_logic              
	);
end entity dataGen;
	
	
	
	
architecture dataMaker of dataGen is	
	constant tco 	: time := 0.5 ns;
	signal endsim_i: std_logic := '0';
	signal END_SIM_i: std_logic_vector(0 to 10); 
begin	
	
	COEF( 13 downto 0)    <= std_logic_vector(to_signed(0,    14));
	COEF( 27 downto 14)   <= std_logic_vector(to_signed(76,   14));
	COEF( 41 downto 28)   <= std_logic_vector(to_signed(389,  14));
	COEF( 55 downto 42)   <= std_logic_vector(to_signed(1002, 14));
	COEF( 69 downto 56)   <= std_logic_vector(to_signed(1656, 14));
	COEF( 83 downto 70)   <= std_logic_vector(to_signed(1941, 14));
	COEF( 97 downto 84)   <= std_logic_vector(to_signed(1656, 14));
	COEF( 111 downto 98)  <= std_logic_vector(to_signed(1002, 14));
	COEF( 125 downto 112) <= std_logic_vector(to_signed(389,  14));
	COEF( 139 downto 126) <= std_logic_vector(to_signed(76,   14));	
	COEF( 153 downto 140) <= std_logic_vector(to_signed(0,    14));
	
	main: process(CLK, RST)
		file in_file : text open read_mode is "samples.txt";
		variable in_line  : line;
		variable in_14bit : integer;
		variable counter: integer := 0;
	begin
	
		if RST = '1' then
			DOUT <= (others => '0');      
			VOUT <= '0';
			endsim_i <= '0';
		elsif CLK'event and CLK = '1' then
			if IN_VALID = '1' then	-- read data	
				if not endfile(in_file) then	-- read from txt and give it to output
					readline(in_file,in_line);
					read(in_line,in_14bit);
					DOUT <= std_logic_vector(to_signed(in_14bit, DOUT'length));
					VOUT <= '1';				
					endsim_i <= '0';
				else
					VOUT <= '0';
					endsim_i <= '1';
				end if;
			else
				VOUT <= '0' after 1 ns;
				DOUT <= (others => 'U');
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