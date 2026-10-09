/******************************************************************************
 * Project     : AXI4 UVM Verification
 * File        : axi_driver.sv
 * Author      : Mirza Agha Malik Baig
 * Description : Drives AXI transactions and captures read data and write
 *               responses.
 *****************************************************************************/

class axi_driver extends uvm_driver #(axi_txn);
  `uvm_component_utils(axi_driver)
  
  virtual axi_if vif;
  axi_txn txn;
  
  function new(string name="axi_driver",
               uvm_component parent=null);
    super.new(name,parent);
  endfunction
  
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual axi_if):: get(
      this,"","vif",vif))
      
     `uvm_fatal("DRV","virtual interface not found")
      
  endfunction
      
    task run_phase(uvm_phase phase);
    
    init_signals();
     wait(vif.aresetn == 1'b1);

  forever begin

    seq_item_port.get_next_item(txn);

    drive(txn);

    seq_item_port.item_done();

  end

endtask
    
    
    
    task init_signals();

  vif.awvalid <= 1'b0;
  vif.wvalid  <= 1'b0;
  vif.wlast   <= 1'b0;
  vif.bready  <= 1'b0;

  vif.arvalid <= 1'b0;
  vif.rready  <= 1'b0;

endtask
    
    
    task drive(axi_txn txn);

  if (txn.op == axi_txn::AXI_WRITE)
    drive_write(txn);
  else
    drive_read(txn);

endtask
    
    
    
  
task drive_write(axi_txn txn);

  // Send write address/control
  @(posedge vif.aclk);

  vif.awid    <= txn.id;
  vif.awaddr  <= txn.addr;
  vif.awlen   <= txn.len;
  vif.awsize  <= txn.size;
  vif.awburst <= txn.burst;
  vif.awvalid <= 1'b1;

  // Wait for address handshake
  do begin
    @(posedge vif.aclk);
  end while (!vif.awready);

  vif.awvalid <= 1'b0;


  // Send write data beats
  for (int i = 0; i <= txn.len; i++) begin

    vif.wdata <= txn.write_data[i];
    vif.wstrb <= txn.wstrb[i];

    if (i == txn.len)
      vif.wlast <= 1'b1;
    else
      vif.wlast <= 1'b0;

    vif.wvalid <= 1'b1;

    // Hold current beat until slave accepts it
    do begin
      @(posedge vif.aclk);
    end while (!vif.wready);

  end

  vif.wvalid <= 1'b0;
  vif.wlast  <= 1'b0;


  // Accept write response
  vif.bready <= 1'b1;

  do begin
    @(posedge vif.aclk);
  end while (!vif.bvalid);

  // Capture response returned by the slave
  txn.bresp = axi_txn::axi_resp_e'(vif.bresp);

  if (vif.bid != txn.id)
    `uvm_error("DRV", "BID does not match write transaction ID")

  vif.bready <= 1'b0;

endtask
  
    
    
    task drive_read(axi_txn txn);

  // Send read address/control
  @(posedge vif.aclk);

  vif.arid    <= txn.id;
  vif.araddr  <= txn.addr;
  vif.arlen   <= txn.len;
  vif.arsize  <= txn.size;
  vif.arburst <= txn.burst;
  vif.arvalid <= 1'b1;

  // Wait until slave accepts the read address
  do begin
    @(posedge vif.aclk);
  end while (!vif.arready);

  vif.arvalid <= 1'b0;


  // Make space to store returned read beats
  txn.read_data = new[txn.len + 1];
  txn.rresp     = new[txn.len + 1];


  // Master is ready to accept read data
  vif.rready <= 1'b1;

  for (int i = 0; i <= txn.len; i++) begin

    // Wait for one valid read beat
    do begin
      @(posedge vif.aclk);
    end while (!vif.rvalid);

    // RVALID && RREADY handshake happened
    txn.read_data[i] = vif.rdata;
    txn.rresp[i] =
        axi_txn::axi_resp_e'(vif.rresp);


    // Check transaction ID
    if (vif.rid != txn.id)
      `uvm_error("DRV",
                 "RID does not match requested ID")


    // Check RLAST
    if (i == txn.len) begin

      if (!vif.rlast)
        `uvm_error("DRV",
                   "RLAST missing on final read beat")

    end
    else begin

      if (vif.rlast)
        `uvm_error("DRV",
                   "RLAST asserted before final read beat")

    end

  end


  // Finished receiving the read burst
  vif.rready <= 1'b0;

endtask
      
      
endclass