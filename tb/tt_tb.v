`timescale 1ns/1ps
module tt_tb;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  reg ena, rst_n;
  reg clk = 0;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
  
  //We need to ensure the wrapper itself can feed the TT in a correct manner

  tt_um_risk_trade dut2(
    .clk(clk), .rst_n(rst_n), .ena(ena),
    .ui_in(ui_in), .uio_in(uio_in),
    .uo_out(uo_out), .uio_out(uio_out), .uio_oe(uio_oe)
  );

  always #5 clk = ~clk;
  
  //We send a byte on the nedge of the clock, focusing on configuration first, then prices

  task send_byte(input [7:0] data, input cfg, input [1:0] sel);
    begin
      @(negedge clk);
      uio_in = {4'b0, sel, cfg, 1'b1};
      ui_in = data;
    end
  endtask
  
  //Send no data, just idle clock, with byte_valid = 0

  task idle_cycle(input cfg, input [1:0] sel);
    begin
      @(negedge clk);
      uio_in = {4'b0, sel, cfg, 1'b0};
    end
  endtask


  
  initial begin
    rst_n = 0; ena = 0; ui_in = 0; uio_in = 0;
	 
	 //Once reset deasserted we begin
    #12 rst_n = 1;
	 
	 //Send ref price config info first, MSB

    send_byte(8'h00, 1, 2'd0);
    send_byte(8'h00, 1, 2'd0);
    send_byte(8'h03, 1, 2'd0);
    send_byte(8'hE8, 1, 2'd0);
    idle_cycle(1, 2'd0);

	 //Send collar tick information second
	 
    send_byte(8'h00, 1, 2'd1);
    send_byte(8'h00, 1, 2'd1);
    send_byte(8'h00, 1, 2'd1);
    send_byte(8'h32, 1, 2'd1);
    idle_cycle(1, 2'd1);
	 
	 //Send diff threshold information

    send_byte(8'h00, 1, 2'd2);
    send_byte(8'h00, 1, 2'd2);
    send_byte(8'h07, 1, 2'd2);
    send_byte(8'hD0, 1, 2'd2);
    idle_cycle(1, 2'd2);
	 
	 //Send actual incoming prices last

    send_byte(8'h00, 0, 2'd0);
    send_byte(8'h00, 0, 2'd0);
    send_byte(8'h03, 0, 2'd0);
    send_byte(8'hE8, 0, 2'd0);
    idle_cycle(0, 2'd0);

    @(posedge clk);
    @(posedge clk);
    $display("price=1000 decision=%b fault=%b", uo_out[0], uo_out[1]);
	 
	 //Send a second incoming price (1010)

    send_byte(8'h00, 0, 2'd0);
    send_byte(8'h00, 0, 2'd0);
    send_byte(8'h03, 0, 2'd0);
    send_byte(8'hF2, 0, 2'd0);
    idle_cycle(0, 2'd0);

    @(posedge clk);
    @(posedge clk);
    $display("price=1010 decision=%b fault=%b", uo_out[0], uo_out[1]);

    $finish;
  end
endmodule