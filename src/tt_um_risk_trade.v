/*
 * Copyright (c) 2024 Denis Brown
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_risk_trade (
    input  wire [7:0] ui_in,  
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,  
    output wire [7:0] uio_out, 
    output wire [7:0] uio_oe,  
    input  wire       ena,    
    input  wire       clk, 
    input  wire       rst_n  
);

  reg [31:0] accum;
  reg [31:0] price_in_reg;
  reg [31:0] config_in_reg;
  reg [2:0] count;
  wire ready;
  
  wire byte_valid    = uio_in[0];
  wire is_config      = uio_in[1];
  wire [1:0] cfg_sel  = uio_in[3:2];
  wire _unused_uio    = &{uio_in[7:4], 1'b0};
  
  //We don't use this
  assign uio_oe  = 8'b00000000;
  assign uio_out = 8'd0;
  
  always @ (posedge clk) begin
    if (!rst_n) begin
      	count <=0;
    end else begin
      if (byte_valid) begin
        count <= (count == 3) ? 0 : count + 1;
      end else begin
        count <= count;
      end 
    end 
    
  end 
  
  wire [31:0] accum_next = {accum[23:0], ui_in};
  
  always @(posedge clk) begin
    if (!rst_n) begin
      accum <=0;
    end else begin
      if (byte_valid) begin
      	accum <= accum_next;
      end
    end 
    
  end 
  
  assign ready = (count == 3 && byte_valid) ? 1 : 0;
  
  always @(posedge clk) begin
    if (!rst_n) begin
      price_in_reg <= 0;
      config_in_reg <= 0;
    end else if (ready && !is_config) begin
      	price_in_reg <= accum_next;
    end else if (ready && is_config) begin
      	config_in_reg <= accum_next;
    end 
  end
  
  risk_engine dut1(
    .clk(clk),
    .rst_n(rst_n),
    .config_we(is_config),
    .config_select(cfg_sel),
    .config_data(config_in_reg),
    .price_in(price_in_reg),
    .tmr_decision(uo_out[0]),
    .fault_detected(uo_out[1])
  );
    
  assign uo_out[7:2] = 6'b0; 
  
endmodule
