/*
 * Copyright (c) 2025 Dylan Toussaint, Justin Fok
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/*
 Module fp_to_fixed
 Converts 32 bit floating point numbers to 3.16 fixed point format.
 */
module fp_to_fixed #(
    parameter int Q = 3
)(
    input  wire     [31:0] fp_in,
    output reg      [18:0] fp_out,
    output reg             fp_input_invalid_flag
);

    localparam [7:0]  PI_EXP  = 8'd128;
    localparam [22:0] PI_FRAC = 23'h490FDB;

    wire             sign;
    wire  [7:0]      exp;
    wire  [22:0]     frac;
    wire  [23:0]     mant;
    reg   [23+Q-1:0] imm;

    //Need to handle special cases...
    wire is_zero = (exp == 8'd0)   && (frac == 23'd0);
    wire is_sub  = (exp == 8'd0)   && (frac != 23'd0);
    wire is_inf  = (exp == 8'd255) && (frac == 23'd0);
    wire is_nan  = (exp == 8'd255) && (frac != 23'd0);

    reg signed [8:0]      shift;

    assign sign = fp_in[31];
    assign exp  = fp_in[30:23];
    assign frac = fp_in[22:0];
    assign mant = is_sub ? {1'b0, frac} : {1'b1, frac};

    wire out_of_range = (exp > PI_EXP) || ((exp == PI_EXP) && ({1'b1, frac} > {1'b1, PI_FRAC}));

    always @* begin
        fp_out   = 19'd0;
        shift    = 9'd0;
        imm      = '0;

        if(is_zero) begin
            fp_out                = 19'd0;
            fp_input_invalid_flag = 1'b0;
        end else if (is_nan || is_inf || out_of_range) begin
            fp_out                = 19'd0;
            fp_input_invalid_flag = 1'b1;
        end else begin
            fp_input_invalid_flag = 1'b0;

            shift = is_sub ? -9'sd126  : ({1'b0, exp} - 9'sd127);

            if(shift >= 9'sd0) begin
                imm = sign ? - ({2'b0, mant} << shift) : ({2'b0, mant} << shift);
                fp_out = imm[23+Q-1:23+Q-1-18];
            end else begin
                imm = sign ? - ({2'b0, mant} >>> (-shift)) : ({2'b0, mant} >>> (-shift));
                fp_out = imm[23+Q-1:23+Q-1-18];
            end
        end
    end

endmodule
