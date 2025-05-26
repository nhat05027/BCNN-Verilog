module bsram (
	      input 	   clk,
	      input 	   rst,
	      input 	   ce, 
	      input 	   wre,
	      input [13:0] addr,
	      input [11:0]  data_in,
	      output [11:0] data_out
);

// Define one of DIRECT, FROMDOC, or GENERIC
`define FROMDOC

`ifdef GENERIC
   reg [11:0] 		   mem[16383:0]; // 12 bit x 10bit addr
   reg [13:0] 		   read_addr;

   always @(posedge clk) begin
      if (wre)
	   mem[addr] <= data_in;
   read_addr <= addr;
   end

   assign data_out = mem[read_addr];

`elsif FROMDOC
   reg [11:0] 		   mem[16383:0];
   reg [11:0] 		   data_out_reg;

  initial mem[0] = 0;
   always @(posedge clk or posedge rst)
     if (rst)
       data_out_reg <= 0;
     else
       if (ce & !wre)
	 data_out_reg <= mem[addr];

   always @(posedge clk)
     if (ce & wre)
       mem[addr] <= data_in;
   
   assign data_out = data_out_reg;

`elsif DIRECT

   Gowin_SP gmem (
		  .dout(data_out),
		  .clk(clk),
		  .oce(1'b1),
		  .ce(ce),
		  .reset(rst),
		  .wre(wre),
		  .ad(addr),
		  .din(data_in)
		  );
    

`endif
endmodule // bsram
