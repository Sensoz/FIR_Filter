library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;

entity FD_G is
	Generic(NBIT: integer:= 16	-- NBIT Flip Flop
			);
	Port (	D     :	In	std_logic_vector(NBIT-1 downto 0);
			CK    :	In	std_logic;
			RESET :	In  std_logic;
			EN    : In  std_logic;
			Q     :	Out	std_logic_vector(NBIT-1 downto 0));
end FD_G;


architecture PIPPO of FD_G is -- flip flop D with syncronous reset

begin
	PSYNCH: process(CK,RESET)
	begin
	  if CK'event and CK='1' then -- positive edge triggered:
	    if RESET='1' then -- active high reset 
	      Q <= (others => '0'); 
	    elsif EN = '1' then
	      Q <= D; -- input is written on output
	    end if;
	  end if;
	end process;

end PIPPO;