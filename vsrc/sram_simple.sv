// Module to interface OpenRAM Sram with picorv32

module sram_simple(
   input clk,
   input rstn,
   input mem_valid,
   input mem_instr,
   input [31:0] mem_addr,
   input [31:0] mem_wdata,
   input [3:0] mem_wstrb,
   
   output [31:0] mem_rdata,
   output mem_ready
   
);

logic sram_write;
assign sram_write = mem_valid && mem_wstrb[0];

assign mem_ready = mem_valid;

sram_8_1024_sky130A SRAM (
   .clk(clk),
   .csb0(rstn),
   .web0(sram_write),
   .addr0(mem_addr[9:0]),
   .din0(mem_wdata[7:0]),
   .dout0(mem_rdata[7:0])
); 

endmodule
