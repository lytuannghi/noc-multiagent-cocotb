// ============================================================================
// File: noc_matrix_arbiter.v
// Module: noc_matrix_arbiter
// Description: Starvation-Free 5-Input Round-Robin Arbiter for Switch Allocation
// Author: Qwen 2.5 Coder
// ============================================================================

`include "noc_pkg.vh"

module noc_matrix_arbiter (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [`NUM_PORTS-1:0]  req,       // [4:0] = {West, East, South, North, Local}
    output reg  [`NUM_PORTS-1:0]  grant,     // One-hot grant vector
    output wire                   grant_valid
);

    reg [2:0] priority_ptr; // Points to current highest-priority port (0..4)

    assign grant_valid = |grant;

    // Combinational Grant Evaluation based on rotating priority
    always @(*) begin
        grant = 5'b00000;
        case (priority_ptr)
            3'd0: begin
                if      (req[0]) grant = 5'b00001;
                else if (req[1]) grant = 5'b00010;
                else if (req[2]) grant = 5'b00100;
                else if (req[3]) grant = 5'b01000;
                else if (req[4]) grant = 5'b10000;
            end
            3'd1: begin
                if      (req[1]) grant = 5'b00010;
                else if (req[2]) grant = 5'b00100;
                else if (req[3]) grant = 5'b01000;
                else if (req[4]) grant = 5'b10000;
                else if (req[0]) grant = 5'b00001;
            end
            3'd2: begin
                if      (req[2]) grant = 5'b00100;
                else if (req[3]) grant = 5'b01000;
                else if (req[4]) grant = 5'b10000;
                else if (req[0]) grant = 5'b00001;
                else if (req[1]) grant = 5'b00010;
            end
            3'd3: begin
                if      (req[3]) grant = 5'b01000;
                else if (req[4]) grant = 5'b10000;
                else if (req[0]) grant = 5'b00001;
                else if (req[1]) grant = 5'b00010;
                else if (req[2]) grant = 5'b00100;
            end
            3'd4: begin
                if      (req[4]) grant = 5'b10000;
                else if (req[0]) grant = 5'b00001;
                else if (req[1]) grant = 5'b00010;
                else if (req[2]) grant = 5'b00100;
                else if (req[3]) grant = 5'b01000;
            end
            default: begin
                if      (req[0]) grant = 5'b00001;
                else if (req[1]) grant = 5'b00010;
                else if (req[2]) grant = 5'b00100;
                else if (req[3]) grant = 5'b01000;
                else if (req[4]) grant = 5'b10000;
            end
        endcase
    end

    // Sequential Priority Update upon successful grant
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_ptr <= 3'd0;
        end else if (grant_valid) begin
            case (grant)
                5'b00001: priority_ptr <= 3'd1;
                5'b00010: priority_ptr <= 3'd2;
                5'b00100: priority_ptr <= 3'd3;
                5'b01000: priority_ptr <= 3'd4;
                5'b10000: priority_ptr <= 3'd0;
                default:  priority_ptr <= 3'd0;
            endcase
        end
    end

endmodule
