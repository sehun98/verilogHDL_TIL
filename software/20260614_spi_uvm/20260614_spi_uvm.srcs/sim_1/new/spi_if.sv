interface ram_if(
   input logic clk
);
   logic write;
   logic [7:0] addr;
   logic [7:0] wdata;
   logic [7:0] rdata;

   clocking drv_cb @(posedge clk);
    default input #1step output #0;
    
   output write;
   output addr;
   output wdata;
   input rdata;
   endclocking

   clocking mon_cb @(posedge clk);
    default input #1step;
   input write;
   input addr;
   input wdata;
   input rdata;
   endclocking

   modport DRV (clocking drv_cb,input clk);
   modport MON (clocking mon_cb,input clk);

endinterface
