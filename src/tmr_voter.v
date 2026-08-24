module tmr_voter(
	input decision_a,
	input decision_b,
	input decision_c,
	output tmr_decision,
	output fault_detected
	

);
assign tmr_decision = (decision_a & decision_b) | (decision_b & decision_c) | (decision_a & decision_c);

//if all 3 decisions dont agree, trigger fault
assign fault_detected = ((decision_a ^ decision_b) | (decision_b ^ decision_c));

endmodule