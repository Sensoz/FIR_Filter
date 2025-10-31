library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity data_sink is
  port (
		CLK        : in std_logic;
		RST        : in std_logic;
		VIN        : in std_logic;
		DIN_3k     : in std_logic_vector(13 downto 0);
		DIN_3k_1   : in std_logic_vector(13 downto 0);
		DIN_3k_2   : in std_logic_vector(13 downto 0)
	);
end data_sink;

architecture beh of data_sink is

begin  -- beh

  process (CLK, RST)
    file res_fp : text open WRITE_MODE is "results_adv_hdl.txt";
    variable line_out : line;
    file fp_in : text open READ_MODE is "resultsC_15bit.txt";
    variable line_in : line;    
    variable x : integer;
    variable cnt : integer := 0;
  begin  -- process
    if RST = '1' then                 -- asynchronous reset (active low)
      cnt := 0;
    elsif CLK'event and CLK = '1' then  -- rising clock edge
      if (VIN = '1') then
        write(line_out, conv_integer(signed(DIN_3k)));
        writeline(res_fp, line_out);
		write(line_out, conv_integer(signed(DIN_3k_1)));
        writeline(res_fp, line_out);
		write(line_out, conv_integer(signed(DIN_3k_2)));
        writeline(res_fp, line_out);

        cnt := cnt + 1;
      end if;
    end if;
  end process;

end beh;
