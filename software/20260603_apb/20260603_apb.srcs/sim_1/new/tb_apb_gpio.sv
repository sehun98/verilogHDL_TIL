`include "uvm_macros.svh"
import uvm_pkg::*;

interface apb_gpio_interface(input logic PCLK, input logic PRESETn);
    logic        PSEL;
    logic        PWRITE;
    logic        PENABLE;
    logic [1:0]  PSTRB;
    logic [31:0] PWDATA;
    logic [31:0] PADDR;
    logic        PSLVERR;
    logic        PREADY;
    logic [31:0] PRDATA;
    logic [15:0] gpio_pin;
endinterface

class apb_gpio_sequence_item extends uvm_sequence_item;
    rand logic        PSEL;
    rand logic        PWRITE;
    rand logic        PENABLE;
    logic [1:0]       PSTRB;
    rand logic [31:0] PWDATA;
    rand logic [31:0] PADDR;
    logic             PSLVERR;
    logic             PREADY;
    logic [31:0]      PRDATA;
    logic [15:0]      gpio_pin;

    function new(string name = "abp_gpio_sequence_item");
        super.new(name);
    endfunction

    `uvm_object_utils_begin
        `uvm_field_int(PSEL, UVM_DEFAULT)
        `uvm_field_int(PWRITE, UVM_DEFAULT)
        `uvm_field_int(PENABLE, UVM_DEFAULT)
        `uvm_field_int(PSTRB, UVM_DEFAULT)
        `uvm_field_int(PWDATA, UVM_DEFAULT)
        `uvm_field_int(PADDR, UVM_DEFAULT)
        `uvm_field_int(PSLVERR, UVM_DEFAULT)
        `uvm_field_int(PREADY, UVM_DEFAULT)
        `uvm_field_int(PRDATA, UVM_DEFAULT)
        `uvm_field_int(gpio_pin, UVM_DEFAULT)
    `uvm_object_utils_end
endclass

class apb_gpio_sequence extends uvm_sequence#(apb_gpio_sequence_item);
    `uvm_object_utils(apb_gpio_sequence)

    apb_gpio_sequence_item apb_gpio_seq_item;

    function new(string name = "apb_gpio_sequence");
        super.new(name);
    endfunction

    virtual task body();
        repeat(100) begin
            apb_gpio_seq_item = apb_gpio_sequence_item::type_id::create("SEQ_ITEM", this);
            
            start_item(apb_gpio_seq_item)
            assert(apb_gpio_seq_item.randomize())
            else begin
                `uvm_fatal("randomize fail")
            end
            finishitem(apb_gpio_seq_item)
        end
    endtask
endclass

class apb_gpio_test extends uvm_test;
    `uvm_component_utils(apb_gpio_test)


endclass

module tb_apb_gpio();
logic clk, rst_n;

apb_gpio_interface apb_gpio_if(clk, rst_n);
apb_gpio dut (
    .PCLK(apb_gpio_if.PCLK),
    .PRESETn(apb_gpio_if.PRESETn),
    .PSEL(apb_gpio_if.PSEL),
    .PWRITE(apb_gpio_if.PWRITE),
    .PENABLE(apb_gpio_if.PENABLE),
    .PSTRB(apb_gpio_if.PSTRB),
    .PWDATA(apb_gpio_if.PWDATA),
    .PADDR(apb_gpio_if.PADDR),
    .PSLVERR(apb_gpio_if.PSLVERR),
    .PREADY(apb_gpio_if.PREADY),
    .PRDATA(apb_gpio_if.PRDATA),
    .gpio_pin(apb_gpio_if.gpio_pin)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    rst_n = 0;
    $fsdbDumpfile("wave.fsds");
    $fsdbDumpvars(0);

    repeat(2) @(posedge clk);
    rst_n = 1;
end

initial begin
    uvm_config_db#(virtual apb_gpio_interface)::set(null,"*","apb_gpio_if", apb_gpio_if);
    run_test("apb_gpio_test");
end

endmodule
