/******************************************************************************
 * Project     : AXI4 UVM Verification
 * File        : axi_test.sv
 * Author      : Mirza Agha Malik Baig
 * Description : Builds the environment, starts stimulus, and manages the
 *               run-phase objection.
******************************************************************************/

  class axi_test extends uvm_test;

  `uvm_component_utils(axi_test)

  axi_env env;

  function new(string name = "axi_test",
               uvm_component parent = null);

    super.new(name, parent);

  endfunction


  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    env = axi_env::type_id::create("env", this);

  endfunction
    
    
     function void end_of_elaboration_phase(uvm_phase phase);

  super.end_of_elaboration_phase(phase);

  uvm_top.print_topology();

endfunction
    
    
   task run_phase(uvm_phase phase);

  axi_sequence seq;

  phase.raise_objection(this);

  seq = axi_sequence::type_id::create("seq");

  seq.start(env.agent.sequencer);

  phase.drop_objection(this);

endtask

endclass