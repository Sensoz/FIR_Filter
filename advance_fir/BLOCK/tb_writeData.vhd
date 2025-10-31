Library IEEE;
use IEEE.Std_Logic_1164.all; 
use IEEE.Std_Logic_Unsigned.all;
use STD.textio.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use work.fir_adv_package.all;

entity testFIR is
	port(
		t_CLK  : IN std_logic;
		t_RST  : IN std_logic;
		t_VIN  : IN std_logic;
		t_DIN  : IN p_data;
		t_COEF : IN p_data;
		t_DOUT : OUT std_logic_vector(13 downto 0);
		t_VOUT : OUT std_logic
	);
end entity testFIR;


architecture test of testFIR is

	component pipelined_block is
		port(
			DATAIN  : IN p_data;
			EN      : IN std_logic;
			CLK     : IN std_logic;
			RST     : IN std_logic;
			COEF    : IN p_data;
			DATAOUT : OUT std_logic_vector(13 downto 0);
			VOUT    : OUT std_logic
		);
	end component pipelined_block;

	signal s_dout: std_logic_vector(13 downto 0);
	signal s_vout: std_logic;
begin
	
	dut: pipelined_block port map(
								  CLK => t_CLK,
								  RST => t_RST,
								  DATAIN => t_DIN,
								  EN => t_VIN,
								  COEF => t_COEF,
								  DATAOUT => s_dout,
								  VOUT => s_vout
								);
-- outputs from filter
	t_DOUT <= s_dout;
	t_VOUT <= s_vout;
	
	p_write:process(t_CLK,t_RST)
		file o_file  : text open write_mode is "resultsVHDL.txt";
		variable o_line: line;
		variable t_out: signed(13 downto 0);
		variable t_out_int: integer;
	begin
		if t_RST = '1' then
			null;
		elsif t_CLK'event and t_CLK = '1' then
			if s_vout = '1' then
				t_out := signed(s_dout);
				t_out_int := to_integer(t_out);
				write(o_line, t_out_int);
				writeline(o_file, o_line);
			end if;
		end if;
	end process p_write;

end architecture test;