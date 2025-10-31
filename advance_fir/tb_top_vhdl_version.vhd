Library IEEE;
use IEEE.Std_Logic_1164.all; 
use IEEE.Std_Logic_Unsigned.all;
use STD.textio.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use work.fir_adv_package.all;


entity tb is
end entity tb;

architecture tb_top of tb is
	component clockGen
		port(
			ENDSIM : IN std_logic;
			CLK_i  : OUT std_logic;
			RST_i  : OUT std_logic
		);
	end component;
	
	component dataGen
		port(
			CLK        : in  std_logic;					
			RST        : in  std_logic; 
			IN_VALID   : in  std_logic;
			VOUT       : out std_logic;                       
			DOUT_3k    : out std_logic_vector(13 downto 0);  
			DOUT_3k_1  : out std_logic_vector(13 downto 0); 
			DOUT_3k_2  : out std_logic_vector(13 downto 0); 
			COEF	   : out p_data;  
			END_SIM    : out std_logic              
		);
	end component;
	
	component testFIR
		port(
			t_CLK       : IN std_logic;
			t_RST       : IN std_logic;
			t_VIN       : IN std_logic;
			t_DIN_3k    : IN std_logic_vector(13 downto 0);
			t_DIN_3k_1  : IN std_logic_vector(13 downto 0);
			t_DIN_3k_2  : IN std_logic_vector(13 downto 0);
			t_COEF      : IN p_data;
			t_DOUT_3k   : OUT std_logic_vector(13 downto 0);
			t_DOUT_3k_1 : OUT std_logic_vector(13 downto 0);
			t_DOUT_3k_2 : OUT std_logic_vector(13 downto 0);
			t_VOUT_3k   : OUT std_logic;
			t_VOUT_3k_1 : OUT std_logic;
			t_VOUT_3k_2 : OUT std_logic;
			t_VOUT	  	: OUT std_logic
		);
	end component;
	
	signal my_clk, my_rst: std_logic;
	signal my_endsim: std_logic;
	signal my_vin, my_vout: std_logic;
	signal my_vout_3k,my_vout_3k_1,my_vout_3k_2,my_real_vout : std_logic;
	signal my_coef_arr: p_data;
	signal my_dout_3k,my_dout_3k_1,my_dout_3k_2: std_logic_vector(13 downto 0);
	signal tb_dataout_3k,tb_dataout_3k_1,tb_dataout_3k_2: std_logic_vector(13 downto 0);
	
begin
	clock_gen: clockGen
				port map(
					ENDSIM => my_endsim,
				    CLK_i  => my_clk,
				    RST_i  => my_rst
				);

	data_gen: dataGen
				port map(
					CLK       => my_clk,        -- in
					RST       => my_rst,        -- in
					IN_VALID  => my_vin,       -- in
					VOUT      => my_vout,      -- out
					DOUT_3k   => my_dout_3k,    -- out
					DOUT_3k_1 => my_dout_3k_1,  -- out
					DOUT_3k_2 => my_dout_3k_2,  -- out
					COEF	  => my_coef_arr,   -- out
					END_SIM   => my_endsim     -- out
				);
	
	top: testFIR
			port map(
					t_CLK       => my_clk,
                    t_RST       => my_rst,
                    t_VIN       => my_vout,
                    t_DIN_3k    => my_dout_3k,
                    t_DIN_3k_1  => my_dout_3k_1,
                    t_DIN_3k_2  => my_dout_3k_2,
                    t_COEF      => my_coef_arr,
                    t_DOUT_3k   => tb_dataout_3k,
                    t_DOUT_3k_1 => tb_dataout_3k_1,
                    t_DOUT_3k_2 => tb_dataout_3k_2,
                    t_VOUT_3k   => my_vout_3k,
                    t_VOUT_3k_1 => my_vout_3k_1,
                    t_VOUT_3k_2 => my_vout_3k_2,
					t_VOUT      => my_real_vout
			);
	
	process begin
		my_vin <= '0';
		wait for 20 ns;
		my_vin <= '1';
		wait;
	end process;
	
end tb_top;









