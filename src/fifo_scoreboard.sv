class fifo_scoreboard extends uvm_scoreboard;

  uvm_tlm_analysis_fifo #(fifo_write_seq_item) write_fifo;
  uvm_tlm_analysis_fifo #(fifo_read_seq_item) read_fifo;

  `uvm_component_utils(fifo_scoreboard)

  // Reference model
  bit [`DATA_WIDTH-1:0] ref_queue[$];
  int depth = 16; // FIFO depth
  bit exp_full=0 , exp_empty=1;

  // Statistics
  int write_count = 0;
  int read_count = 0;
  int successful_writes = 0;
  int successful_reads = 0;
  int match_count = 0;
  int mismatch_count = 0;
  int write_when_full = 0;
  int read_when_empty = 0;
  int full_mismatch = 0;
  int empty_mismatch = 0;

  function new(string name = "fifo_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    write_fifo = new("write_fifo", this);
    read_fifo  = new("read_fifo",  this);
  endfunction

  task run_phase(uvm_phase phase);
    fork
      process_writes();
      process_reads();
    join_none
  endtask

  // ----------------------------
  // WRITE SIDE PROCESSING
  // ----------------------------
  task process_writes();
    fifo_write_seq_item trans;
    forever begin
      write_fifo.get(trans);
      write_count++;

      // Expected full condition
       exp_full = (ref_queue.size() >= depth);

      // Compare DUT's wfull with expected
      if (trans.wfull !== exp_full) begin
        full_mismatch++;
        `uvm_error(get_type_name(),
          $sformatf("FULL FLAG MISMATCH: Expected=%0b Actual=%0b | Queue Size=%0d",
          exp_full, trans.wfull, ref_queue.size()))
      end

      // Handle write
      if (trans.winc) begin
        if (!exp_full) begin //ref_queue.size() < depth
        ref_queue.push_back(trans.wdata);
        successful_writes++;
        `uvm_info(get_type_name(),
          $sformatf("WRITE: data=0x%0h, Queue Size=%0d", trans.wdata, ref_queue.size()),
          UVM_MEDIUM)
        end
        else begin
        write_when_full++;
        `uvm_warning(get_type_name(), "WRITE attempted when FULL")
      end
      end

    end
  endtask

  // ----------------------------
  // READ SIDE PROCESSING
  // ----------------------------
  task process_reads();
    fifo_read_seq_item trans;
    bit [`DATA_WIDTH-1:0] expected_data;
    forever begin
      read_fifo.get(trans);
      read_count++;

      // Expected empty condition
       exp_empty = (ref_queue.size() == 0);
      $display("%0t exp_empty=%0b, ref_queue.size()=%0d", $time, exp_empty, ref_queue.size());
      // Compare DUT's rempty with expected
      if (trans.rempty !== exp_empty) begin
        empty_mismatch++;
        `uvm_error(get_type_name(),
          $sformatf("EMPTY FLAG MISMATCH: Expected=%0b Actual=%0b | Queue Size=%0d",exp_empty, trans.rempty, ref_queue.size()))
      end
      
      // Handle read
      if (trans.rinc) begin //&& !trans.rempty
        if (!exp_empty) begin //ref_queue.size() > 0    //!trans.rempty
          expected_data = ref_queue.pop_front();
          successful_reads++;
          
          if (expected_data == trans.rdata) begin
            match_count++;
            `uvm_info(get_type_name(),
              $sformatf("||||||| MATCH: Exp=0x%0h, Actual=0x%0h, Queue Size=%0d |||||||",expected_data, trans.rdata, ref_queue.size()),
              UVM_MEDIUM)
          end
          else begin
            mismatch_count++;
            `uvm_error(get_type_name(),
              $sformatf("||||||| DATA MISMATCH: Exp=0x%0h, Actual=0x%0h |||||||", expected_data, trans.rdata))
          end
        end
        else begin
          `uvm_error(get_type_name(), "Read from EMPTY reference queue!")
          read_when_empty++;
        end
      end
      
    end
  endtask

  // ----------------------------
  // REPORT PHASE
  // ----------------------------
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info(get_type_name(), "========================================", UVM_LOW)
    `uvm_info(get_type_name(), "      SCOREBOARD FINAL REPORT", UVM_LOW)
    `uvm_info(get_type_name(), "========================================", UVM_LOW)

    `uvm_info(get_type_name(), "\n--- Transaction Statistics ---", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Total Write Transactions: %0d", write_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Total Read Transactions: %0d", read_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Successful Writes: %0d", successful_writes), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Successful Reads: %0d", successful_reads), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Write When Full: %0d", write_when_full), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Read When Empty: %0d", read_when_empty), UVM_LOW)

    `uvm_info(get_type_name(), "\n--- Status Flag Verification ---", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("FULL Flag Mismatches: %0d", full_mismatch), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("EMPTY Flag Mismatches: %0d", empty_mismatch), UVM_LOW)

    `uvm_info(get_type_name(), "\n--- Data Verification ---", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Data Matches: %0d", match_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Data Mismatches: %0d", mismatch_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Final Queue Size: %0d", ref_queue.size()), UVM_LOW)

    `uvm_info(get_type_name(), "\n--- Analysis FIFO Status ---", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Write FIFO Remaining: %0d", write_fifo.size()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Read FIFO Remaining: %0d", read_fifo.size()), UVM_LOW)

    `uvm_info(get_type_name(), "\n========================================", UVM_LOW)

    // if (mismatch_count == 0 )
    //   `uvm_info(get_type_name(), "       *** TEST PASSED ***", UVM_LOW)
    // else
    //   `uvm_error(get_type_name(), "       *** TEST FAILED ***")

    `uvm_info(get_type_name(), "========================================", UVM_LOW)
  endfunction

endclass
