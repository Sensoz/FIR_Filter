`timescale 1ns / 1ps


module tb_top ();

	wire myClock;
	wire myReset;
	wire mySim;
	wire [13:0] myDin_3k,myDin_3k_1,myDin_3k_2;
	reg myVin;
	wire myVout;
	wire [153:0] myCoef;
	wire [13:0] myDout;
	wire vout_sim;
	wire [13:0] fir_out_3k,fir_out_3k_1,fir_out_3k_2;
	wire fir_vout;
	
	clockGen clock_adv(
				.ENDSIM(mySim),
				.CLK_i(myClock),
				.RST_i(myReset)
	);

	dataGen DATA_adv(
				.CLK(myClock),       
				.RST(myReset),       
				.IN_VALID(myVin),	// control the test
				.VOUT(myVout),      
				.DOUT_3k(myDin_3k),   
				.DOUT_3k_1(myDin_3k_1), 
				.DOUT_3k_2(myDin_3k_2), 
				.COEF(myCoef),	  
				.END_SIM(mySim)   			
	);

	adv_fir UUT(
				.CLK(myClock), 	  
				.RST(myReset), 	  
				.DIN_3k(myDin_3k), 	  
				.DIN_3k_1(myDin_3k_1),  
				.DIN_3k_2(myDin_3k_2),  
				.VIN(myVout), 	  
				.COEFFICIENT(myCoef),
				
				.DOUT_3k(fir_out_3k),   
				.DOUT_3k_1(fir_out_3k_1), 
				.DOUT_3k_2(fir_out_3k_2), 
				.VOUT_3k(fir_vout_3k),   
				.VOUT_3k_1(fir_vout_3k_1), 
				.VOUT_3k_2(fir_vout_3k_2), 
				.VOUT(fir_vout)	  
	);

	data_sink sink(
				.CLK(myClock),
				.RST(myReset),
				.VIN(fir_vout),     
				.DIN_3k(fir_out_3k),  
				.DIN_3k_1(fir_out_3k_1),
				.DIN_3k_2(fir_out_3k_2)
	);

	initial
	begin
		myVin = 0;
		#60 myVin = 1;
		#100 myVin = 0;
		#40 myVin = 1;
		#100 myVin = 0;
		#80 myVin = 1;
	end

endmodule