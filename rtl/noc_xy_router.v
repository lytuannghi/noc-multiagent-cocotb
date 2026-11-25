`timescale 1ns / 1ps

// ============================================================================
// File: noc_xy_router.v
// Module: noc_xy_router
// Description: Dimension-Order X-Y Routing Computation Unit (Deadlock-Free)
// Author: Gemini Architect & DeepSeek-R1 DV Lead (Enforced VETO against Y-X turns)
// ============================================================================

`include "noc_pkg.vh"

module noc_xy_router #(
    parameter CUR_X = 2'd0,
    parameter CUR_Y = 2'd0
)(
    input  wire [`COORD_WIDTH-1:0] dst_x,
    input  wire [`COORD_WIDTH-1:0] dst_y,
    output reg  [2:0]              target_port
);

    always @(*) begin
        // Dimension-Order Routing Rule: First resolve X axis, then Y axis.
        if (dst_x > CUR_X) begin
            target_port = `PORT_EAST;
        end else if (dst_x < CUR_X) begin
            target_port = `PORT_WEST;
        end else if (dst_y > CUR_Y) begin
            target_port = `PORT_SOUTH;
        end else if (dst_y < CUR_Y) begin
            target_port = `PORT_NORTH;
        end else begin
            // Destination reached: delivered to local core
            target_port = `PORT_LOCAL;
        end
    end

endmodule
