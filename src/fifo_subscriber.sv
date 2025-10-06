class fifo_subscriber extends uvm_component;
  `uvm_component_utils(fifo_subscriber)

  // Two analysis exports — one for write, one for read
  uvm_tlm_analysis_fifo #(fifo_write_seq_item) write_fifo;
  uvm_tlm_analysis_fifo #(fifo_read_seq_item) read_fifo;


  fifo_write_seq_item wr_item;
  fifo_read_seq_item  rd_item;

   real wr_coverage, rd_coverage;

  // --------------------------
  // Covergroups
  // --------------------------

  // Write coverage
  covergroup write_cg @(wr_item);
    option.per_instance = 1;
    wdata_cp  : coverpoint wr_item.wdata { bins all_data = {[0:(2*`DATA_WIDTH)-1]}; }
    winc_cp  : coverpoint wr_item.winc  { bins inc_on  = {1}; bins inc_off = {0}; }
    wfull_cp  : coverpoint wr_item.wfull { bins full_b  = {1}; bins not_full = {0}; }

    wr_cross : cross wdata_cp, winc_cp, wfull_cp;
  endgroup

  // Read coverage
  covergroup read_cg @(rd_item);
    option.per_instance = 1;
    rdata_cp  : coverpoint rd_item.rdata  { bins all_data = {[0:(2*`DATA_WIDTH)-1]}; }
    rinc_cp  : coverpoint rd_item.rinc   { bins inc_on  = {1}; bins inc_off = {0}; }
    rempty_cp : coverpoint rd_item.rempty { bins empty_b = {1}; bins not_empty = {0}; }

    rd_cross : cross rdata_cp, rinc_cp, rempty_cp;
  endgroup

  // --------------------------
  // Constructor
  // --------------------------
  function new(string name = "fifo_subscriber", uvm_component parent = null);
    super.new(name, parent);
    write_fifo = new("write_fifo", this);
    read_fifo  = new("read_fifo", this);
    write_cg = new();
    read_cg  = new();
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
      forever begin
        write_fifo.get(wr_item);
        write_cg.sample();
        read_fifo.get(rd_item);
        read_cg.sample();
      end
  endtask
  
  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    wr_coverage = write_cg.get_coverage();
    rd_coverage = read_cg.get_coverage();
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("[Write] Coverage : %0.2f%%", wr_coverage), UVM_MEDIUM);
    `uvm_info(get_type_name(), $sformatf("[Read] Coverage : %0.2f%%", rd_coverage), UVM_MEDIUM);
  endfunction 
endclass


