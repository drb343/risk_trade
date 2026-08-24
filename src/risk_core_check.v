`resetall
module risk_core_check(
	input clk,
	input rst_n,
	input config_we,
	input [31:0] price_in,
	input [1:0] config_select,
	input [31:0] config_data,
	output reg decision
	
);

reg [15:0] collar_ticks_reg;
reg [31:0] ref_price_reg;
reg [31:0] prev_price;
reg [15:0] diff_threshold;
wire signed [32:0] diff;

assign diff = $signed({1'b0, price_in}) - $signed({1'b0, prev_price});

//Basic logic: if an incoming price falls within a certain band we have a positive deicision, else no
//Upgraded logic to also include drastic price changes resulting in a low decision
//collar_tick acts as a safety margin before approaching a high ref price

always @ (posedge clk) begin
	if (!rst_n) begin
		decision <= 0;
		prev_price <= 0;
	end else begin
		if (((ref_price_reg - collar_ticks_reg) <= price_in) && (price_in <= (ref_price_reg + collar_ticks_reg)) && (((diff>= 0)? diff : -diff) <= diff_threshold)) begin
			decision <= 1;
			prev_price <= price_in;
		end else begin
			decision <= 0;
			prev_price <= prev_price;
		end 
	end 
end 

//depending on select signals we may sometimes update these values

always @(posedge clk) begin
    if (!rst_n) begin
        ref_price_reg    <= 32'd0;
        collar_ticks_reg <= 16'd0;
		  diff_threshold <= 16'd0;
    end else if (config_we && config_select == 2'd0) begin
        ref_price_reg <= config_data;
    end else if (config_we && config_select == 2'd1) begin
        collar_ticks_reg <= config_data[15:0];
    end else if (config_we && config_select == 2'd2) begin
		  diff_threshold <= config_data[15:0];
	 end 
end




endmodule