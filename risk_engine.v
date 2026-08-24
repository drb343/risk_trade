`resetall
module risk_engine(
	input clk,
	input rst_n,
	input config_we,
	input [31:0] price_in,
	input [1:0] config_select,
	input [31:0] config_data,
	output tmr_decision,
	output fault_detected

);

//connects risk_core and tmr_voter, may expand later just a wrapper for now

wire out_risk_1;
wire out_risk_2;
wire out_risk_3;

risk_core_check uut1(
	.clk(clk),
	.rst_n(rst_n),
	.config_we(config_we),
	.price_in(price_in),
	.config_select(config_select),
	.config_data(config_data),
	.decision(out_risk_1)
);

risk_core_check uut2(
	.clk(clk),
	.rst_n(rst_n),
	.config_we(config_we),
	.price_in(price_in),
	.config_select(config_select),
	.config_data(config_data),
	.decision(out_risk_2)
);

risk_core_check uut3(
	.clk(clk),
	.rst_n(rst_n),
	.config_we(config_we),
	.price_in(price_in),
	.config_select(config_select),
	.config_data(config_data),
	.decision(out_risk_3)
);

tmr_voter uut4(
	.decision_a(out_risk_1),
	.decision_b(out_risk_2),
	.decision_c(out_risk_3),
	.tmr_decision(tmr_decision),
	.fault_detected(fault_detected)
);



endmodule