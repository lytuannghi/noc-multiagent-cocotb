`timescale 1ns / 1ps

// ============================================================================
// File: noc_mesh_2x2.v
// Module: noc_mesh_2x2
// Description: 2x2 2D Mesh Network-on-Chip Top-Level Subsystem
//              Interconnects 4 Routers with Full Credit-Based Handshaking
// Author: Gemini Architect & Qwen 2.5 Coder
// ============================================================================

`include "noc_pkg.vh"

module noc_mesh_2x2 (
    input  wire                   clk,
    input  wire                   rst_n,

    // PE 00 (X=0, Y=0) Interface
    input  wire                   pe00_tx_valid,
    input  wire                   pe00_tx_vc,
    input  wire [`FLIT_WIDTH-1:0] pe00_tx_data,
    output wire [`NUM_VCS-1:0]    pe00_tx_credit,
    output wire                   pe00_rx_valid,
    output wire                   pe00_rx_vc,
    output wire [`FLIT_WIDTH-1:0] pe00_rx_data,
    input  wire [`NUM_VCS-1:0]    pe00_rx_credit,

    // PE 10 (X=1, Y=0) Interface
    input  wire                   pe10_tx_valid,
    input  wire                   pe10_tx_vc,
    input  wire [`FLIT_WIDTH-1:0] pe10_tx_data,
    output wire [`NUM_VCS-1:0]    pe10_tx_credit,
    output wire                   pe10_rx_valid,
    output wire                   pe10_rx_vc,
    output wire [`FLIT_WIDTH-1:0] pe10_rx_data,
    input  wire [`NUM_VCS-1:0]    pe10_rx_credit,

    // PE 01 (X=0, Y=1) Interface
    input  wire                   pe01_tx_valid,
    input  wire                   pe01_tx_vc,
    input  wire [`FLIT_WIDTH-1:0] pe01_tx_data,
    output wire [`NUM_VCS-1:0]    pe01_tx_credit,
    output wire                   pe01_rx_valid,
    output wire                   pe01_rx_vc,
    output wire [`FLIT_WIDTH-1:0] pe01_rx_data,
    input  wire [`NUM_VCS-1:0]    pe01_rx_credit,

    // PE 11 (X=1, Y=1) Interface
    input  wire                   pe11_tx_valid,
    input  wire                   pe11_tx_vc,
    input  wire [`FLIT_WIDTH-1:0] pe11_tx_data,
    output wire [`NUM_VCS-1:0]    pe11_tx_credit,
    output wire                   pe11_rx_valid,
    output wire                   pe11_rx_vc,
    output wire [`FLIT_WIDTH-1:0] pe11_rx_data,
    input  wire [`NUM_VCS-1:0]    pe11_rx_credit
);

    // ========================================================================
    // Internal Router Interconnect Channels
    // ========================================================================
    // R00 <-> R10 (Horizontal Link Y=0)
    wire                   r00_to_r10_valid, r00_to_r10_vc;
    wire [`FLIT_WIDTH-1:0] r00_to_r10_data;
    wire [`NUM_VCS-1:0]    r10_to_r00_credit;

    wire                   r10_to_r00_valid, r10_to_r00_vc;
    wire [`FLIT_WIDTH-1:0] r10_to_r00_data;
    wire [`NUM_VCS-1:0]    r00_to_r10_credit;

    // R01 <-> R11 (Horizontal Link Y=1)
    wire                   r01_to_r11_valid, r01_to_r11_vc;
    wire [`FLIT_WIDTH-1:0] r01_to_r11_data;
    wire [`NUM_VCS-1:0]    r11_to_r01_credit;

    wire                   r11_to_r01_valid, r11_to_r01_vc;
    wire [`FLIT_WIDTH-1:0] r11_to_r01_data;
    wire [`NUM_VCS-1:0]    r01_to_r11_credit;

    // R00 <-> R01 (Vertical Link X=0)
    wire                   r00_to_r01_valid, r00_to_r01_vc;
    wire [`FLIT_WIDTH-1:0] r00_to_r01_data;
    wire [`NUM_VCS-1:0]    r01_to_r00_credit;

    wire                   r01_to_r00_valid, r01_to_r00_vc;
    wire [`FLIT_WIDTH-1:0] r01_to_r00_data;
    wire [`NUM_VCS-1:0]    r00_to_r01_credit;

    // R10 <-> R11 (Vertical Link X=1)
    wire                   r10_to_r11_valid, r10_to_r11_vc;
    wire [`FLIT_WIDTH-1:0] r10_to_r11_data;
    wire [`NUM_VCS-1:0]    r11_to_r10_credit;

    wire                   r11_to_r10_valid, r11_to_r10_vc;
    wire [`FLIT_WIDTH-1:0] r11_to_r10_data;
    wire [`NUM_VCS-1:0]    r10_to_r11_credit;

    // ========================================================================
    // Router 0,0 (Top-Left)
    // ========================================================================
    noc_router #(.NODE_X(2'd0), .NODE_Y(2'd0)) u_router_00 (
        .clk(clk), .rst_n(rst_n),
        // Local
        .local_in_valid(pe00_tx_valid), .local_in_vc(pe00_tx_vc), .local_in_data(pe00_tx_data), .local_credit_out(pe00_tx_credit),
        .local_out_valid(pe00_rx_valid), .local_out_vc(pe00_rx_vc), .local_out_data(pe00_rx_data), .local_credit_in(pe00_rx_credit),
        // North (Boundary)
        .north_in_valid(1'b0), .north_in_vc(1'b0), .north_in_data({`FLIT_WIDTH{1'b0}}), .north_credit_out(),
        .north_out_valid(), .north_out_vc(), .north_out_data(), .north_credit_in(2'b00),
        // South -> R01
        .south_in_valid(r01_to_r00_valid), .south_in_vc(r01_to_r00_vc), .south_in_data(r01_to_r00_data), .south_credit_out(r00_to_r01_credit),
        .south_out_valid(r00_to_r01_valid), .south_out_vc(r00_to_r01_vc), .south_out_data(r00_to_r01_data), .south_credit_in(r01_to_r00_credit),
        // East -> R10
        .east_in_valid(r10_to_r00_valid), .east_in_vc(r10_to_r00_vc), .east_in_data(r10_to_r00_data), .east_credit_out(r00_to_r10_credit),
        .east_out_valid(r00_to_r10_valid), .east_out_vc(r00_to_r10_vc), .east_out_data(r00_to_r10_data), .east_credit_in(r10_to_r00_credit),
        // West (Boundary)
        .west_in_valid(1'b0), .west_in_vc(1'b0), .west_in_data({`FLIT_WIDTH{1'b0}}), .west_credit_out(),
        .west_out_valid(), .west_out_vc(), .west_out_data(), .west_credit_in(2'b00)
    );

    // ========================================================================
    // Router 1,0 (Top-Right)
    // ========================================================================
    noc_router #(.NODE_X(2'd1), .NODE_Y(2'd0)) u_router_10 (
        .clk(clk), .rst_n(rst_n),
        // Local
        .local_in_valid(pe10_tx_valid), .local_in_vc(pe10_tx_vc), .local_in_data(pe10_tx_data), .local_credit_out(pe10_tx_credit),
        .local_out_valid(pe10_rx_valid), .local_out_vc(pe10_rx_vc), .local_out_data(pe10_rx_data), .local_credit_in(pe10_rx_credit),
        // North (Boundary)
        .north_in_valid(1'b0), .north_in_vc(1'b0), .north_in_data({`FLIT_WIDTH{1'b0}}), .north_credit_out(),
        .north_out_valid(), .north_out_vc(), .north_out_data(), .north_credit_in(2'b00),
        // South -> R11
        .south_in_valid(r11_to_r10_valid), .south_in_vc(r11_to_r10_vc), .south_in_data(r11_to_r10_data), .south_credit_out(r10_to_r11_credit),
        .south_out_valid(r10_to_r11_valid), .south_out_vc(r10_to_r11_vc), .south_out_data(r10_to_r11_data), .south_credit_in(r11_to_r10_credit),
        // East (Boundary)
        .east_in_valid(1'b0), .east_in_vc(1'b0), .east_in_data({`FLIT_WIDTH{1'b0}}), .east_credit_out(),
        .east_out_valid(), .east_out_vc(), .east_out_data(), .east_credit_in(2'b00),
        // West -> R00
        .west_in_valid(r00_to_r10_valid), .west_in_vc(r00_to_r10_vc), .west_in_data(r00_to_r10_data), .west_credit_out(r10_to_r00_credit),
        .west_out_valid(r10_to_r00_valid), .west_out_vc(r10_to_r00_vc), .west_out_data(r10_to_r00_data), .west_credit_in(r00_to_r10_credit)
    );

    // ========================================================================
    // Router 0,1 (Bottom-Left)
    // ========================================================================
    noc_router #(.NODE_X(2'd0), .NODE_Y(2'd1)) u_router_01 (
        .clk(clk), .rst_n(rst_n),
        // Local
        .local_in_valid(pe01_tx_valid), .local_in_vc(pe01_tx_vc), .local_in_data(pe01_tx_data), .local_credit_out(pe01_tx_credit),
        .local_out_valid(pe01_rx_valid), .local_out_vc(pe01_rx_vc), .local_out_data(pe01_rx_data), .local_credit_in(pe01_rx_credit),
        // North -> R00
        .north_in_valid(r00_to_r01_valid), .north_in_vc(r00_to_r01_vc), .north_in_data(r00_to_r01_data), .north_credit_out(r01_to_r00_credit),
        .north_out_valid(r01_to_r00_valid), .north_out_vc(r01_to_r00_vc), .north_out_data(r01_to_r00_data), .north_credit_in(r00_to_r01_credit),
        // South (Boundary)
        .south_in_valid(1'b0), .south_in_vc(1'b0), .south_in_data({`FLIT_WIDTH{1'b0}}), .south_credit_out(),
        .south_out_valid(), .south_out_vc(), .south_out_data(), .south_credit_in(2'b00),
        // East -> R11
        .east_in_valid(r11_to_r01_valid), .east_in_vc(r11_to_r01_vc), .east_in_data(r11_to_r01_data), .east_credit_out(r01_to_r11_credit),
        .east_out_valid(r01_to_r11_valid), .east_out_vc(r01_to_r11_vc), .east_out_data(r01_to_r11_data), .east_credit_in(r11_to_r01_credit),
        // West (Boundary)
        .west_in_valid(1'b0), .west_in_vc(1'b0), .west_in_data({`FLIT_WIDTH{1'b0}}), .west_credit_out(),
        .west_out_valid(), .west_out_vc(), .west_out_data(), .west_credit_in(2'b00)
    );

    // ========================================================================
    // Router 1,1 (Bottom-Right)
    // ========================================================================
    noc_router #(.NODE_X(2'd1), .NODE_Y(2'd1)) u_router_11 (
        .clk(clk), .rst_n(rst_n),
        // Local
        .local_in_valid(pe11_tx_valid), .local_in_vc(pe11_tx_vc), .local_in_data(pe11_tx_data), .local_credit_out(pe11_tx_credit),
        .local_out_valid(pe11_rx_valid), .local_out_vc(pe11_rx_vc), .local_out_data(pe11_rx_data), .local_credit_in(pe11_rx_credit),
        // North -> R10
        .north_in_valid(r10_to_r11_valid), .north_in_vc(r10_to_r11_vc), .north_in_data(r10_to_r11_data), .north_credit_out(r11_to_r10_credit),
        .north_out_valid(r11_to_r10_valid), .north_out_vc(r11_to_r10_vc), .north_out_data(r11_to_r10_data), .north_credit_in(r10_to_r11_credit),
        // South (Boundary)
        .south_in_valid(1'b0), .south_in_vc(1'b0), .south_in_data({`FLIT_WIDTH{1'b0}}), .south_credit_out(),
        .south_out_valid(), .south_out_vc(), .south_out_data(), .south_credit_in(2'b00),
        // East (Boundary)
        .east_in_valid(1'b0), .east_in_vc(1'b0), .east_in_data({`FLIT_WIDTH{1'b0}}), .east_credit_out(),
        .east_out_valid(), .east_out_vc(), .east_out_data(), .east_credit_in(2'b00),
        // West -> R01
        .west_in_valid(r01_to_r11_valid), .west_in_vc(r01_to_r11_vc), .west_in_data(r01_to_r11_data), .west_credit_out(r11_to_r01_credit),
        .west_out_valid(r11_to_r01_valid), .west_out_vc(r11_to_r01_vc), .west_out_data(r11_to_r01_data), .west_credit_in(r01_to_r11_credit)
    );

endmodule
