//Takes in a clock and a threshold value.
//Simply outputs a 1 if a counter exceeds a threshold, or a 0 otherwise.

module PWM_Module (input wire   clk,
                   input wire reset,
                   input wire[7:0] threshold,
                   output wire   pwm_out);

reg [7:0] counter;

assign  pwm_out = counter < threshold ? 1 : 0;

 always @ (posedge clk, posedge reset) begin
        if (reset == 1) begin
                counter <= 0;
        end else begin
                if (counter == 245)	//Don't go quite to 255 so we can avoid
					//excessive flickering on LED's
                        counter <= 0;
                else
                        counter <= counter + 1;
        end
end
endmodule
