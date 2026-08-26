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
  //per TT standards, data can only get passed in as single bytes, however risk_engine modules requires 4 bytes
  reg [31:0] accum;
  reg [31:0] price_in_reg;
  reg [31:0] config_in_reg;
  reg [2:0] count;
  reg ready_d;
  wire ready;
  
  wire byte_valid    = uio_in[0];
  wire is_config      = uio_in[1];
  wire [1:0] cfg_sel  = uio_in[3:2];
  wire _unused_uio    = &{uio_in[7:4], 1'b0};
  
  //We don't use this
  assign uio_oe  = 8'b00000000;
  assign uio_out = 8'd0;
  

  //Keep a running count of all of the bytes passed in, when it reaches 4 bytes reset
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
  
  //Accumulate the incoming byte into the 4 byte register
  wire [31:0] accum_next = {accum[23:0], ui_in};
  

  //PAss it into the register
  always @(posedge clk) begin
    if (!rst_n) begin
      accum <=0;
    end else begin
      if (byte_valid) begin
      	accum <= accum_next;
      end
    end 
    
  end 
  
  //Once all 4 bytes are inside the register, we are ready to change price or config going into risk_engine
  assign ready = (count == 3 && byte_valid) ? 1 : 0;
  
  //Depending on is_config flag, or accum register will either hold config or price data
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

  //ready needs to be delayed by one cycle to accomodate when accum has all 4 data bytes
  always @(posedge clk) begin
    if (!rst_n) begin
      ready_d <= 1'b0;
    end else begin
      ready_d <= ready;
    end
  end
  
  risk_engine dut1(
    .clk(clk),
    .rst_n(rst_n),
    .config_we(ready_d && is_config),
    .config_select(cfg_sel),
    .config_data(config_in_reg),
    .price_in(price_in_reg),
    .tmr_decision(uo_out[0]),
    .fault_detected(uo_out[1])
  );
    

  //Only need first 2 bits of uo_out per risk_engine convention
  assign uo_out[7:2] = 6'b0; 
  
endmodule
