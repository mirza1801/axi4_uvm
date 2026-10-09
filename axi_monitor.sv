/*******************************************************************************
 * Project     : AXI4 UVM Verification
 * File        : axi_monitor.sv
 * Author      : Mirza Agha Malik Baig
 * Description : Reconstructs completed AXI read and write transactions from bus handshakes.
 ******************************************************************************/

class axi_monitor extends uvm_monitor;

  `uvm_component_utils(axi_monitor)

  virtual axi_if vif;

  uvm_analysis_port #(axi_txn) ap;

  axi_txn wr_txn;
  axi_txn rd_txn;

  int wr_beat_idx;
  int rd_beat_idx;


  function new(string name = "axi_monitor",
               uvm_component parent = null);

    super.new(name, parent);

    ap = new("ap", this);

  endfunction


  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(virtual axi_if)::get(
          this, "", "vif", vif))
      `uvm_fatal("MON", "virtual interface not found")

  endfunction


  task run_phase(uvm_phase phase);

    forever begin

      @(posedge vif.aclk);


      // -----------------------------------------------------
      // AW channel
      // -----------------------------------------------------

      if (vif.awvalid && vif.awready) begin

        wr_txn = axi_txn::type_id::create("wr_txn");

        wr_txn.op    = axi_txn::AXI_WRITE;
        wr_txn.id    = vif.awid;
        wr_txn.addr  = vif.awaddr;
        wr_txn.len   = vif.awlen;
        wr_txn.size  = vif.awsize;
        wr_txn.burst =
          axi_txn::axi_burst_e'(vif.awburst);

        // AWLEN tells us how many W beats are expected
        wr_txn.write_data = new[vif.awlen + 1];
        wr_txn.wstrb      = new[vif.awlen + 1];

        wr_beat_idx = 0;

      end


      // -----------------------------------------------------
      // W channel
      // -----------------------------------------------------

      if (vif.wvalid && vif.wready) begin

        // One W handshake = one W beat
        wr_txn.write_data[wr_beat_idx] = vif.wdata;
        wr_txn.wstrb[wr_beat_idx]      = vif.wstrb;

        if (wr_beat_idx != wr_txn.len)
          wr_beat_idx = wr_beat_idx + 1;

      end


      // -----------------------------------------------------
      // B channel
      // -----------------------------------------------------

      if (vif.bvalid && vif.bready) begin

        wr_txn.bresp =
          axi_txn::axi_resp_e'(vif.bresp);

        if (vif.bid != wr_txn.id)
          `uvm_error("MON", "BID does not match AWID")

        // Entire observed write transaction is complete
        ap.write(wr_txn);

      end


      // -----------------------------------------------------
      // AR channel
      // -----------------------------------------------------

      if (vif.arvalid && vif.arready) begin

        rd_txn = axi_txn::type_id::create("rd_txn");

        rd_txn.op    = axi_txn::AXI_READ;
        rd_txn.id    = vif.arid;
        rd_txn.addr  = vif.araddr;
        rd_txn.len   = vif.arlen;
        rd_txn.size  = vif.arsize;
        rd_txn.burst =
          axi_txn::axi_burst_e'(vif.arburst);

        // ARLEN tells us how many R beats are expected
        rd_txn.read_data = new[vif.arlen + 1];
        rd_txn.rresp     = new[vif.arlen + 1];

        rd_beat_idx = 0;

      end


      // -----------------------------------------------------
      // R channel
      // -----------------------------------------------------

      if (vif.rvalid && vif.rready) begin

        // One R handshake = one R beat
        rd_txn.read_data[rd_beat_idx] = vif.rdata;

        rd_txn.rresp[rd_beat_idx] =
          axi_txn::axi_resp_e'(vif.rresp);


        // RID should match the original ARID
        if (vif.rid != rd_txn.id)
          `uvm_error("MON", "RID does not match ARID")


        // More R beats remain
        if (rd_beat_idx != rd_txn.len) begin

          rd_beat_idx = rd_beat_idx + 1;

        end

        // Final R beat
        else begin

          if (!vif.rlast)
            `uvm_error(
              "MON",
              "RLAST not asserted on final read beat"
            )

          // Entire observed read transaction is complete
          ap.write(rd_txn);

        end

      end

    end

  endtask

endclass