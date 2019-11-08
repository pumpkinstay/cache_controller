/****
      Designer:   Jiangnan WU
              Data:   2019/01/13
 Description:   Verilog Test Fixture  for module: cache_controller

*/
`timescale 1ns / 1ps

module cache_controller_tb;

	parameter DELY=100; 
	// Inputs
	reg clk;
	reg reset;
	reg ld;                                         		// load
	reg st;                                         		// store
	reg [31:0]addr;                            // cache access address
	reg [20:0]tag1_loaded,tag2_loaded;      
	reg valid1,valid2;
	reg dirty1,dirty2;                             	
	reg l2_ack;      
	
	// Outputs
	wire hit;
	wire miss;                                    
	wire load_ready;                        
	wire write_l1;                             
	wire read_l2;                               
	wire write_l2;                            

	// Instantiate the Unit Under Test (UUT)
	
	cache_controller uut (
		//input
		.clk(clk), 
		.ld(ld), 
		.st(st), 
		.addr(addr), 
		.l2_ack(l2_ack), 
		.reset(reset), 
		.tag1_loaded(tag1_loaded), 
		.tag2_loaded(tag2_loaded), 
		.valid1(valid1),
		.valid2(valid2), 
		.dirty1(dirty1), 
		.dirty2(dirty2),
		
		//output
		.hit(hit),
		.miss(miss),
		.load_ready(load_ready),
		.write_l1(write_l1),
		.read_l2(read_l2),
		.write_l2(write_l2)	);
		
  //clk
	always #(DELY/2) clk=~clk;
  // Inputs
	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 0;
		#(DELY*0.5+1) reset = 1;
		#(DELY)       reset = 0;
		
		// read hit ( way1 hit ) 
		#(DELY) 	valid1=1;	 valid2=1;	dirty1=0;dirty2=0;
								ld=1; st=0;l2_ack=0;			//ld =1
								addr=32'h10001_fff;
								tag1_loaded={20'h10001,1'b1};   // tag1 == addr[31:11]
								tag2_loaded={20'h10001,1'b0};
		
		// write hit
		#(DELY*10) 	valid1=1;	 	dirty1=0;
								ld=0; st=1;l2_ack=0; 		//st =1
								
		// read miss + block clean
		#(DELY*10)    valid1=0;	dirty1=0;
								ld=1; st=0;l2_ack=0; 		//ld =1
		#(DELY*8)    l2_ack=1; 	valid1=1;	 // after 8 cycles			
		#(DELY) l2_ack=0;
		
		
		// write miss + block clean
		#(DELY*10) 	valid1=0;	 dirty1=0;
								ld=0; st=1;l2_ack=1;        // st=1

		#(DELY*10)  $stop;
        

	end
      
endmodule