/******************************************************************************
 * Project     : AXI4 UVM Verification
 * File        : axi_sequencer.sv
 * Author      : Mirza Agha Malik Baig
 * Description : Passes AXI transaction items from sequences to the
 *               driver.
 *****************************************************************************/

class axi_sequencer extends uvm_sequencer #(axi_txn);

  `uvm_component_utils(axi_sequencer)

  function new(string name = "axi_sequencer",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass