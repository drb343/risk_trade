`timescale 1ns/1ps

//going to test TMR logic with a sucessful decision and a 2/3 decision, see how well it works
module tb_fault_detection;
	reg clk;
	reg rst_n;
	reg config_we;
	reg [31:0] price_in;
	reg [1:0] config_select;
	reg [31:0] config_data;
	wire tmr_decision;
	wire fault_detected;


risk_engine dut1(
	.clk(clk),
	.rst_n(rst_n),
	.config_we(config_we),
	.price_in(price_in),
	.config_select(config_select),
	.config_data(config_data),
	.tmr_decision(tmr_decision),
	.fault_detected(fault_detected)
);

always #5 clk = ~clk;

//test and init
initial begin
    clk = 0;
    rst_n = 0;
    config_we = 0;
    config_select = 2'd0;
    config_data = 32'd0;
    price_in = 32'd0;
    @(posedge clk);
    rst_n = 1;

    @(posedge clk);
    config_select = 2'd0;
    config_we = 1;
    config_data = 32'd1000;
	 
    @(posedge clk);
    config_select = 2'd1;
    config_data = {16'd0, 16'd50};
	 
    @(posedge clk);
    config_select = 2'd2;
    config_data = 32'd2000;
	 
    @(posedge clk);
    config_we = 0;
    price_in = 32'd1000;
    $display("decision: %d, fault detected: %d", tmr_decision, fault_detected); //decision should be 0, no fault

    @(posedge clk);
    config_we = 0;
    price_in = 32'd1010;

    @(posedge clk);
    $display("decision: %d, fault detected: %d", tmr_decision, fault_detected); //decision should be 1, no fault
    config_we = 0;
    force dut1.uut2.decision = 0;

    @(posedge clk);
    $display("decision: %d, fault detected: %d", tmr_decision, fault_detected); //decision should be 0, fault
    release dut1.uut2.decision;

end

endmodule