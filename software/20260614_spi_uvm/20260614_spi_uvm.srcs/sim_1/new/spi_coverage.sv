/*
spi_master (
    input  logic       clk,
    input  logic       reset,
    input  logic       start,
    input  logic       cpol,
    input  logic       cpha,
    input  logic [2:0] clk_div,
    output logic       busy,
    output logic       done,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       sclk,
    output logic       mosi,
    input  logic       miso,
    output logic       ss_n
);
*/

class ram_coverage extends uvm_subscriber #(ram_seq_item);
   `uvm_component_utils(ram_coverage)

   ram_seq_item tr;

   covergroup ram_cg;
      option.per_instance =1;

   cp_op : coverpoint tr.write {
   
         bins read = {0};
         bins write = {1};
      }

      cp_addr : coverpoint tr.addr {
         bins addr_min = {8'h00};
         bins addr_low = {[8'h01:8'h54]};
         bins addr_mid = {[8'h55:8'hAA]};
         bins addr_high = {[8'hAB:8'hFE]};
         bins addr_max = {8'hff};
      }

      cp_wdata : coverpoint tr.wdata iff (tr.write) {
         bins data_zero = {8'h00};
         bins data_max = {8'hFF};
         bins data_etc = {[8'h01:8'hFE]};
      }

      cx_op_addr : cross cp_op, cp_addr;
   endgroup

   function new(string name, uvm_component parent);
      super.new(name,parent);
      ram_cg = new();
   endfunction

    function void write(ram_seq_item t);
      tr = t;
      ram_cg.sample();
        //`uvm_info(get_type_name(),t.convert2string(),UVM_HIGH)
    endfunction

   function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      `uvm_info("COV","==================================",UVM_LOW)
      `uvm_info("COV","======Functional Coverage 결과=====",UVM_LOW)
      `uvm_info("COV",$sformatf("전체 : %6.2f %%",ram_cg.get_inst_coverage()),UVM_LOW)
      `uvm_info("COV",$sformatf("동작종류: %6.2f %%(read/write)",ram_cg.cp_op.get_inst_coverage()),UVM_LOW)
      `uvm_info("COV",$sformatf("주소: %6.2f %%(min/low/mid/high/max)",ram_cg.cp_addr.get_inst_coverage()),UVM_LOW)
      `uvm_info("COV",$sformatf("데이터: %6.2f %%(0/FF/etc)",ram_cg.cp_wdata.get_inst_coverage()),UVM_LOW)
      `uvm_info("COV",$sformatf("동작x주소: %6.2f %%(cross)",ram_cg.cx_op_addr.get_inst_coverage()),UVM_LOW)
      `uvm_info("COV","==================================",UVM_LOW)

      if(ram_cg.get_inst_coverage() < 100.0)  begin
         `uvm_warning("COV","커버리지 100% 미달~ 시나리오를 추가하거나 더 테스트를 진행하시오")
      end 
   endfunction
endclass
