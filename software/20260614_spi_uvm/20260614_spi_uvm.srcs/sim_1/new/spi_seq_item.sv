class spi_seq_item extends uvm_sequence_item;
    rand logic [7:0] master_tx_data;
    rand logic [7:0] slave_tx_data;

    logic [7:0] master_rx_data;
    logic [7:0] slave_rx_data;

    rand logic cpol;
    rand logic cpha;
    rand logic [2:0] clk_div;

    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(master_tx_data, UVM_DEFAULT)
        `uvm_field_int(slave_tx_data,  UVM_DEFAULT)
        `uvm_field_int(master_rx_data, UVM_DEFAULT)
        `uvm_field_int(slave_rx_data,  UVM_DEFAULT)
        `uvm_field_int(cpol,           UVM_DEFAULT)
        `uvm_field_int(cpha,           UVM_DEFAULT)
        `uvm_field_int(clk_div,        UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "spi_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf(
            "master_tx_data=0x%02h, slave_tx_data=0x%02h, master_rx_data=0x%02h, slave_rx_data=0x%02h, cpol=%0d, cpha=%0d, clk_div=%0d",
            master_tx_data,
            slave_tx_data,
            master_rx_data,
            slave_rx_data,
            cpol,
            cpha,
            clk_div
        );
    endfunction
endclass
