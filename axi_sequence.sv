class axi_sequence extends uvm_sequence #(axi_txn);

  `uvm_object_utils(axi_sequence)

  function new(string name = "axi_sequence");
    super.new(name);
  endfunction


  task body();

    axi_txn txn;
    axi_txn txn_1;
    axi_txn txn_2;

    // First transaction: fully constrained-random
    txn = axi_txn::type_id::create("txn");

    start_item(txn);

    assert(txn.randomize());

    finish_item(txn);


    // Second transaction: directed single-beat write
    txn_1 = axi_txn::type_id::create("txn_1");

    start_item(txn_1);

    assert(txn_1.randomize() with {
      op            == axi_txn::AXI_WRITE;
      addr          == 32'd100;
      len           == 0;
      size          == 2;
      burst         == axi_txn::INCR;
      id            == 0;
      write_data[0] == 32'd50;
      wstrb[0]      == 4'b1111;
    });

    finish_item(txn_1);
    
    
    txn_2 = axi_txn::type_id::create("txn_2");

start_item(txn_2);

assert(txn_2.randomize() with {
    op    == axi_txn::AXI_READ;
    addr  == 32'd100;
    len   == 0;
    size  == 2;
    burst == axi_txn::INCR;
    id    == 0;
});

finish_item(txn_2);

  endtask

endclass