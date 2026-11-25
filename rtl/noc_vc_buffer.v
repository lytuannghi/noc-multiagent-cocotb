`timescale 1ns / 1ps

// ============================================================================
// File: noc_vc_buffer.v
// Module: noc_vc_buffer
// Description: Multi-Virtual Channel FIFO Buffer with Credit Flow Control
// Author: Qwen 2.5 Coder (Approved by DeepSeek-R1 DV Lead)
// ============================================================================

`include "noc_pkg.vh"

module noc_vc_buffer #(
    parameter DATA_WIDTH = `FLIT_WIDTH,
    parameter DEPTH      = `VC_DEPTH,
    parameter NUM_VCS    = `NUM_VCS
)(
    input  wire                   clk,
    input  wire                   rst_n,

    // Write Interface (From upstream router or local PE)
    input  wire                   wr_en,
    input  wire                   wr_vc,       // Selected VC (0 or 1)
    input  wire [DATA_WIDTH-1:0]  wr_data,
    output wire [NUM_VCS-1:0]     vc_full,

    // Read Interface (To router crossbar)
    input  wire [NUM_VCS-1:0]     rd_en,
    output wire [DATA_WIDTH-1:0]  rd_data_vc0,
    output wire [DATA_WIDTH-1:0]  rd_data_vc1,
    output wire [NUM_VCS-1:0]     vc_empty,

    // Credit output pulse to upstream router (indicates a flit was read/freed)
    output reg  [NUM_VCS-1:0]     credit_out
);

    // VC 0 Storage
    reg [DATA_WIDTH-1:0] fifo_vc0 [0:DEPTH-1];
    reg [1:0] wr_ptr_vc0, rd_ptr_vc0;
    reg [2:0] count_vc0;

    // VC 1 Storage
    reg [DATA_WIDTH-1:0] fifo_vc1 [0:DEPTH-1];
    reg [1:0] wr_ptr_vc1, rd_ptr_vc1;
    reg [2:0] count_vc1;

    // Status Flags
    assign vc_empty[0] = (count_vc0 == 0);
    assign vc_full[0]  = (count_vc0 == DEPTH);
    assign vc_empty[1] = (count_vc1 == 0);
    assign vc_full[1]  = (count_vc1 == DEPTH);

    // Read data outputs (first flit available without pop delay)
    assign rd_data_vc0 = fifo_vc0[rd_ptr_vc0];
    assign rd_data_vc1 = fifo_vc1[rd_ptr_vc1];

    // FIFO VC0 Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_vc0 <= 2'b00;
            rd_ptr_vc0 <= 2'b00;
            count_vc0  <= 3'b000;
            credit_out[0] <= 1'b0;
        end else begin
            credit_out[0] <= 1'b0;

            // Simultaneous Read and Write
            if ((wr_en && wr_vc == 1'b0 && !vc_full[0]) && (rd_en[0] && !vc_empty[0])) begin
                fifo_vc0[wr_ptr_vc0] <= wr_data;
                wr_ptr_vc0 <= (wr_ptr_vc0 == DEPTH-1) ? 2'b00 : wr_ptr_vc0 + 1'b1;
                rd_ptr_vc0 <= (rd_ptr_vc0 == DEPTH-1) ? 2'b00 : rd_ptr_vc0 + 1'b1;
                credit_out[0] <= 1'b1; // Slot consumed and freed
            end
            // Write Only
            else if (wr_en && wr_vc == 1'b0 && !vc_full[0]) begin
                fifo_vc0[wr_ptr_vc0] <= wr_data;
                wr_ptr_vc0 <= (wr_ptr_vc0 == DEPTH-1) ? 2'b00 : wr_ptr_vc0 + 1'b1;
                count_vc0  <= count_vc0 + 1'b1;
            end
            // Read Only
            else if (rd_en[0] && !vc_empty[0]) begin
                rd_ptr_vc0 <= (rd_ptr_vc0 == DEPTH-1) ? 2'b00 : rd_ptr_vc0 + 1'b1;
                count_vc0  <= count_vc0 - 1'b1;
                credit_out[0] <= 1'b1; // Notify upstream transmitter
            end
        end
    end

    // FIFO VC1 Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_vc1 <= 2'b00;
            rd_ptr_vc1 <= 2'b00;
            count_vc1  <= 3'b000;
            credit_out[1] <= 1'b0;
        end else begin
            credit_out[1] <= 1'b0;

            // Simultaneous Read and Write
            if ((wr_en && wr_vc == 1'b1 && !vc_full[1]) && (rd_en[1] && !vc_empty[1])) begin
                fifo_vc1[wr_ptr_vc1] <= wr_data;
                wr_ptr_vc1 <= (wr_ptr_vc1 == DEPTH-1) ? 2'b00 : wr_ptr_vc1 + 1'b1;
                rd_ptr_vc1 <= (rd_ptr_vc1 == DEPTH-1) ? 2'b00 : rd_ptr_vc1 + 1'b1;
                credit_out[1] <= 1'b1;
            end
            // Write Only
            else if (wr_en && wr_vc == 1'b1 && !vc_full[1]) begin
                fifo_vc1[wr_ptr_vc1] <= wr_data;
                wr_ptr_vc1 <= (wr_ptr_vc1 == DEPTH-1) ? 2'b00 : wr_ptr_vc1 + 1'b1;
                count_vc1  <= count_vc1 + 1'b1;
            end
            // Read Only
            else if (rd_en[1] && !vc_empty[1]) begin
                rd_ptr_vc1 <= (rd_ptr_vc1 == DEPTH-1) ? 2'b00 : rd_ptr_vc1 + 1'b1;
                count_vc1  <= count_vc1 - 1'b1;
                credit_out[1] <= 1'b1;
            end
        end
    end

endmodule
