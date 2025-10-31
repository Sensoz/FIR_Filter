library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_signed.all;
use work.fir_adv_package.all;

entity adv_fir is
	port(
		CLK 	    :  IN std_logic;
		RST 	    :  IN std_logic;
		DIN_3k 	    :  IN std_logic_vector(13 downto 0);
		DIN_3k_1    :  IN std_logic_vector(13 downto 0);
		DIN_3k_2    :  IN std_logic_vector(13 downto 0);
		VIN 	    :  IN std_logic;
		COEFFICIENT : IN std_logic_vector(153 downto 0);	-- 14-bits*(10+1)=154 bits - all coefficients at once / depends on # of bits
		
		DOUT_3k   : OUT std_logic_vector(13 downto 0);
		DOUT_3k_1 : OUT std_logic_vector(13 downto 0);
		DOUT_3k_2 : OUT std_logic_vector(13 downto 0);		
		VOUT_3k   : OUT std_logic;
		VOUT_3k_1 : OUT std_logic;
		VOUT_3k_2 : OUT std_logic;
		VOUT	  : OUT std_logic
	);
end entity adv_fir;

architecture myfilterAdv of adv_fir is
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

	component pipelined_block
		port(
			DATAIN  : IN p_data;
			EN      : IN std_logic;
			CLK     : IN std_logic;
			RST     : IN std_logic;
			COEF    : IN p_data;
			DATAOUT : OUT std_logic_vector(13 downto 0);
			VOUT    : OUT std_logic
		);
	end component;
	
	type shift_reg is array (10 downto 0) of std_logic_vector(13 downto 0);	-- same with input bits
	type delay3    is array (3 downto 0) of std_logic_vector(13 downto 0);
	type delay4    is array (4 downto 0) of std_logic_vector(13 downto 0);
	
	signal IN_COEF	: p_data;
	signal i_reg_3k, i_reg_3k_1, i_reg_3k_2 	: shift_reg;   -- internal registers' inputs
	signal pipe_in_3k,pipe_in_3k_1,pipe_in_3k_2 : shift_reg;	   -- to pipeblock in
-- input/output registers	
	signal IN_VIN, OUT_VOUT_3k, OUT_VOUT_3k_1, OUT_VOUT_3k_2: std_logic;				-- valid signals
	signal IN_DIN_3k, IN_DIN_3k_1, IN_DIN_3k_2 		 : std_logic_vector(13 downto 0);	-- input registers' output	
	signal OUT_DOUT_3k, OUT_DOUT_3k_1, OUT_DOUT_3k_2 : std_logic_vector(13 downto 0);	-- output registers' output
-- delayed input data	
	signal IN_DIN_3k_delayed   : delay3;	-- input data_3k with delayed versions
	signal IN_DIN_3k_1_delayed : delay3;	-- input data_3k_1 with delayed versions
	signal IN_DIN_3k_2_delayed : delay4;	-- input data_3k_1 with delayed versions
-- pipe block signals
	signal in_pipe1_data,in_pipe2_data,in_pipe3_data: p_data;
	signal s_VOUT_3k, s_VOUT_3k_1, s_VOUT_3k_2      : std_logic;
-- Output VALID
	signal OUT_VOUT : std_logic;	-- Real valid out signal
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
	FD_DATAIN_3k:FD_G
				generic map(NBIT => 14)
				port map(
					D     => DIN_3k,
					CK    => CLK,
					RESET => RST,
					EN    => '1',
					Q     => IN_DIN_3k
				); 
	FD_DATAIN_3k_1:FD_G
				generic map(NBIT => 14)
				port map(
					D     => DIN_3k_1,
					CK    => CLK,
					RESET => RST,
					EN    => '1',
					Q     => IN_DIN_3k_1
				); 	
	FD_DATAIN_3k_2:FD_G
				generic map(NBIT => 14)
				port map(
					D     => DIN_3k_2,
					CK    => CLK,
					RESET => RST,
					EN    => '1',
					Q     => IN_DIN_3k_2
				); 

-- Input 3k delayed
	IN_DIN_3k_delayed(0) <= IN_DIN_3k;
	d3k_delay: for d in 1 to 3 generate
		fd0: FD_G	
				generic map(NBIT => 14)
				port map(
					D     => IN_DIN_3k_delayed(d-1),
					CK    => CLK,
					RESET => RST,
					EN    => '1',
					Q     => IN_DIN_3k_delayed(d)
				); 
	end generate d3k_delay;
-- Input 3k_1 delayed
	IN_DIN_3k_1_delayed(0) <= IN_DIN_3k_1;
	d3k_1_delay: for d in 1 to 3 generate
		fd1: FD_G
				generic map(NBIT => 14)
				port map(
					D     => IN_DIN_3k_1_delayed(d-1),
					CK    => CLK,
					RESET => RST,
					EN    => '1',
					Q     => IN_DIN_3k_1_delayed(d)
				); 
	end generate d3k_1_delay;
-- Input 3k_2 delayed
	IN_DIN_3k_2_delayed(0) <= IN_DIN_3k_2;
	d3k_2_delay: for d in 1 to 4 generate
		fd2: FD_G
				generic map(NBIT => 14)
				port map(
					D     => IN_DIN_3k_2_delayed(d-1),
					CK    => CLK,
					RESET => RST,
					EN    => '1',
					Q     => IN_DIN_3k_2_delayed(d)
				); 
	end generate d3k_2_delay;

-- Coefficient registers
	coefficients: for c in 0 to 10 generate	-- filter order = 10+1
		FD_COEF: FD_G
				generic map(NBIT => 14)
				port map(
					D     => COEFFICIENT(14*(c+1)-1 downto 14*c),
					CK    => CLK,
					RESET => RST,
					EN    => '1',
					Q     => IN_COEF(c)
				);
	end generate coefficients;
			
-- Pipeline Block 1 INPUTS
	in_pipe1_data(0)  <= IN_DIN_3k;
	in_pipe1_data(1)  <= IN_DIN_3k_2_delayed(1);
	in_pipe1_data(2)  <= IN_DIN_3k_1_delayed(1);
	in_pipe1_data(3)  <= IN_DIN_3k_delayed(1);
	in_pipe1_data(4)  <= IN_DIN_3k_2_delayed(2);
	in_pipe1_data(5)  <= IN_DIN_3k_1_delayed(2);
	in_pipe1_data(6)  <= IN_DIN_3k_delayed(2);
	in_pipe1_data(7)  <= IN_DIN_3k_2_delayed(3);
	in_pipe1_data(8)  <= IN_DIN_3k_1_delayed(3);
	in_pipe1_data(9)  <= IN_DIN_3k_delayed(3);
	in_pipe1_data(10) <= IN_DIN_3k_2_delayed(4);

-- Pipeline Block 2 INPUTS
	in_pipe2_data(0)  <= IN_DIN_3k_1;
	in_pipe2_data(1)  <= IN_DIN_3k;
	in_pipe2_data(2)  <= IN_DIN_3k_2_delayed(1);
	in_pipe2_data(3)  <= IN_DIN_3k_1_delayed(1);
	in_pipe2_data(4)  <= IN_DIN_3k_delayed(1);
	in_pipe2_data(5)  <= IN_DIN_3k_2_delayed(2);
	in_pipe2_data(6)  <= IN_DIN_3k_1_delayed(2);
	in_pipe2_data(7)  <= IN_DIN_3k_delayed(2);
	in_pipe2_data(8)  <= IN_DIN_3k_2_delayed(3);
	in_pipe2_data(9)  <= IN_DIN_3k_1_delayed(3);
	in_pipe2_data(10) <= IN_DIN_3k_delayed(3);
	
-- Pipeline Block 3 INPUTS
	in_pipe3_data(0)  <= IN_DIN_3k_2;
	in_pipe3_data(1)  <= IN_DIN_3k_1;
	in_pipe3_data(2)  <= IN_DIN_3k;
	in_pipe3_data(3)  <= IN_DIN_3k_2_delayed(1);
	in_pipe3_data(4)  <= IN_DIN_3k_1_delayed(1);
	in_pipe3_data(5)  <= IN_DIN_3k_delayed(1);
	in_pipe3_data(6)  <= IN_DIN_3k_2_delayed(2);
	in_pipe3_data(7)  <= IN_DIN_3k_1_delayed(2);
	in_pipe3_data(8)  <= IN_DIN_3k_delayed(2);
	in_pipe3_data(9)  <= IN_DIN_3k_2_delayed(3);
	in_pipe3_data(10) <= IN_DIN_3k_1_delayed(3);
	
	PB3k: pipelined_block
				port map(
					DATAIN  => in_pipe1_data,
					EN      => IN_VIN,
					CLK     => CLK,
					RST     => RST,
					COEF    => IN_COEF,
				    DATAOUT => OUT_DOUT_3k,
				    VOUT   	=> OUT_VOUT_3k
				);
	PB3k_1: pipelined_block
				port map(
					DATAIN  => in_pipe2_data,
					EN      => IN_VIN,
					CLK     => CLK,
					RST     => RST,
					COEF    => IN_COEF,
				    DATAOUT => OUT_DOUT_3k_1,
				    VOUT   	=> OUT_VOUT_3k_1
				);
	PB3k_2: pipelined_block
				port map(
					DATAIN  => in_pipe3_data,
					EN      => IN_VIN,
					CLK     => CLK,
					RST     => RST,
					COEF    => IN_COEF,
				    DATAOUT => OUT_DOUT_3k_2,
				    VOUT   	=> OUT_VOUT_3k_2
				);	


-- Output DATA Registers
	O_DATA_3k: FD_G
					generic map(NBIT => 14)
					port map(
						D     => OUT_DOUT_3k,
						CK    => CLK,
						RESET => RST,
						EN    => '1',
						Q     => DOUT_3k
					);
	O_DATA_3k_1: FD_G
					generic map(NBIT => 14)
					port map(
						D     => OUT_DOUT_3k_1,
						CK    => CLK,
						RESET => RST,
						EN    => '1',
						Q     => DOUT_3k_1
					);
	O_DATA_3k_2: FD_G
					generic map(NBIT => 14)
					port map(
						D     => OUT_DOUT_3k_2,
						CK    => CLK,
						RESET => RST,
						EN    => '1',
						Q     => DOUT_3k_2
					);

-- Block Output VALID Registers
	O_VALID_3k: fd 
			port map(
				D     => OUT_VOUT_3k,
				CK    => CLK,
				RESET => RST,
				EN    => '1',
			    Q     => s_VOUT_3k
			);
	O_VALID_3k_1: fd 
			port map(
				D     => OUT_VOUT_3k_1,
				CK    => CLK,
				RESET => RST,
				EN    => '1',
			    Q     => s_VOUT_3k_1
			);	
	O_VALID_3k_2: fd 
			port map(
				D     => OUT_VOUT_3k_2,
				CK    => CLK,
				RESET => RST,
				EN    => '1',
			    Q     => s_VOUT_3k_2
			);	
			
	OUT_VOUT <= (s_VOUT_3k and s_VOUT_3k_1 and s_VOUT_3k_2);
	VOUT_3k   <= s_VOUT_3k;
	VOUT_3k_1 <= s_VOUT_3k_1;
	VOUT_3k_2 <= s_VOUT_3k_2;

	
	O_VALID: fd 
			port map(
				D     => OUT_VOUT,
				CK    => CLK,
				RESET => RST,
				EN    => '1',
			    Q     => VOUT
			);	

end architecture myfilterAdv;