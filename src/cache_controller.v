/****
      Designer:   Jiangnan WU
              Data:   2019/01/06
         Version:   1.0 edition
		 
 Description:   this is a first-level data cache controller .
                            a infinite write buffer  is concerned ; no TLB 
							only one load/store instruction is processed at a time.

*/


module cache_controller(clk,reset,ld,st,addr,tag1_loaded,tag2_loaded,valid1,valid2,dirty1,dirty2,l2_ack,hit,miss,load_ready,write_l1,read_l2,write_l2);

	input clk,reset;
	input ld,st;                                         // load/store
	input [31:0]addr;                            // cache access address
	input [20:0]tag1_loaded,tag2_loaded;               // the tag of the indexed cache data address
	input valid1,valid2;        
	input dirty1,dirty2;   
	input l2_ack;                                    //if =1 : the data loaded from L2 cache is arrived 
	
	
	output hit,miss;                                // cache hit/miss
	output reg load_ready;                        // if =1 :data is successfully loaded and ready for processor
	output reg write_l1;                              //enable for L1 cache write
	output reg read_l2;                               // load request to L2 cache 
	output reg write_l2;                             //  write buffer
	
	// state definition
	parameter Idle=2'b00;
	parameter CompareTag=2'b01;
	parameter WriteBuffer=2'b10;
	parameter Allocate=2'b11;
	
	
	reg [1:0]state;                                        //current state
	reg [1:0]next_state;                             //next state
	
	
	wire dirty;
	wire hit1,hit2;
	
	assign hit1=(tag1_loaded==addr[31:11]) & valid1;
	assign hit2=(tag2_loaded==addr[31:11]) & valid2;
	assign dirty= (hit1&dirty1) || (hit2 & dirty2);
	assign valid =(hit1&valid1) || (hit2 & valid2);
	assign hit = (ld||st) & (hit1||hit2);
	assign miss= ~hit;
	

	
/*****       WriteBuffer counter      *****/
	wire WB_ready;    // =1 after 8 cycles, write buffer finish.
	reg count8;       // 8times
	  counter_n #(.n(8) , .counter_bits(3) )  counter8(
				.clk(clk),
				.r(count8),
				.en(write_l2),
				.co(WB_ready),
				.q());
	
/*****       State Transition      *****/
	always@(posedge clk)
	begin
	if(reset)   state <= Idle;

	else
		state <= next_state  ;         //no state change by default
		case(state)
		
		// idle state
		Idle: begin 
				// if cache access requests from CPU, then compare tag
					if(ld || st)	 next_state <= CompareTag;
					else next_state <= Idle;
				  end

		CompareTag: begin 
					/*   cache hit   */
					if(hit)		next_state <= Idle;    
					
					/*   cache miss  */
					else if ((ld & dirty) || st) 	begin	next_state <= WriteBuffer;   count8 <=1 ;end
					 
					 //if  ld & clean,allocate a line and read data
					else begin  next_state <= Allocate;  	end
					end
							
				 
		Allocate: begin
					
					//if  data-loading from L2  success
					if(l2_ack)  next_state <= CompareTag;  
					
					// else , stall until data-loading finish
					else next_state<= Allocate;            
				end
				
		WriteBuffer: begin
					// assume a inifite write buffer, no worry about a stall due to small room 
					
					if(WB_ready&st) next_state <= Allocate;   //if read ,go to Allocate state
					else  next_state <= Idle ;            //if write miss,write directly to L2/write buffer
					end
					
		endcase
		
	end
	
	
/*****       Control signal       *****/

	// initialize signals
	 always @ (posedge clk) 
    begin
      if(reset) begin 
	  next_state <= 2'b00;
			count8<=0;
			load_ready <=0;
			write_l1 <=0;  write_l2<=0;  read_l2<=0;
			end
      else if(state!=CompareTag) count8 <=0;
    end
	
	
  // load_ready
  always @ (posedge clk) 
    begin  
		if((state==CompareTag)&hit&ld)  load_ready <= 1;
      else      load_ready <= 0;
    end
	
	// write_l1
  always @ (posedge clk) 
    begin  
		if((state==CompareTag)&hit&st)  write_l1 <= 1;
      else      write_l1 <= 0;
    end
	
	 // write_l2 , read_l2
	 //write_l2  last about 8  clocks ; 
	  always @ (posedge clk) 
    begin 
		if(state==Allocate)
        begin   read_l2<=1;  
          if(l2_ack) read_l2<=0;   // if load data from L2 is finish
        end
            
      else if(state==WriteBuffer)
        begin write_l2<=1;
			if(WB_ready) write_l2<=0;
		end
		
      else   {read_l2,write_l2}<=2'b0;
    end
	
endmodule

