# P1: Run the Flow!

Version: 2025.0
---

## Due Date:  FIXME



# Goal

This project will walk you through the basics of setting up a floorplan for a digital IC design flow that includes both hard macros and standard cell logic.  It will also give you some exposure on the process of modifing an existing digital logic design to add more features. 

# Setup

```bash
ssh burrow-rhel.luddy.indiana.edu -YCA
git clone https://github.com/engr599-ic/P2_floorplanning.git
cd P2_floorplanning
make setup
source load_tools.sh
```

# Modify the RTL

The first task is to modify the existing RTL to fix the desired circuit.  The base design only includes a single 8-bit wide SRAM macro.  Unfortunately, the PICORV core wants a 32-bit wide a single 8-bit wide SRAM

<img width="502" height="403" alt="image" src="https://github.com/user-attachments/assets/174d7f5c-93eb-434e-888b-964b68c646c1" />


Open `vsrc/sram_simple.sv`: 
```module sram_simple(
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
```
# Run the Flow
## Synthesis

```bash
make synth
```

You can also restore the synthesis database with:
```bash
genus -gui -db ./dbs/syn_opt.db
```

## Place and Route

Place and Route (P&R or PnR) is where electronic components and their interconnections are automatically arranged and routed on a chip or printed circuit board (PCB).  It is also called Automatic Place and Route (APR).  

```bash
make pnr
```

This launches a tool named `innovus`, and asks it to run `pnr.tcl`.  This will do the P&R on our previously synthesized netlist.  Once complete, you can open the database and view your results.  

```bash
innovus -stylus -db ./dbs/signoff.db
```

By default all database files are saved to the `dbs/` dir

## Timing

The file `functional.sdc` is a synopsis design constraint file that dictates how fast the clock will be in your design.
The synthesis and place and route tools will attempt to meet this timing constraint.
[SDC Command Reference](https://iccircle.com/static/upload/img20240131000211.pdf)

Timing reports can be found in the `RPT_final` directory as well as the `timingReports` directory.

### MMMC File

An MMMC file (multi-mode multi-corner) file creates all of the corner information used by the synthesis and pnr tools. 
This file sets the following:
  - Library Sets
    - Lists of `.lib` files that contain timing information for standard cells.
  - Constraint Modes
    - Links SDC files to specific Corners
  - Delay Corners
  - Analysis Views

# Getting Help

Both tools (genus and innovus) have a gui option that can be enabled by adding the `-gui` flag.  

For documentation on available commands, both tools (in GUI mode) also have a Help dropdown that includes the user guide.  

# Your Turn

Now that you know the basic flow, it's time to start tweaking for improved PPA.  Your task is customize this flow twice, once to optimize performance and once to optimize for area.  

## Optimize for Performance

By default, your PICORV core is targetting a 100ns (10MHz) clock.  Your task is to see how high you can push the frequency without causing setup/hold violations on any of the process corners.  

Start by modifying this line in the `functional.sdc` Constraint file: 
`create_clock -name clk -period 100 -waveform {0 50} [get_ports {clk}]`

You will likely need to optimize both the `synthesis.tcl` and `pnr.tcl` to achieve the highest performance. 

## Optimize for Area

Next Time...

