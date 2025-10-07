interface fifo_if  (input bit wclk, input bit rclk, input bit wrst_n, input bit rrst_n);

// #(parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 4 )
 // Write interface signals
  logic [`DATA_WIDTH-1:0] wdata;
  logic winc;
  bit wfull;
  logic [`ADDR_WIDTH:0] wptr;
  
  // Read interface signals
  logic [`DATA_WIDTH-1:0] rdata;
  logic rinc;
  logic rempty;
  logic [`ADDR_WIDTH:0] rptr;

  // Clocking blocks for synchronization
  clocking wdrv_cb @(posedge wclk);
    // default input #0 output #0;
    output wdata;
    output winc;
    input wfull;
    // input wptr;
  endclocking
  
  clocking rdrv_cb @(posedge rclk);
    // default input #0 output #0;
    output rinc;
    input rempty;
    // input rptr;
  endclocking
  
  // Monitor clocking blocks
  clocking wmon_cb @(posedge wclk);
    default input #0;
    input wdata;
    input winc;
    input wfull;
    input wptr;
  endclocking
  
  clocking rmon_cb @(posedge rclk);
    default input #0;
    input rdata;
    input rinc;
    input rempty;
    input rptr;
  endclocking
  
  // // Modports for drivers
  // modport wdrv_mp (
  //   clocking wdrv_cb,
  // );
  
  // modport rdrv_mp (
  //   clocking rdrv_cb,
  // );
  
  // // Modports for monitors
  // modport wmon_mp (
  //   clocking wmon_cb,
  // );
  
  // modport rmon_mp (
  //   clocking rmon_cb,
  // );
  

   //Assertions 
    
//      property p1;
//     @(posedge wclk) disable iff(!wrst_n)
//       winc |=> !wfull;
//   endproperty
//   assert property(p1)
//     else $error("p1 FAILED: Write attempted when FIFO is FULL!");

  property p2;
    @(posedge wclk) disable iff(!wrst_n)
      (winc && wfull) |-> $stable(wdata);
  endproperty
  assert property(p2)
    else $error("p2 FAILED: Data changed during write when FULL!");

  property p3;
    @(posedge rclk) disable iff(!rrst_n)
      rinc |-> !rempty;
  endproperty
  assert property(p3)
    else $error("p3 FAILED: Read attempted when FIFO is EMPTY!");

  property p4;
    @(posedge rclk) disable iff(!rrst_n)
      (rinc && !rempty) |-> !$isunknown(rdata);
  endproperty
  assert property(p4)
    else $error("p4 FAILED: rdata is X/Z on valid read!");

  property p5;
    @(posedge wclk) disable iff(!wrst_n)
      !(wfull && rempty);
  endproperty
  assert property(p5)
    else $error("p5 FAILED: FIFO signaled FULL and EMPTY simultaneously!");
    
endinterface
