library IEEE;
use IEEE.std_logic_1164.all; 
--use IEEE.NUMERIC_STD.all;
use ieee.std_logic_signed.all;
-- Filter order = 10
-- Number of bits = 14
entity FIR_filter is
	port(
		CLK :  IN std_logic;
		RST :  IN std_logic;
		DIN :  IN std_logic_vector(13 downto 0);
		VIN :  IN std_logic;
		COEF : IN std_logic_vector(153 downto 0);	-- 14-bits*(10+1)=154 bits - all coefficients at once / depends on # of bits
		
		DOUT : OUT std_logic_vector(13 downto 0);
		VOUT : OUT std_logic
	);
end FIR_filter;

architecture myfilter of FIR_filter is
	
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
		Port (	D:		In	std_logic;
					CK:		In	std_logic;
					RESET:	In	std_logic;
					EN   : In std_logic;
					Q:		Out	std_logic
			);
	end component;
	
	type mulType   is array (10 downto 0) of std_logic_vector(27 downto 0);	-- output of multipliers
	type shift_reg is array (10 downto 0) of std_logic_vector(13 downto 0);	-- same with input bits
	type addType   is array (9 downto 0) of std_logic_vector(14 downto 0); -- add outputs from multipliers
	type addType2   is array (10 downto 0) of std_logic_vector(14 downto 0);
-- internal signals	
	signal o_mul 	: mulType;	   -- 11 multipliers with 24 bit output
	signal i_reg 	: shift_reg;   -- internal registers' inputs and coefficients 
	signal o_add	: addType;	   -- 10 adders' outputs
	signal IN_COEF	: shift_reg;
	signal i_add	: addType2;
-- input/output registers	
	signal IN_VIN, OUT_VOUT: std_logic;	-- valid signals
	signal IN_DIN, OUT_DOUT, OUT_DOUT_SELECT: std_logic_vector(13 downto 0);	
	
	signal mux_sel: std_logic_vector(1 downto 0);
begin	
  
-- Input Valid register	
	FD_VIN: fd port map(
				D 	  => VIN,
				CK 	  => CLK,
				RESET => RST,
				EN    => '1',
				Q     => IN_VIN
			);

-- Input Data Register
	FD_DATAIN:FD_G
				generic map(NBIT => 14)
				port map(
					D     => DIN,
					CK    => CLK,
					RESET => RST,
					EN    => '1',
					Q     => IN_DIN
				); 

-- Coefficient registers
	coefficients: for c in 0 to 10 generate	-- filter order = 10+1
		FD_COEF: FD_G
				generic map(NBIT => 14)
				port map(
					D     => COEF(14*(c+1)-1 downto 14*c),
					CK    => CLK,
					RESET => RST,
					EN    => '1',
					Q     => IN_COEF(c)
				);
	end generate coefficients;
				
-- Output valid register
	FD_VOUT: fd port map(
				D 	  => IN_VIN,
				CK 	  => CLK,
				RESET => RST,
				EN    => '1',
				Q     => OUT_VOUT
			);


-- DIN Shift registers
	i_reg(0) <= IN_DIN;
	reg_loop: for r in 0 to 9 generate	-- filter order = 10
		inner_regs: FD_G
					generic map(NBIT => 14)
					port map(
						D     => i_reg(r),
						CK    => CLK,
						RESET => RST,
						EN    => IN_VIN,
						Q     => i_reg(r+1)
					);
	end generate reg_loop;
-- Arithmetic
	mull: for i in 0 to 10 generate -- filter order = 10+1
		o_mul(i) <= IN_COEF(i) * i_reg(i);	-- output of multiplier is 28-bits
	end generate mull;
	
	addi: for m in 0 to 10 generate
		i_add(m) <= o_mul(m)(27 downto 13);
	end generate addi;
	
	add: for i in 0 to 9 generate -- filter order = 10
		one: if i = 0 generate
			o_add(0) <= i_add(0) + i_add(1);	-- 15 bit
		end generate one;
		rest: if i > 0 generate
			o_add(i) <= i_add(i+1) + o_add(i-1);
		end generate rest;
	end generate add;
	
-- Output MUX. Consider max and min values
	mux_sel <= o_add(9)(14 downto 13);
	with mux_sel select
		OUT_DOUT_SELECT <= "01111111111111"       when "01",
						   "10000000000000"       when "10",
						   o_add(9)(13 downto 0)  when others;
-- Output register
		FD_DATAOUT:FD_G
				generic map(NBIT => 14)
				port map(
					D     => OUT_DOUT_SELECT,
					CK    => CLK,
					RESET => RST,
					EN    => IN_VIN,
					Q     => OUT_DOUT
				); 	
-- output
	DOUT <= OUT_DOUT;
	VOUT <= OUT_VOUT;
	
end myfilter;


















