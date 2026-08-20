`resetall
module risk_core_check(
	input clk,
	input rst_n,
	input config_we,
	input [31:0] price_in,
	input config_select,
	input [31:0] config_data,
	output reg decision
	
);

reg [15:0] collar_ticks_reg;
reg [31:0] ref_price_reg;


always @ (posedge clk) begin
	if (!rst_n) begin
		decision <= 0;
	end else begin
		if (((ref_price_reg - collar_ticks_reg) <= price_in) && (price_in <= (ref_price_reg + collar_ticks_reg))) begin
			decision <= 1;
		end else begin
			decision <= 0;
		end 
	end 


end 

always @(posedge clk) begin
    if (!rst_n) begin
        ref_price_reg    <= 32'd0;
        collar_ticks_reg <= 16'd0;
    end else if (config_we && config_select == 1'b0) begin
        ref_price_reg <= config_data;
    end else if (config_we && config_select == 1'b1) begin
        collar_ticks_reg <= config_data[15:0];
    end
end




endmodule