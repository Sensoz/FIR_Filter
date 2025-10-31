library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_signed.all;
use work.fir_adv_package.all;

entity pipelined_block is
	port(
		DATAIN  : IN p_data;
		EN      : IN std_logic;
		CLK     : IN std_logic;
		RST     : IN std_logic;
		COEF    : IN p_data;
		DATAOUT : OUT std_logic_vector(13 downto 0);
		VOUT    : OUT std_logic
	);
end entity pipelined_block;


architecture pipe_4_stages of pipelined_block is
	component FD_G
		Generic(NBIT: integer	-- NBIT Flip Flop can be used both in arch and entity
				);
				
		Port (	D:		In	std_logic_vector(NBIT-1 downto 0);  --depends on the filter order
					CK:		In	std_logic;
					RESET:	In	std_logic;
					EN   : In std_logic;
					Q:		Out	std_logic_vector(NBIT-1 downto 0)
			);
	end component;
	
	component fd 
		Port (		D     :	In	std_logic;
					CK    :	In	std_logic;
					RESET :	In	std_logic;
					EN    : In std_logic;
					Q     :	Out	std_logic
			);
	end component;
	
	type t_mul_out     is array (10 downto 0) of std_logic_vector(27 downto 0);
	type t_in          is array (10 downto 0) of std_logic_vector(13 downto 0);
	type t_adder_in    is array (10 downto 0) of std_logic_vector(14 downto 0);
	type t_adder_out   is array (10 downto 1) of std_logic_vector(14 downto 0);
	type t_add_pipe    is array  (2 downto 0) of std_logic_vector(14 downto 0);
	
	signal o_mul           : t_mul_out;
	signal i_adder_0       : t_adder_in;
	signal i_adder_1       : t_adder_in;
	signal i_adder_2       : t_adder_in;
	signal i_adder_3       : t_adder_in;
	signal i_adder_4       : t_adder_in;
	signal o_adder	       : t_adder_out;
	signal o_adder_delayed : t_add_pipe;	  -- pipeline registers' output on adder chain 
	
	signal enables: std_logic_vector(3 downto 0);	-- enable signals for pipelines
	signal mux_sel: std_logic_vector(1 downto 0);
begin	
	
--multiplication
	mull: for i in 0 to 10 generate -- filter order = 10+1
		o_mul(i) <= COEF(i) * DATAIN(i);	
		i_adder_0(i) <= o_mul(i)(27 downto 13);
	end generate mull;
	
-- enable signals	
	enables(0) <= EN;
	ena: for x in 0 to 2 generate
		enab: fd 
			port map(
				D     => enables(x),
				CK    => CLK,
				RESET => RST,
				EN    => '1',
			    Q     => enables(x+1)
			);
	end generate ena;
	
-- first pipeline
	pipeline1 : for x in 0 to 10 generate
	FD_P1 : FD_G
	generic map(NBIT => 15)
				port map(
					D     => i_adder_0(x),	-- output of multiplier
					CK    => CLK,
					RESET => RST,
					EN    => enables(0),
					Q     => i_adder_1(x)		-- output of first pipeline
				);
	end generate pipeline1;

-- second pipeline	
	pipeline2 : for x in 0 to 10 generate
		r: if x < 4 generate
			i_adder_2(x) <= i_adder_1(x);	-- transfer unpipe signals
		end generate r;
		sec: if x > 3 generate	
			FD_P2 : FD_G
			generic map(NBIT => 15)
						port map(
							D     => i_adder_1(x),
							CK    => CLK,
							RESET => RST,
							EN    => enables(1),
							Q     => i_adder_2(x)
						);
		end generate sec;
	end generate pipeline2;	
	
-- third pipeline
	pipeline3 : for x in 0 to 10 generate
		rr: if x < 7 generate
			i_adder_3(x) <= i_adder_2(x);
		end generate rr;
		thrd: if x > 6 generate
			FD_P3 : FD_G
			generic map(NBIT => 15)
						port map(
							D     => i_adder_2(x),
							CK    => CLK,
							RESET => RST,
							EN    => enables(2),
							Q     => i_adder_3(x)
						);
		end generate thrd;
	end generate pipeline3;	

-- fourth pipeline
	pipeline4: for x in 0 to 10 generate
		rrr: if x < 10 generate
			i_adder_4(x) <= i_adder_3(x);
		end generate rrr;
		forth: if x = 10 generate
			FD_P4 : FD_G
			generic map(NBIT => 15)
						port map(
							D     => i_adder_3(x),
							CK    => CLK,
							RESET => RST,
							EN    => enables(3),
							Q     => i_adder_4(x)
						);
		end generate forth;
	end generate pipeline4;	
	
-- adder chain registers
	-- first FD on chain
	FD_P5 : FD_G
	generic map(NBIT => 15)
			port map(
				D     => o_adder(3),	-- output of multiplier
				CK    => CLK,
				RESET => RST,
				EN    => enables(1),
				Q     => o_adder_delayed(0)		-- output of first pipeline
			);
	
	-- second FD on chain
	FD_P6 : FD_G
	generic map(NBIT => 15)
			port map(
				D     => o_adder(6),	-- output of multiplier
				CK    => CLK,
				RESET => RST,
				EN    => enables(2),
				Q     => o_adder_delayed(1)		-- output of first pipeline
			);
	-- third FD on chain
	FD_P7 : FD_G
	generic map(NBIT => 15)
			port map(
				D     => o_adder(9),	-- output of multiplier
				CK    => CLK,
				RESET => RST,
				EN    => enables(3),
				Q     => o_adder_delayed(2)		-- output of first pipeline
			);

-- addition
	o_adder(1)  <= i_adder_4(0)  + i_adder_4(1);
	o_adder(2)  <= i_adder_4(2)  + o_adder(1);
	o_adder(3)  <= i_adder_4(3)  + o_adder(2);
	o_adder(4)  <= i_adder_4(4)  + o_adder_delayed(0);
	o_adder(5)  <= i_adder_4(5)  + o_adder(4);
	o_adder(6)  <= i_adder_4(6)  + o_adder(5);	
	o_adder(7)  <= i_adder_4(7)  + o_adder_delayed(1);	
	o_adder(8)  <= i_adder_4(8)  + o_adder(7);	
	o_adder(9)  <= i_adder_4(9)  + o_adder(8);	
	o_adder(10) <= i_adder_4(10) + o_adder_delayed(2);	
				
-- Output MUX. Consider max and min values
	mux_sel <= o_adder(10)(14 downto 13);
	with mux_sel select
		DATAOUT <= "01111111111111"         when "01",
				   "10000000000000"         when "10",
				   o_adder(10)(13 downto 0)	when others;	
-- Valid output				
	VOUT <= enables(3);
	
end architecture pipe_4_stages;