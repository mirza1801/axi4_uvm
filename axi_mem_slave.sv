/******************************************************************************
 * Project     : AXI4 UVM Verification
 * File        : axi_mem_slave.sv
 * Author      : Mirza Agha Malik Baig
 * Description : Implements a simple byte-addressable AXI4 memory slave
 *               for testbench use.
 *****************************************************************************/

module axi_mem_slave #(
    parameter int MEM_BYTES = 64*1024
)(
    axi_if axi
);

  // Byte-addressable memory
  logic [7:0] mem [0:MEM_BYTES-1];


  // =========================================================
  // Write-side state
  // =========================================================

  logic [3:0]  saved_wr_id;
  logic [7:0]  saved_wr_len;
  logic [2:0]  saved_wr_size;
  logic [1:0]  saved_wr_burst;

  logic [31:0] wr_addr;
  logic [7:0]  wr_beat_count;

  logic        write_active;


  // =========================================================
  // Read-side state
  // =========================================================

  logic [3:0]  saved_rd_id;
  logic [7:0]  saved_rd_len;
  logic [2:0]  saved_rd_size;
  logic [1:0]  saved_rd_burst;

  logic [31:0] rd_addr;
  logic [7:0]  rd_beat_count;

  logic        read_active;


  // =========================================================
  // READY generation
  // =========================================================

  // Accept a new write address only when free
  assign axi.awready =
         axi.aresetn &&
         !write_active;

  // Simple DUT:
  // accept W only after AW has already been accepted
  assign axi.wready =
         axi.aresetn &&
         write_active &&
         !axi.bvalid;

  // Accept new read address only when free
  assign axi.arready =
         axi.aresetn &&
         !read_active;


  // =========================================================
  // Sequential logic
  // =========================================================

  always_ff @(posedge axi.aclk or negedge axi.aresetn) begin

    if (!axi.aresetn) begin

      // -------------------------
      // Write reset
      // -------------------------

      saved_wr_id    <= '0;
      saved_wr_len   <= '0;
      saved_wr_size  <= '0;
      saved_wr_burst <= '0;

      wr_addr        <= '0;
      wr_beat_count  <= '0;

      write_active   <= 1'b0;

      axi.bvalid     <= 1'b0;
      axi.bid        <= '0;
      axi.bresp      <= 2'b00;


      // -------------------------
      // Read reset
      // -------------------------

      saved_rd_id    <= '0;
      saved_rd_len   <= '0;
      saved_rd_size  <= '0;
      saved_rd_burst <= '0;

      rd_addr        <= '0;
      rd_beat_count  <= '0;

      read_active    <= 1'b0;

      axi.rvalid     <= 1'b0;
      axi.rid        <= '0;
      axi.rdata      <= '0;
      axi.rresp      <= 2'b00;
      axi.rlast      <= 1'b0;

    end

    else begin


      // =====================================================
      // AW CHANNEL
      // =====================================================

      if (axi.awvalid && axi.awready) begin

        saved_wr_id    <= axi.awid;
        saved_wr_len   <= axi.awlen;
        saved_wr_size  <= axi.awsize;
        saved_wr_burst <= axi.awburst;

        wr_addr        <= axi.awaddr;
        wr_beat_count  <= 0;

        write_active   <= 1'b1;

      end


      // =====================================================
      // W CHANNEL
      // =====================================================

      if (axi.wvalid && axi.wready) begin

        // Write enabled byte lanes

        if (axi.wstrb[0])
          mem[wr_addr + 0] <= axi.wdata[7:0];

        if (axi.wstrb[1])
          mem[wr_addr + 1] <= axi.wdata[15:8];

        if (axi.wstrb[2])
          mem[wr_addr + 2] <= axi.wdata[23:16];

        if (axi.wstrb[3])
          mem[wr_addr + 3] <= axi.wdata[31:24];


        // More W beats remain
        if (wr_beat_count != saved_wr_len) begin

          wr_beat_count <= wr_beat_count + 1;

          // INCR burst
          if (saved_wr_burst == 2'b01)
            wr_addr <= wr_addr +
                       (32'd1 << saved_wr_size);

          // FIXED burst:
          // address remains unchanged

        end

        // Final W beat
        else begin

          // Final expected beat must have WLAST
          if (!axi.wlast)
            $error("WLAST missing on final write beat");

          // Start write response
          axi.bvalid <= 1'b1;
          axi.bid    <= saved_wr_id;
          axi.bresp  <= 2'b00;       // OKAY

        end

      end


      // =====================================================
      // B CHANNEL
      // =====================================================

      if (axi.bvalid && axi.bready) begin

        // Master accepted B response
        axi.bvalid   <= 1'b0;

        // Write transaction completely finished
        write_active <= 1'b0;

      end


      // =====================================================
      // AR CHANNEL
      // =====================================================

      if (axi.arvalid && axi.arready) begin

        saved_rd_id    <= axi.arid;
        saved_rd_len   <= axi.arlen;
        saved_rd_size  <= axi.arsize;
        saved_rd_burst <= axi.arburst;

        rd_addr        <= axi.araddr;
        rd_beat_count  <= 0;

        read_active    <= 1'b1;

      end


      // =====================================================
      // PREPARE R BEAT
      // =====================================================

      /*
       * Prepare a new R beat only when RVALID is currently low.
       *
       * If RVALID = 1 and RREADY = 0,
       * RDATA/RID/RRESP/RLAST must remain stable.
       */

      if (read_active && !axi.rvalid) begin

        axi.rid <= saved_rd_id;

        axi.rdata <= {
          mem[rd_addr + 3],
          mem[rd_addr + 2],
          mem[rd_addr + 1],
          mem[rd_addr + 0]
        };

        axi.rresp <= 2'b00;       // OKAY


        // Last read beat?
        if (rd_beat_count == saved_rd_len)
          axi.rlast <= 1'b1;
        else
          axi.rlast <= 1'b0;


        axi.rvalid <= 1'b1;

      end


      // =====================================================
      // R CHANNEL HANDSHAKE
      // =====================================================

      if (axi.rvalid && axi.rready) begin

        // Current R beat was accepted
        axi.rvalid <= 1'b0;


        // -----------------------------------------------
        // Final read beat
        // -----------------------------------------------

        if (rd_beat_count == saved_rd_len) begin

          // RLAST was 1 during this handshake.
          // Now the burst is finished.
          axi.rlast  <= 1'b0;

          read_active <= 1'b0;

        end


        // -----------------------------------------------
        // More read beats remain
        // -----------------------------------------------

        else begin

          rd_beat_count <= rd_beat_count + 1;

          // INCR burst
          if (saved_rd_burst == 2'b01)
            rd_addr <= rd_addr +
                       (32'd1 << saved_rd_size);

          // FIXED burst:
          // address remains unchanged

        end

      end

    end

  end

endmodule