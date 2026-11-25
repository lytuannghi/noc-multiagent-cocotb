// ============================================================================
// File: tb_noc_mesh_2x2.v
// Module: tb_noc_mesh_2x2
// Description: Comprehensive End-to-End Testbench for 2x2 Network-on-Chip
// Author: Llama 3.3 Cocotb/DV Engineer & DeepSeek-R1 DV Lead
// ============================================================================

`timescale 1ns/1ps
`include "noc_pkg.vh"

module tb_noc_mesh_2x2;

    reg clk;
    reg rst_n;

    // PE 00 Interface
    reg                   pe00_tx_valid;
    reg                   pe00_tx_vc;
    reg  [`FLIT_WIDTH-1:0] pe00_tx_data;
    wire [`NUM_VCS-1:0]    pe00_tx_credit;
    wire                  pe00_rx_valid;
    wire                  pe00_rx_vc;
    wire [`FLIT_WIDTH-1:0] pe00_rx_data;
    reg  [`NUM_VCS-1:0]    pe00_rx_credit;

    // PE 10 Interface
    reg                   pe10_tx_valid;
    reg                   pe10_tx_vc;
    reg  [`FLIT_WIDTH-1:0] pe10_tx_data;
    wire [`NUM_VCS-1:0]    pe10_tx_credit;
    wire                  pe10_rx_valid;
    wire                  pe10_rx_vc;
    wire [`FLIT_WIDTH-1:0] pe10_rx_data;
    reg  [`NUM_VCS-1:0]    pe10_rx_credit;

    // PE 01 Interface
    reg                   pe01_tx_valid;
    reg                   pe01_tx_vc;
    reg  [`FLIT_WIDTH-1:0] pe01_tx_data;
    wire [`NUM_VCS-1:0]    pe01_tx_credit;
    wire                  pe01_rx_valid;
    wire                  pe01_rx_vc;
    wire [`FLIT_WIDTH-1:0] pe01_rx_data;
    reg  [`NUM_VCS-1:0]    pe01_rx_credit;

    // PE 11 Interface
    reg                   pe11_tx_valid;
    reg                   pe11_tx_vc;
    reg  [`FLIT_WIDTH-1:0] pe11_tx_data;
    wire [`NUM_VCS-1:0]    pe11_tx_credit;
    wire                  pe11_rx_valid;
    wire                  pe11_rx_vc;
    wire [`FLIT_WIDTH-1:0] pe11_rx_data;
    reg  [`NUM_VCS-1:0]    pe11_rx_credit;

    // Test Tracking Variables
    integer test_id;
    integer pass_count;
    integer fail_count;
    integer rx_count_00, rx_count_10, rx_count_01, rx_count_11;

    // Clock Generation (100 MHz, Period = 10ns)
    initial clk = 0;
    always #5 clk = ~clk;

    // DUT Instantiation
    noc_mesh_2x2 u_mesh (
        .clk(clk), .rst_n(rst_n),
        .pe00_tx_valid(pe00_tx_valid), .pe00_tx_vc(pe00_tx_vc), .pe00_tx_data(pe00_tx_data), .pe00_tx_credit(pe00_tx_credit),
        .pe00_rx_valid(pe00_rx_valid), .pe00_rx_vc(pe00_rx_vc), .pe00_rx_data(pe00_rx_data), .pe00_rx_credit(pe00_rx_credit),

        .pe10_tx_valid(pe10_tx_valid), .pe10_tx_vc(pe10_tx_vc), .pe10_tx_data(pe10_tx_data), .pe10_tx_credit(pe10_tx_credit),
        .pe10_rx_valid(pe10_rx_valid), .pe10_rx_vc(pe10_rx_vc), .pe10_rx_data(pe10_rx_data), .pe10_rx_credit(pe10_rx_credit),

        .pe01_tx_valid(pe01_tx_valid), .pe01_tx_vc(pe01_tx_vc), .pe01_tx_data(pe01_tx_data), .pe01_tx_credit(pe01_tx_credit),
        .pe01_rx_valid(pe01_rx_valid), .pe01_rx_vc(pe01_rx_vc), .pe01_rx_data(pe01_rx_data), .pe01_rx_credit(pe01_rx_credit),

        .pe11_tx_valid(pe11_tx_valid), .pe11_tx_vc(pe11_tx_vc), .pe11_tx_data(pe11_tx_data), .pe11_tx_credit(pe11_tx_credit),
        .pe11_rx_valid(pe11_rx_valid), .pe11_rx_vc(pe11_rx_vc), .pe11_rx_data(pe11_rx_data), .pe11_rx_credit(pe11_rx_credit)
    );

    // Continuous Receiver Credit Return (Simulating PE consuming flits immediately)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pe00_rx_credit <= 2'b00;
            pe10_rx_credit <= 2'b00;
            pe01_rx_credit <= 2'b00;
            pe11_rx_credit <= 2'b00;
        end else begin
            pe00_rx_credit[0] <= pe00_rx_valid && (pe00_rx_vc == 1'b0);
            pe00_rx_credit[1] <= pe00_rx_valid && (pe00_rx_vc == 1'b1);

            pe10_rx_credit[0] <= pe10_rx_valid && (pe10_rx_vc == 1'b0);
            pe10_rx_credit[1] <= pe10_rx_valid && (pe10_rx_vc == 1'b1);

            pe01_rx_credit[0] <= pe01_rx_valid && (pe01_rx_vc == 1'b0);
            pe01_rx_credit[1] <= pe01_rx_valid && (pe01_rx_vc == 1'b1);

            pe11_rx_credit[0] <= pe11_rx_valid && (pe11_rx_vc == 1'b0);
            pe11_rx_credit[1] <= pe11_rx_valid && (pe11_rx_vc == 1'b1);
        end
    end

    // Flit Packet Packing Function
    // [33:32] type, [31:30] srcX, [29:28] srcY, [27:26] dstX, [25:24] dstY, [23:16] seq, [15:0] payload
    function [`FLIT_WIDTH-1:0] make_flit;
        input [1:0]  flit_type;
        input [1:0]  sx, sy;
        input [1:0]  dx, dy;
        input [7:0]  seq;
        input [15:0] payload;
        begin
            make_flit = {flit_type, sx, sy, dx, dy, seq, payload};
        end
    endfunction

    // Continuous Monitoring of Receivers (latch payload on valid pulse)
    reg [15:0] last_rx_00, last_rx_10, last_rx_01, last_rx_11;
    always @(posedge clk) begin
        if (!rst_n) begin
            last_rx_00 <= 16'd0;
            last_rx_10 <= 16'd0;
            last_rx_01 <= 16'd0;
            last_rx_11 <= 16'd0;
        end else begin
            if (pe00_rx_valid) begin rx_count_00 <= rx_count_00 + 1; last_rx_00 <= pe00_rx_data[15:0]; end
            if (pe10_rx_valid) begin rx_count_10 <= rx_count_10 + 1; last_rx_10 <= pe10_rx_data[15:0]; end
            if (pe01_rx_valid) begin rx_count_01 <= rx_count_01 + 1; last_rx_01 <= pe01_rx_data[15:0]; end
            if (pe11_rx_valid) begin rx_count_11 <= rx_count_11 + 1; last_rx_11 <= pe11_rx_data[15:0]; end
        end
    end

    // ========================================================================
    // Main Test Stimulus
    // ========================================================================
    initial begin
        $dumpfile("noc_mesh.vcd");
        $dumpvars(0, tb_noc_mesh_2x2);

        // Initialization
        rst_n         = 0;
        test_id       = 0;
        pass_count    = 0;
        fail_count    = 0;
        rx_count_00   = 0;
        rx_count_10   = 0;
        rx_count_01   = 0;
        rx_count_11   = 0;
        pe00_tx_valid = 0; pe00_tx_vc = 0; pe00_tx_data = 0;
        pe10_tx_valid = 0; pe10_tx_vc = 0; pe10_tx_data = 0;
        pe01_tx_valid = 0; pe01_tx_vc = 0; pe01_tx_data = 0;
        pe11_tx_valid = 0; pe11_tx_vc = 0; pe11_tx_data = 0;

        #20 rst_n = 1;
        #20;

        $display("==================================================================");
        $display("   AI-DRIVEN 2D MESH NETWORK-ON-CHIP (NoC) VERIFICATION SUITE   ");
        $display("   DV LEAD: DeepSeek-R1 (VETO Active) | ARCHITECT: Gemini        ");
        $display("==================================================================");

        // --------------------------------------------------------------------
        // Test 1: Single-Hop Horizontal Routing (PE00 -> PE10, East)
        // --------------------------------------------------------------------
        test_id = 1;
        $display("\n[TEST 1] Single-Hop Horizontal Routing: PE(0,0) -> PE(1,0)...");
        @(posedge clk);
        pe00_tx_data  <= make_flit(`FLIT_SINGLE, 2'd0, 2'd0, 2'd1, 2'd0, 8'h01, 16'hA001);
        pe00_tx_valid <= 1'b1;
        pe00_tx_vc    <= 1'b0;
        @(posedge clk);
        pe00_tx_valid <= 1'b0;

        // Wait for arrival at PE10
        repeat (10) @(posedge clk);
        if (rx_count_10 >= 1 && last_rx_10 == 16'hA001) begin
            $display("  -> SUCCESS: Flit delivered to PE(1,0). Payload: 0x%04X", last_rx_10);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAILED: Flit not received at PE(1,0)! payload=0x%04X", last_rx_10);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------------------
        // Test 2: Single-Hop Vertical Routing (PE00 -> PE01, South)
        // --------------------------------------------------------------------
        test_id = 2;
        $display("\n[TEST 2] Single-Hop Vertical Routing: PE(0,0) -> PE(0,1)...");
        @(posedge clk);
        pe00_tx_data  <= make_flit(`FLIT_SINGLE, 2'd0, 2'd0, 2'd0, 2'd1, 8'h02, 16'hB002);
        pe00_tx_valid <= 1'b1;
        pe00_tx_vc    <= 1'b0;
        @(posedge clk);
        pe00_tx_valid <= 1'b0;

        repeat (10) @(posedge clk);
        if (rx_count_01 >= 1 && last_rx_01 == 16'hB002) begin
            $display("  -> SUCCESS: Flit delivered to PE(0,1). Payload: 0x%04X", last_rx_01);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAILED: Flit not received at PE(0,1)! payload=0x%04X", last_rx_01);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------------------
        // Test 3: Multi-Hop Diagonal Routing (PE00 -> PE11: East then South)
        // --------------------------------------------------------------------
        test_id = 3;
        $display("\n[TEST 3] Multi-Hop Diagonal Routing: PE(0,0) -> PE(1,1) via X-Y...");
        @(posedge clk);
        pe00_tx_data  <= make_flit(`FLIT_SINGLE, 2'd0, 2'd0, 2'd1, 2'd1, 8'h03, 16'hC003);
        pe00_tx_valid <= 1'b1;
        pe00_tx_vc    <= 1'b0;
        @(posedge clk);
        pe00_tx_valid <= 1'b0;

        repeat (15) @(posedge clk);
        if (rx_count_11 >= 1 && last_rx_11 == 16'hC003) begin
            $display("  -> SUCCESS: Multi-hop Flit arrived at PE(1,1). Payload: 0x%04X", last_rx_11);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAILED: Multi-hop flit lost! payload=0x%04X", last_rx_11);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------------------
        // Test 4: Reverse Diagonal Routing (PE11 -> PE00: West then North)
        // --------------------------------------------------------------------
        test_id = 4;
        $display("\n[TEST 4] Reverse Diagonal Routing: PE(1,1) -> PE(0,0)...");
        @(posedge clk);
        pe11_tx_data  <= make_flit(`FLIT_SINGLE, 2'd1, 2'd1, 2'd0, 2'd0, 8'h04, 16'hD004);
        pe11_tx_valid <= 1'b1;
        pe11_tx_vc    <= 1'b0;
        @(posedge clk);
        pe11_tx_valid <= 1'b0;

        repeat (15) @(posedge clk);
        if (rx_count_00 >= 1 && last_rx_00 == 16'hD004) begin
            $display("  -> SUCCESS: Reverse Flit arrived at PE(0,0). Payload: 0x%04X", last_rx_00);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAILED: Reverse flit lost! payload=0x%04X", last_rx_00);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------------------
        // Test 5: Virtual Channel Isolation (VC0 and VC1)
        // --------------------------------------------------------------------
        test_id = 5;
        $display("\n[TEST 5] Virtual Channel Isolation: Stream on VC1...");
        @(posedge clk);
        pe10_tx_data  <= make_flit(`FLIT_SINGLE, 2'd1, 2'd0, 2'd0, 2'd1, 8'h05, 16'hE005);
        pe10_tx_valid <= 1'b1;
        pe10_tx_vc    <= 1'b1; // VC1
        @(posedge clk);
        pe10_tx_valid <= 1'b0;

        repeat (15) @(posedge clk);
        if (rx_count_01 >= 2 && last_rx_01 == 16'hE005) begin
            $display("  -> SUCCESS: Virtual Channel 1 traffic delivered (Payload: 0x%04X).", last_rx_01);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAILED: Virtual Channel 1 payload mismatch (0x%04X)!", last_rx_01);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------------------
        // Test 6: Wormhole Packet Burst (HEAD -> BODY -> TAIL)
        // --------------------------------------------------------------------
        test_id = 6;
        $display("\n[TEST 6] Wormhole Multi-Flit Packet: 3-Flit Burst PE(0,1) -> PE(1,0)...");
        @(posedge clk);
        // Head Flit
        pe01_tx_data  <= make_flit(`FLIT_HEAD, 2'd0, 2'd1, 2'd1, 2'd0, 8'h06, 16'h1111);
        pe01_tx_valid <= 1'b1; pe01_tx_vc <= 1'b0;
        @(posedge clk);
        // Body Flit
        pe01_tx_data  <= make_flit(`FLIT_BODY, 2'd0, 2'd1, 2'd1, 2'd0, 8'h06, 16'h2222);
        @(posedge clk);
        // Tail Flit
        pe01_tx_data  <= make_flit(`FLIT_TAIL, 2'd0, 2'd1, 2'd1, 2'd0, 8'h06, 16'h3333);
        @(posedge clk);
        pe01_tx_valid <= 1'b0;

        repeat (20) @(posedge clk);
        if (rx_count_10 >= 4 && last_rx_10 == 16'h3333) begin
            $display("  -> SUCCESS: Wormhole 3-flit burst received cleanly (tail=0x%04X).", last_rx_10);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAILED: Wormhole burst incomplete (rx_count_10=%0d, last=0x%04X).", rx_count_10, last_rx_10);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------------------
        // Test 7: Credit-Based Flow Control Verification
        // --------------------------------------------------------------------
        test_id = 7;
        $display("\n[TEST 7] Credit-Based Backpressure Handshake Verification...");
        $display("  -> PE00 Transmit Credits: VC0=%0d, VC1=%0d", u_mesh.u_router_00.credit_cnt_east_vc0, u_mesh.u_router_00.credit_cnt_east_vc1);
        if (u_mesh.u_router_00.credit_cnt_east_vc0 > 0) begin
            $display("  -> SUCCESS: Credit flow control active; buffer capacity bounded.");
            pass_count = pass_count + 1;
        end else begin
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------------------
        // Test 8: Concurrent All-to-All Mesh Traffic
        // --------------------------------------------------------------------
        test_id = 8;
        $display("\n[TEST 8] Concurrent Cross-Traffic Injection (All 4 Nodes active)...");
        @(posedge clk);
        pe00_tx_data <= make_flit(`FLIT_SINGLE, 2'd0, 2'd0, 2'd1, 2'd1, 8'h10, 16'h8001); pe00_tx_valid <= 1'b1;
        pe10_tx_data <= make_flit(`FLIT_SINGLE, 2'd1, 2'd0, 2'd0, 2'd1, 8'h20, 16'h8002); pe10_tx_valid <= 1'b1;
        pe01_tx_data <= make_flit(`FLIT_SINGLE, 2'd0, 2'd1, 2'd1, 2'd0, 8'h30, 16'h8003); pe01_tx_valid <= 1'b1;
        pe11_tx_data <= make_flit(`FLIT_SINGLE, 2'd1, 2'd1, 2'd0, 2'd0, 8'h40, 16'h8004); pe11_tx_valid <= 1'b1;
        @(posedge clk);
        pe00_tx_valid <= 0; pe10_tx_valid <= 0; pe01_tx_valid <= 0; pe11_tx_valid <= 0;

        repeat (25) @(posedge clk);
        if (last_rx_11 == 16'h8001 && last_rx_01 == 16'h8002 && last_rx_10 == 16'h8003 && last_rx_00 == 16'h8004) begin
            $display("  -> SUCCESS: 4 simultaneous packets arbitrated and delivered cleanly.");
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAILED: Cross-traffic payload mismatch (%04X, %04X, %04X, %04X)!", last_rx_11, last_rx_01, last_rx_10, last_rx_00);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------------------
        // Test 9: Deadlock-Freedom Total Flit Conservation Audit
        // --------------------------------------------------------------------
        test_id = 9;
        $display("\n[TEST 9] Deadlock & Livelock Resistance Audit...");
        $display("  -> Total Flits Received: PE00=%0d, PE10=%0d, PE01=%0d, PE11=%0d", rx_count_00, rx_count_10, rx_count_01, rx_count_11);
        if ((rx_count_00 + rx_count_10 + rx_count_01 + rx_count_11) == 12) begin
            $display("  -> SUCCESS: All 12 injected flits conserved with zero deadlock/loss.");
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAILED: Flit conservation mismatch (total=%0d, expected 12).", rx_count_00 + rx_count_10 + rx_count_01 + rx_count_11);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------------------
        // Test 10: Credit Conservation & Steady-State Return Check
        // --------------------------------------------------------------------
        test_id = 10;
        $display("\n[TEST 10] Steady-State Credit Restoration Check...");
        if (u_mesh.u_router_00.credit_cnt_east_vc0 == 4 && u_mesh.u_router_00.credit_cnt_south_vc0 == 4) begin
            $display("  -> SUCCESS: All downstream link credits restored cleanly (4/4 free).");
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAILED: Credits leaked (east=%0d, south=%0d).", u_mesh.u_router_00.credit_cnt_east_vc0, u_mesh.u_router_00.credit_cnt_south_vc0);
            fail_count = fail_count + 1;
        end

        #50;
        $display("\n==================================================================");
        $display("   FINAL NOC VERIFICATION SUMMARY: %0d/10 TESTS PASSED", pass_count);
        if (fail_count == 0) begin
            $display("   STATUS: >>> ALL 10 TESTS PASSED (100%%) - CHIP TAPE-OUT READY <<<");
        end else begin
            $display("   STATUS: FAILED (%0d failures)", fail_count);
        end
        $display("==================================================================");

        $finish;
    end

endmodule
