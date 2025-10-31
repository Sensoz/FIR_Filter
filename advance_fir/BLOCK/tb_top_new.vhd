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
			CLK      : in  std_logic;					
			RST      : in  std_logic; 
			IN_VALID : in  std_logic;
			VOUT     : out std_logic;                       
			DOUT     : out p_data;   
			COEF	 : out p_data;  
			END_SIM  : out std_logic              
		);
	end component;
	
	component testFIR
		port(
			t_CLK  : IN std_logic;
			t_RST  : IN std_logic;
			t_VIN  : IN std_logic;
			t_DIN  : IN p_data;
			t_COEF : IN p_data;
			t_DOUT : OUT std_logic_vector(13 downto 0);
			t_VOUT : OUT std_logic
		);
	end component;
	
	signal my_clk, my_rst: std_logic;
	signal my_endsim: std_logic;
	signal my_vin, my_vout, tb_vout: std_logic;
	signal my_coef: p_data;
	signal my_datain : p_data;
	signal my_dataout: p_data;
	signal tb_dataout: std_logic_vector(13 downto 0);
	
begin
	clock_gen: clockGen
				port map(
					ENDSIM => my_endsim,
				    CLK_i  => my_clk,
				    RST_i  => my_rst
				);

	data_gen: dataGen
				port map(
					CLK 	 => my_clk,     
					RST      => my_rst,
				    IN_VALID => my_vin,
				    VOUT     => my_vout, 
				    DOUT     => my_dataout,
				    COEF	 => my_coef,
				    END_SIM  => my_endsim
				);
	
	top: testFIR
			port map(
				t_CLK  => my_clk,
				t_RST  => my_rst,
				t_VIN  => my_vout,
				t_DIN  => my_dataout,
				t_COEF => my_coef,
				t_DOUT => tb_dataout,
				t_VOUT => tb_vout
			);
	
	process begin
		my_vin <= '0';
		wait for 20 ns;
		my_vin <= '1';
		wait;
	end process;
	
end tb_top;









