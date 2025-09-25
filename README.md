# P2: Floorplanning

Version: 2025.0
---

## Due Date:  09:59am, Thursday, October 2nd, 2025



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

# Modify the Design

The first task is to modify the existing source files to fix the circuit.  The base design only includes a single 8-bit wide memory (SRAM) macro. This would be fine for an 8-bit (1 byte) CPU.  Unfortunately, the PICORV core is a 32-bit (4 byte) system, which needs a 32-bit wide memory interface.  So you will need to modify the RTL to include 4 8-bit wide SRAM macros to create a 32-bit interface.  A cartoon of how to pin mapping should go is shown below.  

<img width="494" height="388" alt="image" src="https://github.com/user-attachments/assets/8240aeb6-fa7b-4dae-a5d0-5b49c2a2f406" />

To add the extra SRAM modules, you will need to **modify `vsrc/sram_simple.sv`**.  The code is shown below with some additional annotationed clues.  

```
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
assign sram_write = mem_valid && mem_wstrb[0];// <- will need modified for each block

assign mem_ready = mem_valid;

sram_8_1024_sky130A SRAM ( // <- will need to make 4 instances of this
   .clk(clk), // <- will stay the same for each block
   .csb0(rstn), // <- will stay the same for each block
   .web0(sram_write),  // <- will need modified for each block
   .addr0(mem_addr[9:0]), // <- will stay the same for each block
   .din0(mem_wdata[7:0]), // <- will need modified for each block
   .dout0(mem_rdata[7:0]) // <- will need modified for each block
);

endmodule
```
# Floorplanning

Now we need to integrate the memory macros into the layout, or floorplan, of the overall system. This will start just like Project 1, but you will need to do more manual intervention on the place and route phase.   

## Synthesis

This should be largely unchanged since Project 1.  One exception is that now the timing libraries for the sram are included in the `mmmc.tcl` file. 

If you have any Verilog synatx errors, the synthesis step will catch those. 

```bash
make synth
```

You can also restore the synthesis database with:
```bash
genus -gui -db ./dbs/syn_opt.db
```

## Place and Route

Ok, now you get to design your own floorplan.  

### Load design

Start innovus:
```bash
innovus -stylus
```

Once that has launched, it should drop you at a TCL (Tool Command Language) prompt.  Run the modified pnr.tcl file *in the Innovus TCL shell*
```tcl
source pnr.tcl
```

This will load the design into Innovus, but won't do anything beyond that. It should stop you in a screen that looks like this: 
<img width="1032" height="896" alt="image" src="https://github.com/user-attachments/assets/581193ad-2b33-416f-aff7-b41ab8ce3e3c" />

Note that the hard SRAM macros are on the right side.  

### Resize floorplan
By default, Innovus seems to make a floorplan that is too small for the SRAM macros.  You can use TCL commands to increase it's size, or use the GUI window, shown below: 

<img width="388" height="321" alt="image" src="https://github.com/user-attachments/assets/59e98ce6-4351-4fdb-bd57-4ea3d0576676" />

We suggest a ~70% core utilization.  

### Place the SRAM Macros

Now we need to move the SRAM macros where we want them.  One way to do that is to right click on one of the SRAM macros and select "Attach to Cursor".  Then you can move the macro where you want it and click to fix it's location. 

<img width="632" height="670" alt="image" src="https://github.com/user-attachments/assets/911147da-2ee1-4bec-9b59-5e73d2e62b88" />

Now move the macros to arrange them inside the floorplan.  One suggestion is to arrange them as follows (but you can do other placements): 

<img width="497" height="238" alt="image" src="https://github.com/user-attachments/assets/db4ab49c-1406-45ca-9f79-823fce970bc0" />

#### Cut Core Rows

We don't want standard cells right up against the SRAM macros, so we'll use the "Cut Rows" option for that.  

Start by selecting all 4 SRAM macros (Shift + Click).  With all 4 SRAM macros selected, select "Cut Core Rows" dropdown box, as shown below.  

<img width="393" height="436" alt="image" src="https://github.com/user-attachments/assets/a19fdc37-d1bb-4420-accb-73c98bd00f21" />


Once there, configure as shown below.  This will make sure no standard cells are placed within 4 "units" on the left/right, and 2 on the top/bottom.  The top/bottom units are larger than the left/right, so we're excluding a larger number of left/right units.  

<img width="400" height="441" alt="image" src="https://github.com/user-attachments/assets/1d76c952-a3a7-4d7e-9c95-ae2f1cc0fa37" />

### Power Planning

#### Macro Connection

First, let's draw a ring around the macros: 

<img width="665" height="375" alt="image" src="https://github.com/user-attachments/assets/6555bcf4-9f62-4c3a-bab8-18e0cd8dbbbb" />

<img width="604" height="505" alt="image" src="https://github.com/user-attachments/assets/18570b31-6e79-4151-99d5-0f74595a4aa0" />

- Nets:  VPWR VGND
- Block ring(s) around each block
- Top/Bottom:  Met5, 10um width
- Left/Right:  Met4: 10um width

That should have drawn the rings, but not connected them to the macros.  For that, we will use SRoute (Special Route): 

<img width="200" height="202" alt="image" src="https://github.com/user-attachments/assets/0047d134-0dcb-412f-a363-33e79d3628ec" />

This will connect the power rings around the macros: 

<img width="522" height="631" alt="image" src="https://github.com/user-attachments/assets/7f42fcb0-e395-43a8-93da-9338905e197a" />

If all goes well, it should look like this: 

<img width="430" height="427" alt="image" src="https://github.com/user-attachments/assets/215638a7-433d-4682-9d2d-ecadc277d125" />

#### Follow-Pins

Next, let's use SRoute to put down power rails for the standard cells.  These are often called the "Follow Pins". 

<img width="200" height="202" alt="image" src="https://github.com/user-attachments/assets/0047d134-0dcb-412f-a363-33e79d3628ec" />

And configure it as follows: 

<img width="518" height="628" alt="image" src="https://github.com/user-attachments/assets/25aeaebb-2337-4709-a2ea-ce09dd58999b" />

#### Stripes

Now let's add some power/ground strips to get the power distributed around the chip:

<img width="284" height="247" alt="image" src="https://github.com/user-attachments/assets/a0b8e966-446d-42e3-a9ff-f46fe4149489" />

This should draw horizontal strips on Met5:

<img width="601" height="654" alt="image" src="https://github.com/user-attachments/assets/725979d4-b7e3-4e5d-8dd4-cb9b803ff588" />


And this will draw vertical strips on Met4: 

<img width="604" height="652" alt="image" src="https://github.com/user-attachments/assets/b1e68725-ee6e-4aee-a22d-ca5b6f2cd88a" />


#### Dealing with Dangling Nets

```tcl
check_connectivity -nets {VPWR VGND} -type all
edit_trim_routes -all
check_connectivity -nets {VPWR VGND} -type all
```

#### Check Connectivity

If you want to run check_connectivity manually, it can be found here: 

<img width="259" height="265" alt="image" src="https://github.com/user-attachments/assets/c673efc5-8c7a-4cc8-a0b1-4f69154e5fdf" />

#### Pin Assignment

If you want to control where the block pins are placed for a design instead of letting innovus place them randomly use the Pin Editor.

Edit > Pin Editor

<img width="814" height="896" alt="image" src="https://github.com/user-attachments/assets/78105ada-d2db-4460-85fe-91a9503101a7" />

Here you can choose a pin group and assign it to an edge of the design (Top Bottom Left Right). Then you can specify the layer you want the pins to be on as well
as the spacing and pattern of pin placement.

#### Reset Floorplan

If (or when) you run into floorplanning issues and want to "reset" your floorplan, try the "Clear Floorplan" option in the GUI: 
<img width="335" height="446" alt="image" src="https://github.com/user-attachments/assets/f6f741d9-580b-4a9a-89ed-c2c51df8088e" />

### Save the Floorplan

Once your happy with your floorplan, we suggest you save your floorplan.  Try File->Save->Floorplan.  
### Finish the flow. 

Now you can continue on with standard placement,  clock tree synthesis, routing, and signoff as per Project 1. 
Most of this can be uncommented from the existing `pnr.tcl` script.  We recommend adding a `read_floorplan` command that loads the floorplan saved in the previous step.  

# Getting Help

Both tools (genus and innovus) have a gui option that can be enabled by adding the `-gui` flag.  

For documentation on available commands, both tools (in GUI mode) also have a Help dropdown that includes the user guide.  

# Your Turn

Now it's your turn to run your own flow.  This time we're concerned with getting the DRC and connectivity checks to pass.  We're not so concerned about area or timing, so feel free to relax those to make things run faster.  

Your goal should be to achieve the following: 
 - You have power rings around your SRAM macros
 - You have a reasonable power grid in your core
 - You have an overall pass on `run_checks.sh` command  

