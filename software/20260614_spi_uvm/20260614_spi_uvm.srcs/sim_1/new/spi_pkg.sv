package ram_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

   // 의존성 순서대로 include 작성해야함
    `include "spi_seq_item.sv"

    `include "spi_master_sequence.sv"
    `include "spi_master_driver.sv"
    `include "spi_master_monitor.sv"
    `include "spi_master_agent.sv"

    `include "spi_slave_sequence.sv"
    `include "spi_slave_driver.sv"
    `include "spi_slave_monitor.sv"
    `include "spi_slave_agent.sv"

    `include "spi_scoreboard.sv"
    `include "spi_coverage.sv"
    `include "spi_env.sv"
    `include "spi_base_test.sv"
    `include "spi_mode0_test.sv"
    `include "spi_mode1_test.sv"
    `include "spi_random_test.sv"

endpackage