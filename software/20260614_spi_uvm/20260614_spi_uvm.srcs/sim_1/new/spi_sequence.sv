class ram_base_seq extends uvm_sequence #(ram_seq_item);
   `uvm_object_utils(ram_base_seq)

   function new(string name = "ram_base_seq");
      super.new(name);
   endfunction

   task do_write(bit [7:0] addr, bit [7:0] data);
        ram_seq_item item;
        item = ram_seq_item::type_id::create("item");
        start_item(item);
        item.write = 1'b1;
        item.addr = addr;
        item.wdata = data;
        finish_item(item);
   endtask


   task do_read(bit [7:0] addr);
        ram_seq_item item;
        item = ram_seq_item::type_id::create("item");
        start_item(item);
        item.write = 1'b0;
        item.addr = addr;
        finish_item(item);
   endtask

endclass

class ram_wr_rd_seq extends ram_base_seq;
    `uvm_object_utils(ram_wr_rd_seq)
    rand int num;
    constraint c_num {num inside {[10:30]};}
    function new(string name = "ram_wr_rd_seq");
        super.new(name); 
    endfunction //new()

    task body();
        bit [7:0] addr_q[$];
        bit [7:0] addr;

        `uvm_info(get_type_name(), $sformatf("wr_rd 시나리오 시작 (%0d 반복)",num), UVM_LOW)

        repeat (num) begin
            addr = $urandom_range(0,255);
            do_write(addr, $urandom_range(0,255));
            addr_q.push_back(addr);
        end

        foreach(addr_q[i]) begin // 배열에 있는 만큼 반복 
            do_read(addr_q[i]);
        end

        `uvm_info(get_type_name(),"wr_rd 시나리오 종료",UVM_LOW)
    endtask
endclass //ram_wr_rd_seq extends ram_base_seq

class ram_random_seq extends ram_base_seq;
    `uvm_object_utils(ram_random_seq)

    rand int num;
    constraint c_num {num inside {[30 : 100]};}
    function new(string name = "ram_random_seq");
        super.new(name);
    endfunction //new()

    task body();
        ram_seq_item item;

        `uvm_info(get_type_name(),$sformatf("wr_rd 시나리오 시작 (%0d 반복)",num),UVM_LOW)

    repeat(num) begin
        item = ram_seq_item::type_id::create("item");
        start_item(item);
        if(!item.randomize() with {write dist {1 := 6, 0 := 4};})
        `uvm_error("SEQ","randomize 실패")
        finish_item(item);
    end

    `uvm_info(get_type_name(), "wr_rd 시나리오 종료",UVM_LOW)
    endtask

endclass //ram_random_seq extends ram_base_seq
    