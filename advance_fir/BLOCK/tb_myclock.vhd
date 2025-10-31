library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clockGen is
	port(
		ENDSIM : IN std_logic;
		CLK_i  : OUT std_logic;
		RST_i  : OUT std_logic
	);
end entity clockGen;

architecture myCLK of clockGen is
	constant period : time := 10 ns;
	signal clk: std_logic := '1';
		
begin

	clkk : process
	begin
		if ENDSIM = '0' then
			clk <= not clk;
			
		end if;
		wait for period/2;
	end process clkk;
	
	
	rstt: process
	begin
		RST_i <= '1';
		wait for 3*period;
		RST_i <= '0';
		wait;
	end process rstt;
	
	CLK_i <= clk and not(ENDSIM);

end architecture myCLK;