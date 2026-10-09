/******************************************************************************
 * Project     : AXI4 UVM Verification
 * File        : axi_scoreboard.sv
 * Author      : Mirza Agha Malik Baig
 * Description : Maintains reference memory and checks observed AXI read
 *               data.
******************************************************************************/

class axi_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(axi_scoreboard)

  uvm_analysis_imp #(axi_txn, axi_scoreboard) imp;

  logic [7:0] ref_mem [0:64*1024-1];

  function new(string name = "axi_scoreboard",
               uvm_component parent = null);

    super.new(name, parent);

    imp = new("imp", this);

  endfunction
  
  
  
  function void write(axi_txn txn);

  logic [31:0] current_addr;
  logic [31:0] expected_data;


  // -------------------------------------------------
  // WRITE transaction
  // -------------------------------------------------
  if (txn.op == axi_txn::AXI_WRITE) begin

    current_addr = txn.addr;

    for (int beat = 0; beat <= txn.len; beat++) begin

      if (txn.wstrb[beat][0])
        ref_mem[current_addr + 0] =
          txn.write_data[beat][7:0];

      if (txn.wstrb[beat][1])
        ref_mem[current_addr + 1] =
          txn.write_data[beat][15:8];

      if (txn.wstrb[beat][2])
        ref_mem[current_addr + 2] =
          txn.write_data[beat][23:16];

      if (txn.wstrb[beat][3])
        ref_mem[current_addr + 3] =
          txn.write_data[beat][31:24];


      // Address for next beat
      if (txn.burst == axi_txn::INCR)
        current_addr =
          current_addr + (1 << txn.size);

      // FIXED: address stays unchanged

    end

  end


  // -------------------------------------------------
  // READ transaction
  // -------------------------------------------------
  else if (txn.op == axi_txn::AXI_READ) begin

    current_addr = txn.addr;

    for (int beat = 0; beat <= txn.len; beat++) begin

      // Build expected 32-bit data from reference memory
      expected_data = {
        ref_mem[current_addr + 3],
        ref_mem[current_addr + 2],
        ref_mem[current_addr + 1],
        ref_mem[current_addr + 0]
      };


      // Compare expected memory data with DUT data
      if (expected_data == txn.read_data[beat]) begin

       `uvm_info(
    "SCB",
    $sformatf(
      "Expected data = %0d, DUT read data = %0d",
      expected_data,
      txn.read_data[beat]
    ),
    UVM_LOW
  )

      end
      else begin

        `uvm_error(
          "SCB",
          "Expected data does not match DUT read data"
        )

      end


      // Address for next read beat
      if (txn.burst == axi_txn::INCR)
        current_addr =
          current_addr + (1 << txn.size);

      // FIXED: address stays unchanged

    end

  end

endfunction
  
  

endclass