// ============================================================================
// File: noc_pkg.vh
// Module: Network-on-Chip Parameters & Flit Definitions
// Target: 2D Mesh Wormhole NoC with Virtual Channels & Credit Flow Control
// Author: AI War Room (Gemini Architect + Qwen 2.5 Coder + DeepSeek-R1 DV Lead)
// ============================================================================

`ifndef NOC_PKG_VH
`define NOC_PKG_VH

// Flit Types (2-bit encoding)
`define FLIT_HEAD       2'b00   // Contains routing header (Src, Dst)
`define FLIT_BODY       2'b01   // Payload flit
`define FLIT_TAIL       2'b10   // End of packet, releases virtual channel
`define FLIT_SINGLE     2'b11   // 1-flit atomic packet (Head + Tail)

// Flit Width Configuration
// Bit [33:32]: Flit Type (2 bits)
// Bit [31:28]: Source Node ID X, Y (4 bits: SrcX[1:0], SrcY[1:0])
// Bit [27:24]: Destination Node ID X, Y (4 bits: DstX[1:0], DstY[1:0])
// Bit [23:16]: Packet Sequence / Transaction ID (8 bits)
// Bit [15:0] : 16-bit Payload Data
`define FLIT_WIDTH      34
`define FLIT_TYPE_MSB   33
`define FLIT_TYPE_LSB   32
`define FLIT_SRC_MSB    31
`define FLIT_SRC_LSB    28
`define FLIT_DST_MSB    27
`define FLIT_DST_LSB    24
`define FLIT_DATA_MSB   15
`define FLIT_DATA_LSB   0

// Router Port ID Mapping (5 ports)
`define PORT_LOCAL      3'd0
`define PORT_NORTH      3'd1
`define PORT_SOUTH      3'd2
`define PORT_EAST       3'd3
`define PORT_WEST       3'd4
`define NUM_PORTS       5

// Virtual Channel Configuration
`define NUM_VCS         2
`define VC_DEPTH        4       // 4 flits per Virtual Channel FIFO
`define CREDIT_WIDTH    3       // Log2(VC_DEPTH + 1)

// Node Coordinate Parameters (2-bit X, 2-bit Y for up to 4x4 mesh)
`define COORD_WIDTH     2

`endif // NOC_PKG_VH
