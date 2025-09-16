module SOC (
   input clk,
   input rstn,
   
   output wire [31:0] gpio_do,
   output wire [31:0] gpio_oe,
   output wire [31:0] gpio_ps,
   output wire [31:0] gpio_is,
   output wire [31:0] gpio_ds0,
   output wire [31:0] gpio_ds1,
   output wire [31:0] gpio_sr
);

   logic rst;
   assign rst = ~rstn;

   logic mem_valid;
   logic mem_instr;
   logic mem_ready;
   logic [31:0] mem_addr;
   logic [31:0] mem_wdata;
   logic [3:0] mem_wstrb;
   logic [31:0] mem_rdata;

   picorv32 CORE (
   	.clk(clk), 
   	.resetn(rstn),
   	.trap(),
   
   	.mem_valid(mem_valid),
   	.mem_instr(mem_instr),
   	.mem_ready(mem_ready),
   
   	.mem_addr(mem_addr),
   	.mem_wdata(mem_wdata),
   	.mem_wstrb(mem_wstrb),
   	.mem_rdata(mem_rdata),
   
   	// Look-Ahead Interface
   	.mem_la_read(),
   	.mem_la_write(),
   	.mem_la_addr(),
   	.mem_la_wdata(),
   	.mem_la_wstrb(),
   
   	// Pico Co-Processor Interface (PCPI)
   	.pcpi_valid(),
   	.pcpi_insn(),
   	.pcpi_rs1(),
   	.pcpi_rs2(),
   	.pcpi_wr(),
   	.pcpi_rd(),
   	.pcpi_wait(),
   	.pcpi_ready(),
   
   	// IRQ Interface
   	.irq(),
   	.eoi(),
   
   	.trace_valid(),
   	.trace_data()
   );

   sram_simple SRAM_TOP(
      .clk(clk),
      .rstn(rstn),
      .mem_valid(mem_valid),
      .mem_instr(mem_instr),
      .mem_addr(mem_addr),
      .mem_wstrb(mem_wstrb),
      .mem_wdata(mem_wdata),
      .mem_rdata(mem_rdata),
      .mem_ready(mem_ready)
   );

endmodule
