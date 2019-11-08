module counter_n(clk,r,en,co,q);
  parameter n=2;      // Frequency division ratio
  parameter counter_bits=1;
  input clk,r,en;
  output co;
  output[counter_bits:1] q;
  reg[counter_bits:1] q=0;
	assign co=(q==(n-1))&&en;  
	always @(posedge clk)
	  begin 
	    if(r) q=0;    // Synchronous zero
		else if(en) 
		  begin 
		    if(q==(n-1)) q=0;
		    else q=q+1;
		  end
		else q=q;  	  // state maintence
	  end
endmodule 