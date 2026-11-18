// ============================================================================
// File: noc_router.v
// Module: noc_router
// Description: Complete 5-Port 2D Mesh NoC Router with Virtual Channels,
//              Deadlock-Free X-Y Routing, Matrix Arbiter & Credit Flow Control
// Author: Gemini Architect & Qwen 2.5 Coder (Verified by DeepSeek-R1 DV Lead)
// ============================================================================

`include "noc_pkg.vh"

module noc_router #(
    parameter NODE_X = 2'd0,
    parameter NODE_Y = 2'd0
)(
    input  wire                   clk,
    input  wire                   rst_n,

    // ------------------------------------------------------------------------
    // 5 Input Ports (Data In & Credit Out)
    // ------------------------------------------------------------------------
    // Local Port (PE)
    input  wire                   local_in_valid,
    input  wire                   local_in_vc,
    input  wire [`FLIT_WIDTH-1:0] local_in_data,
    output wire [`NUM_VCS-1:0]    local_credit_out,

    // North Port
    input  wire                   north_in_valid,
    input  wire                   north_in_vc,
    input  wire [`FLIT_WIDTH-1:0] north_in_data,
    output wire [`NUM_VCS-1:0]    north_credit_out,

    // South Port
    input  wire                   south_in_valid,
    input  wire                   south_in_vc,
    input  wire [`FLIT_WIDTH-1:0] south_in_data,
    output wire [`NUM_VCS-1:0]    south_credit_out,

    // East Port
    input  wire                   east_in_valid,
    input  wire                   east_in_vc,
    input  wire [`FLIT_WIDTH-1:0] east_in_data,
    output wire [`NUM_VCS-1:0]    east_credit_out,

    // West Port
    input  wire                   west_in_valid,
    input  wire                   west_in_vc,
    input  wire [`FLIT_WIDTH-1:0] west_in_data,
    output wire [`NUM_VCS-1:0]    west_credit_out,

    // ------------------------------------------------------------------------
    // 5 Output Ports (Data Out & Credit In)
    // ------------------------------------------------------------------------
    // Local Port (PE)
    output wire                   local_out_valid,
    output wire                   local_out_vc,
    output wire [`FLIT_WIDTH-1:0] local_out_data,
    input  wire [`NUM_VCS-1:0]    local_credit_in,

    // North Port
    output wire                   north_out_valid,
    output wire                   north_out_vc,
    output wire [`FLIT_WIDTH-1:0] north_out_data,
    input  wire [`NUM_VCS-1:0]    north_credit_in,

    // South Port
    output wire                   south_out_valid,
    output wire                   south_out_vc,
    output wire [`FLIT_WIDTH-1:0] south_out_data,
    input  wire [`NUM_VCS-1:0]    south_credit_in,

    // East Port
    output wire                   east_out_valid,
    output wire                   east_out_vc,
    output wire [`FLIT_WIDTH-1:0] east_out_data,
    input  wire [`NUM_VCS-1:0]    east_credit_in,

    // West Port
    output wire                   west_out_valid,
    output wire                   west_out_vc,
    output wire [`FLIT_WIDTH-1:0] west_out_data,
    input  wire [`NUM_VCS-1:0]    west_credit_in
);

    // ========================================================================
    // 1. Virtual Channel Buffer Instances & Read Signals
    // ========================================================================
    wire [`NUM_VCS-1:0] local_vc_empty,  local_vc_full;
    wire [`NUM_VCS-1:0] north_vc_empty,  north_vc_full;
    wire [`NUM_VCS-1:0] south_vc_empty,  south_vc_full;
    wire [`NUM_VCS-1:0] east_vc_empty,   east_vc_full;
    wire [`NUM_VCS-1:0] west_vc_empty,   west_vc_full;

    wire [`FLIT_WIDTH-1:0] local_rd_vc0, local_rd_vc1;
    wire [`FLIT_WIDTH-1:0] north_rd_vc0, north_rd_vc1;
    wire [`FLIT_WIDTH-1:0] south_rd_vc0, south_rd_vc1;
    wire [`FLIT_WIDTH-1:0] east_rd_vc0,  east_rd_vc1;
    wire [`FLIT_WIDTH-1:0] west_rd_vc0,  west_rd_vc1;

    reg  [`NUM_VCS-1:0] local_rd_en, north_rd_en, south_rd_en, east_rd_en, west_rd_en;

    // Buffer Instances
    noc_vc_buffer u_buf_local (
        .clk(clk), .rst_n(rst_n),
        .wr_en(local_in_valid), .wr_vc(local_in_vc), .wr_data(local_in_data),
        .vc_full(local_vc_full), .rd_en(local_rd_en),
        .rd_data_vc0(local_rd_vc0), .rd_data_vc1(local_rd_vc1),
        .vc_empty(local_vc_empty), .credit_out(local_credit_out)
    );

    noc_vc_buffer u_buf_north (
        .clk(clk), .rst_n(rst_n),
        .wr_en(north_in_valid), .wr_vc(north_in_vc), .wr_data(north_in_data),
        .vc_full(north_vc_full), .rd_en(north_rd_en),
        .rd_data_vc0(north_rd_vc0), .rd_data_vc1(north_rd_vc1),
        .vc_empty(north_vc_empty), .credit_out(north_credit_out)
    );

    noc_vc_buffer u_buf_south (
        .clk(clk), .rst_n(rst_n),
        .wr_en(south_in_valid), .wr_vc(south_in_vc), .wr_data(south_in_data),
        .vc_full(south_vc_full), .rd_en(south_rd_en),
        .rd_data_vc0(south_rd_vc0), .rd_data_vc1(south_rd_vc1),
        .vc_empty(south_vc_empty), .credit_out(south_credit_out)
    );

    noc_vc_buffer u_buf_east (
        .clk(clk), .rst_n(rst_n),
        .wr_en(east_in_valid), .wr_vc(east_in_vc), .wr_data(east_in_data),
        .vc_full(east_vc_full), .rd_en(east_rd_en),
        .rd_data_vc0(east_rd_vc0), .rd_data_vc1(east_rd_vc1),
        .vc_empty(east_vc_empty), .credit_out(east_credit_out)
    );

    noc_vc_buffer u_buf_west (
        .clk(clk), .rst_n(rst_n),
        .wr_en(west_in_valid), .wr_vc(west_in_vc), .wr_data(west_in_data),
        .vc_full(west_vc_full), .rd_en(west_rd_en),
        .rd_data_vc0(west_rd_vc0), .rd_data_vc1(west_rd_vc1),
        .vc_empty(west_vc_empty), .credit_out(west_credit_out)
    );

    // ========================================================================
    // 2. Active Flit Selection at Input Ports (VC0 priority over VC1)
    // ========================================================================
    wire [`FLIT_WIDTH-1:0] local_flit_cand = !local_vc_empty[0] ? local_rd_vc0 : local_rd_vc1;
    wire [`FLIT_WIDTH-1:0] north_flit_cand = !north_vc_empty[0] ? north_rd_vc0 : north_rd_vc1;
    wire [`FLIT_WIDTH-1:0] south_flit_cand = !south_vc_empty[0] ? south_rd_vc0 : south_rd_vc1;
    wire [`FLIT_WIDTH-1:0] east_flit_cand  = !east_vc_empty[0]  ? east_rd_vc0  : east_rd_vc1;
    wire [`FLIT_WIDTH-1:0] west_flit_cand  = !west_vc_empty[0]  ? west_rd_vc0  : west_rd_vc1;

    wire local_has_flit = !(&local_vc_empty);
    wire north_has_flit = !(&north_vc_empty);
    wire south_has_flit = !(&south_vc_empty);
    wire east_has_flit  = !(&east_vc_empty);
    wire west_has_flit  = !(&west_vc_empty);

    wire local_active_vc = local_vc_empty[0];
    wire north_active_vc = north_vc_empty[0];
    wire south_active_vc = south_vc_empty[0];
    wire east_active_vc  = east_vc_empty[0];
    wire west_active_vc  = west_vc_empty[0];

    // ========================================================================
    // 3. X-Y Routing Units (One per Input Port)
    // ========================================================================
    wire [2:0] local_target, north_target, south_target, east_target, west_target;

    noc_xy_router #(.CUR_X(NODE_X), .CUR_Y(NODE_Y)) u_route_local (
        .dst_x(local_flit_cand[27:26]), .dst_y(local_flit_cand[25:24]),
        .target_port(local_target)
    );
    noc_xy_router #(.CUR_X(NODE_X), .CUR_Y(NODE_Y)) u_route_north (
        .dst_x(north_flit_cand[27:26]), .dst_y(north_flit_cand[25:24]),
        .target_port(north_target)
    );
    noc_xy_router #(.CUR_X(NODE_X), .CUR_Y(NODE_Y)) u_route_south (
        .dst_x(south_flit_cand[27:26]), .dst_y(south_flit_cand[25:24]),
        .target_port(south_target)
    );
    noc_xy_router #(.CUR_X(NODE_X), .CUR_Y(NODE_Y)) u_route_east (
        .dst_x(east_flit_cand[27:26]),  .dst_y(east_flit_cand[25:24]),
        .target_port(east_target)
    );
    noc_xy_router #(.CUR_X(NODE_X), .CUR_Y(NODE_Y)) u_route_west (
        .dst_x(west_flit_cand[27:26]),  .dst_y(west_flit_cand[25:24]),
        .target_port(west_target)
    );

    // ========================================================================
    // 4. Downstream Credit Counters (Tracks buffer availability in neighbor)
    // ========================================================================
    reg [2:0] credit_cnt_local_vc0, credit_cnt_local_vc1;
    reg [2:0] credit_cnt_north_vc0, credit_cnt_north_vc1;
    reg [2:0] credit_cnt_south_vc0, credit_cnt_south_vc1;
    reg [2:0] credit_cnt_east_vc0,  credit_cnt_east_vc1;
    reg [2:0] credit_cnt_west_vc0,  credit_cnt_west_vc1;

    wire local_tx_fire, north_tx_fire, south_tx_fire, east_tx_fire, west_tx_fire;

    // Local Credits Tracking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            credit_cnt_local_vc0 <= `VC_DEPTH;
            credit_cnt_local_vc1 <= `VC_DEPTH;
        end else begin
            if (local_credit_in[0] && !(local_tx_fire && local_out_vc == 1'b0))
                credit_cnt_local_vc0 <= credit_cnt_local_vc0 + 1'b1;
            else if (!local_credit_in[0] && (local_tx_fire && local_out_vc == 1'b0))
                credit_cnt_local_vc0 <= credit_cnt_local_vc0 - 1'b1;

            if (local_credit_in[1] && !(local_tx_fire && local_out_vc == 1'b1))
                credit_cnt_local_vc1 <= credit_cnt_local_vc1 + 1'b1;
            else if (!local_credit_in[1] && (local_tx_fire && local_out_vc == 1'b1))
                credit_cnt_local_vc1 <= credit_cnt_local_vc1 - 1'b1;
        end
    end

    // North Credits Tracking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            credit_cnt_north_vc0 <= `VC_DEPTH;
            credit_cnt_north_vc1 <= `VC_DEPTH;
        end else begin
            if (north_credit_in[0] && !(north_tx_fire && north_out_vc == 1'b0))
                credit_cnt_north_vc0 <= credit_cnt_north_vc0 + 1'b1;
            else if (!north_credit_in[0] && (north_tx_fire && north_out_vc == 1'b0))
                credit_cnt_north_vc0 <= credit_cnt_north_vc0 - 1'b1;

            if (north_credit_in[1] && !(north_tx_fire && north_out_vc == 1'b1))
                credit_cnt_north_vc1 <= credit_cnt_north_vc1 + 1'b1;
            else if (!north_credit_in[1] && (north_tx_fire && north_out_vc == 1'b1))
                credit_cnt_north_vc1 <= credit_cnt_north_vc1 - 1'b1;
        end
    end

    // South Credits Tracking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            credit_cnt_south_vc0 <= `VC_DEPTH;
            credit_cnt_south_vc1 <= `VC_DEPTH;
        end else begin
            if (south_credit_in[0] && !(south_tx_fire && south_out_vc == 1'b0))
                credit_cnt_south_vc0 <= credit_cnt_south_vc0 + 1'b1;
            else if (!south_credit_in[0] && (south_tx_fire && south_out_vc == 1'b0))
                credit_cnt_south_vc0 <= credit_cnt_south_vc0 - 1'b1;

            if (south_credit_in[1] && !(south_tx_fire && south_out_vc == 1'b1))
                credit_cnt_south_vc1 <= credit_cnt_south_vc1 + 1'b1;
            else if (!south_credit_in[1] && (south_tx_fire && south_out_vc == 1'b1))
                credit_cnt_south_vc1 <= credit_cnt_south_vc1 - 1'b1;
        end
    end

    // East Credits Tracking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            credit_cnt_east_vc0 <= `VC_DEPTH;
            credit_cnt_east_vc1 <= `VC_DEPTH;
        end else begin
            if (east_credit_in[0] && !(east_tx_fire && east_out_vc == 1'b0))
                credit_cnt_east_vc0 <= credit_cnt_east_vc0 + 1'b1;
            else if (!east_credit_in[0] && (east_tx_fire && east_out_vc == 1'b0))
                credit_cnt_east_vc0 <= credit_cnt_east_vc0 - 1'b1;

            if (east_credit_in[1] && !(east_tx_fire && east_out_vc == 1'b1))
                credit_cnt_east_vc1 <= credit_cnt_east_vc1 + 1'b1;
            else if (!east_credit_in[1] && (east_tx_fire && east_out_vc == 1'b1))
                credit_cnt_east_vc1 <= credit_cnt_east_vc1 - 1'b1;
        end
    end

    // West Credits Tracking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            credit_cnt_west_vc0 <= `VC_DEPTH;
            credit_cnt_west_vc1 <= `VC_DEPTH;
        end else begin
            if (west_credit_in[0] && !(west_tx_fire && west_out_vc == 1'b0))
                credit_cnt_west_vc0 <= credit_cnt_west_vc0 + 1'b1;
            else if (!west_credit_in[0] && (west_tx_fire && west_out_vc == 1'b0))
                credit_cnt_west_vc0 <= credit_cnt_west_vc0 - 1'b1;

            if (west_credit_in[1] && !(west_tx_fire && west_out_vc == 1'b1))
                credit_cnt_west_vc1 <= credit_cnt_west_vc1 + 1'b1;
            else if (!west_credit_in[1] && (west_tx_fire && west_out_vc == 1'b1))
                credit_cnt_west_vc1 <= credit_cnt_west_vc1 - 1'b1;
        end
    end

    // Output Credit Availability Flags (Credit > 0)
    wire local_has_credit = (credit_cnt_local_vc0 > 0) || (credit_cnt_local_vc1 > 0);
    wire north_has_credit = (credit_cnt_north_vc0 > 0) || (credit_cnt_north_vc1 > 0);
    wire south_has_credit = (credit_cnt_south_vc0 > 0) || (credit_cnt_south_vc1 > 0);
    wire east_has_credit  = (credit_cnt_east_vc0  > 0) || (credit_cnt_east_vc1  > 0);
    wire west_has_credit  = (credit_cnt_west_vc0  > 0) || (credit_cnt_west_vc1  > 0);

    // ========================================================================
    // 5. Switch Allocation Arbiters (One Arbiter per Output Port)
    // ========================================================================
    // Request vectors: [4]=West, [3]=East, [2]=South, [1]=North, [0]=Local
    wire [`NUM_PORTS-1:0] req_to_local;
    wire [`NUM_PORTS-1:0] req_to_north;
    wire [`NUM_PORTS-1:0] req_to_south;
    wire [`NUM_PORTS-1:0] req_to_east;
    wire [`NUM_PORTS-1:0] req_to_west;

    assign req_to_local[0] = local_has_flit && (local_target == `PORT_LOCAL) && local_has_credit;
    assign req_to_local[1] = north_has_flit && (north_target == `PORT_LOCAL) && local_has_credit;
    assign req_to_local[2] = south_has_flit && (south_target == `PORT_LOCAL) && local_has_credit;
    assign req_to_local[3] = east_has_flit  && (east_target  == `PORT_LOCAL) && local_has_credit;
    assign req_to_local[4] = west_has_flit  && (west_target  == `PORT_LOCAL) && local_has_credit;

    assign req_to_north[0] = local_has_flit && (local_target == `PORT_NORTH) && north_has_credit;
    assign req_to_north[1] = north_has_flit && (north_target == `PORT_NORTH) && north_has_credit;
    assign req_to_north[2] = south_has_flit && (south_target == `PORT_NORTH) && north_has_credit;
    assign req_to_north[3] = east_has_flit  && (east_target  == `PORT_NORTH) && north_has_credit;
    assign req_to_north[4] = west_has_flit  && (west_target  == `PORT_NORTH) && north_has_credit;

    assign req_to_south[0] = local_has_flit && (local_target == `PORT_SOUTH) && south_has_credit;
    assign req_to_south[1] = north_has_flit && (north_target == `PORT_SOUTH) && south_has_credit;
    assign req_to_south[2] = south_has_flit && (south_target == `PORT_SOUTH) && south_has_credit;
    assign req_to_south[3] = east_has_flit  && (east_target  == `PORT_SOUTH) && south_has_credit;
    assign req_to_south[4] = west_has_flit  && (west_target  == `PORT_SOUTH) && south_has_credit;

    assign req_to_east[0]  = local_has_flit && (local_target == `PORT_EAST)  && east_has_credit;
    assign req_to_east[1]  = north_has_flit && (north_target == `PORT_EAST)  && east_has_credit;
    assign req_to_east[2]  = south_has_flit && (south_target == `PORT_EAST)  && east_has_credit;
    assign req_to_east[3]  = east_has_flit  && (east_target  == `PORT_EAST)  && east_has_credit;
    assign req_to_east[4]  = west_has_flit  && (west_target  == `PORT_EAST)  && east_has_credit;

    assign req_to_west[0]  = local_has_flit && (local_target == `PORT_WEST)  && west_has_credit;
    assign req_to_west[1]  = north_has_flit && (north_target == `PORT_WEST)  && west_has_credit;
    assign req_to_west[2]  = south_has_flit && (south_target == `PORT_WEST)  && west_has_credit;
    assign req_to_west[3]  = east_has_flit  && (east_target  == `PORT_WEST)  && west_has_credit;
    assign req_to_west[4]  = west_has_flit  && (west_target  == `PORT_WEST)  && west_has_credit;

    wire [`NUM_PORTS-1:0] grant_local, grant_north, grant_south, grant_east, grant_west;

    noc_matrix_arbiter u_arb_local (.clk(clk), .rst_n(rst_n), .req(req_to_local), .grant(grant_local), .grant_valid());
    noc_matrix_arbiter u_arb_north (.clk(clk), .rst_n(rst_n), .req(req_to_north), .grant(grant_north), .grant_valid());
    noc_matrix_arbiter u_arb_south (.clk(clk), .rst_n(rst_n), .req(req_to_south), .grant(grant_south), .grant_valid());
    noc_matrix_arbiter u_arb_east  (.clk(clk), .rst_n(rst_n), .req(req_to_east),  .grant(grant_east),  .grant_valid());
    noc_matrix_arbiter u_arb_west  (.clk(clk), .rst_n(rst_n), .req(req_to_west),  .grant(grant_west),  .grant_valid());

    // ========================================================================
    // 6. Crossbar Switch Instance
    // ========================================================================
    noc_crossbar u_xbar (
        .din_local(local_flit_cand),
        .din_north(north_flit_cand),
        .din_south(south_flit_cand),
        .din_east(east_flit_cand),
        .din_west(west_flit_cand),

        .grant_local(grant_local),
        .grant_north(grant_north),
        .grant_south(grant_south),
        .grant_east(grant_east),
        .grant_west(grant_west),

        .dout_local(local_out_data),
        .dout_north(north_out_data),
        .dout_south(south_out_data),
        .dout_east(east_out_data),
        .dout_west(west_out_data),

        .dout_local_valid(local_out_valid),
        .dout_north_valid(north_out_valid),
        .dout_south_valid(south_out_valid),
        .dout_east_valid(east_out_valid),
        .dout_west_valid(west_out_valid)
    );

    // ========================================================================
    // 7. Output VC Selection and Buffer Pop Logic
    // ========================================================================
    assign local_tx_fire = local_out_valid;
    assign north_tx_fire = north_out_valid;
    assign south_tx_fire = south_out_valid;
    assign east_tx_fire  = east_out_valid;
    assign west_tx_fire  = west_out_valid;

    // Output VC: prioritize VC0 if it has credits, else VC1
    assign local_out_vc = (credit_cnt_local_vc0 > 0) ? 1'b0 : 1'b1;
    assign north_out_vc = (credit_cnt_north_vc0 > 0) ? 1'b0 : 1'b1;
    assign south_out_vc = (credit_cnt_south_vc0 > 0) ? 1'b0 : 1'b1;
    assign east_out_vc  = (credit_cnt_east_vc0  > 0) ? 1'b0 : 1'b1;
    assign west_out_vc  = (credit_cnt_west_vc0  > 0) ? 1'b0 : 1'b1;

    // Buffer read enables: pop when granted
    always @(*) begin
        local_rd_en = 2'b00;
        north_rd_en = 2'b00;
        south_rd_en = 2'b00;
        east_rd_en  = 2'b00;
        west_rd_en  = 2'b00;

        if (grant_local[0] || grant_north[0] || grant_south[0] || grant_east[0] || grant_west[0]) begin
            local_rd_en[local_active_vc] = 1'b1;
        end
        if (grant_local[1] || grant_north[1] || grant_south[1] || grant_east[1] || grant_west[1]) begin
            north_rd_en[north_active_vc] = 1'b1;
        end
        if (grant_local[2] || grant_north[2] || grant_south[2] || grant_east[2] || grant_west[2]) begin
            south_rd_en[south_active_vc] = 1'b1;
        end
        if (grant_local[3] || grant_north[3] || grant_south[3] || grant_east[3] || grant_west[3]) begin
            east_rd_en[east_active_vc] = 1'b1;
        end
        if (grant_local[4] || grant_north[4] || grant_south[4] || grant_east[4] || grant_west[4]) begin
            west_rd_en[west_active_vc] = 1'b1;
        end
    end

endmodule
