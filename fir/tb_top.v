`timescale 1ns / 1ps


module tb_top ();

	wire myClock;
	wire myReset;
	wire mySim;
	wire [13:0] myDin;
	reg myVin;
	wire myVout;
	wire [153:0] myCoef;
	wire [13:0] myDout;
	wire vout_sim;
	wire [13:0] fir_out;
	wire fir_vout;
	
	clockGen clock(
				.ENDSIM(mySim),
				.CLK_i(myClock),
				.RST_i(myReset)
	);

	dataGen d(
				.CLK(myClock),     
				.RST(myReset),  
				.IN_VALID(myVin),	// control from top module testbench
				.VOUT(myVout),
				.DOUT(myDin),   
				.COEF(myCoef),
	            .END_SIM(mySim) 
	);

	FIR_filter UUT(
				.CLK(myClock),
	            .RST(myReset), 
	            .DIN(myDin), 
	            .VIN(myVout), 
	            .COEF(myCoef),
	            .DOUT(fir_out),
	            .VOUT(fir_vout)
	);

	data_sink sink(
				.CLK(myClock),
				.RST(myReset),
				.VIN(fir_vout),
				.DIN(fir_out)
	);

	initial
	begin
		myVin = 0;
		#60 myVin = 1;
		#20 myVin = 0;
		#40 myVin = 1;
		#100 myVin = 0;
		#80 myVin = 1;
	end

endmodule