class spi_master_base_test extends uvm_test;
   `uvm_component_utils(spi_master_base_test)

   spi_master_env env;

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = spi_master_env::type_id::create("env",this);
   endfunction

   function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      uvm_top.print_topology();
   endfunction
endclass

class spi_master_basic_test extends spi_master_base_test;
   `uvm_component_utils(spi_master_basic_test)

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction

   task run_phase(uvm_phase phase);
      spi_master_seq seq;
      phase.raise_objection(this);

      seq = spi_master_seq::type_id::create("seq");
      if(!seq.randomize()) `uvm_error("TEST","seq randomize fail!");
      seq.start(env.agt.sqr);

      #100;
      phase.drop_objection(this);
   endtask
endclass

class spi_master_random_test extends spi_master_base_test;
   `uvm_component_utils(spi_master_random_test)

   function new(string name, uvm_component parent);
      super.new(name,parent);
   endfunction

   task run_phase(uvm_phase phase);
      spi_master_seq seq;
      phase.raise_objection(this);

      seq = spi_master_seq::type_id::create("seq");
      if(!seq.randomize()) `uvm_error("TEST","seq randomize fail!");
      seq.start(env.agt.sqr);

      #100;
      phase.drop_objection(this);
   endtask
endclass