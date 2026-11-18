// ============================================================================
// File: noc_crossbar.v
// Module: noc_crossbar
// Description: Full 5x5 Non-Blocking Crossbar Switch for NoC Router
// Author: Qwen 2.5 Coder
// ============================================================================

`include "noc_pkg.vh"

module noc_crossbar #(
    parameter DATA_WIDTH = `FLIT_WIDTH
)(
    // Input Port Data (from VC buffers)
    input  wire [DATA_WIDTH-1:0] din_local,
    input  wire [DATA_WIDTH-1:0] din_north,
    input  wire [DATA_WIDTH-1:0] din_south,
    input  wire [DATA_WIDTH-1:0] din_east,
    input  wire [DATA_WIDTH-1:0] din_west,

    // Grant vectors from 5 arbiters (one arbiter per output port)
    // grant_X[0]=Local, [1]=North, [2]=South, [3]=East, [4]=West
    input  wire [`NUM_PORTS-1:0] grant_local,
    input  wire [`NUM_PORTS-1:0] grant_north,
    input  wire [`NUM_PORTS-1:0] grant_south,
    input  wire [`NUM_PORTS-1:0] grant_east,
    input  wire [`NUM_PORTS-1:0] grant_west,

    // Output Port Data
    output reg  [DATA_WIDTH-1:0] dout_local,
    output reg  [DATA_WIDTH-1:0] dout_north,
    output reg  [DATA_WIDTH-1:0] dout_south,
    output reg  [DATA_WIDTH-1:0] dout_east,
    output reg  [DATA_WIDTH-1:0] dout_west,

    // Valid flags
    output wire                  dout_local_valid,
    output wire                  dout_north_valid,
    output wire                  dout_south_valid,
    output wire                  dout_east_valid,
    output wire                  dout_west_valid
);

    assign dout_local_valid = |grant_local;
    assign dout_north_valid = |grant_north;
    assign dout_south_valid = |grant_south;
    assign dout_east_valid  = |grant_east;
    assign dout_west_valid  = |grant_west;

    // Output MUX: Local
    always @(*) begin
        case (grant_local)
            5'b00001: dout_local = din_local;
            5'b00010: dout_local = din_north;
            5'b00100: dout_local = din_south;
            5'b01000: dout_local = din_east;
            5'b10000: dout_local = din_west;
            default:  dout_local = {DATA_WIDTH{1'b0}};
        endcase
    end

    // Output MUX: North
    always @(*) begin
        case (grant_north)
            5'b00001: dout_north = din_local;
            5'b00010: dout_north = din_north;
            5'b00100: dout_north = din_south;
            5'b01000: dout_north = din_east;
            5'b10000: dout_north = din_west;
            default:  dout_north = {DATA_WIDTH{1'b0}};
        endcase
    end

    // Output MUX: South
    always @(*) begin
        case (grant_south)
            5'b00001: dout_south = din_local;
            5'b00010: dout_south = din_north;
            5'b00100: dout_south = din_south;
            5'b01000: dout_south = din_east;
            5'b10000: dout_south = din_west;
            default:  dout_south = {DATA_WIDTH{1'b0}};
        endcase
    end

    // Output MUX: East
    always @(*) begin
        case (grant_east)
            5'b00001: dout_east = din_local;
            5'b00010: dout_east = din_north;
            5'b00100: dout_east = din_south;
            5'b01000: dout_east = din_east;
            5'b10000: dout_east = din_west;
            default:  dout_east = {DATA_WIDTH{1'b0}};
        endcase
    end

    // Output MUX: West
    always @(*) begin
        case (grant_west)
            5'b00001: dout_west = din_local;
            5'b00010: dout_west = din_north;
            5'b00100: dout_west = din_south;
            5'b01000: dout_west = din_east;
            5'b10000: dout_west = din_west;
            default:  dout_west = {DATA_WIDTH{1'b0}};
        endcase
    end

endmodule
