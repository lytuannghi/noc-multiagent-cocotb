# ============================================================================
# File: test_noc_mesh.py
# Description: Modern Cocotb Python-based Verification Testbench for 2D Mesh NoC
# Author: Llama 3.3 (Cocotb Verification Engineer)
# ============================================================================

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ReadOnly
import random

def pack_flit(flit_type, sx, sy, dx, dy, seq, payload):
    """Encodes a 34-bit NoC Flit"""
    return ((flit_type & 0x3) << 32) | \
           ((sx & 0x3) << 30) | \
           ((sy & 0x3) << 28) | \
           ((dx & 0x3) << 26) | \
           ((dy & 0x3) << 24) | \
           ((seq & 0xFF) << 16) | \
           (payload & 0xFFFF)

@cocotb.test()
async def test_noc_point_to_point(dut):
    """Test 1: Single Flit Transmission from PE00 to PE10"""
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.pe00_tx_valid.value = 0
    dut.pe00_rx_credit.value = 3
    dut.pe10_rx_credit.value = 3
    await Timer(30, unit="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    dut._log.info("[COCOTB] Sending flit from PE(0,0) to PE(1,0)...")
    flit = pack_flit(0x3, 0, 0, 1, 0, 0x01, 0x1234)
    dut.pe00_tx_data.value = flit
    dut.pe00_tx_vc.value = 0
    dut.pe00_tx_valid.value = 1
    await RisingEdge(dut.clk)
    dut.pe00_tx_valid.value = 0

    # Wait for reception
    for _ in range(10):
        await RisingEdge(dut.clk)
        if dut.pe10_rx_valid.value == 1:
            dut._log.info(f"[COCOTB] Received flit at PE(1,0): {hex(int(dut.pe10_rx_data.value))}")
            assert (int(dut.pe10_rx_data.value) & 0xFFFF) == 0x1234, "Payload mismatch!"
            dut._log.info("[COCOTB] Test 1 PASSED!")
            return

    assert False, "Timeout waiting for flit at PE(1,0)!"

@cocotb.test()
async def test_noc_multi_hop_xy(dut):
    """Test 2: Multi-Hop Diagonal Routing from PE00 to PE11 via X-Y"""
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    await Timer(20, unit="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    dut._log.info("[COCOTB] Testing multi-hop diagonal delivery PE(0,0) -> PE(1,1)...")
    flit = pack_flit(0x3, 0, 0, 1, 1, 0x02, 0xCAFE)
    dut.pe00_tx_data.value = flit
    dut.pe00_tx_vc.value = 0
    dut.pe00_tx_valid.value = 1
    await RisingEdge(dut.clk)
    dut.pe00_tx_valid.value = 0

    received = False
    for _ in range(15):
        await RisingEdge(dut.clk)
        if dut.pe11_rx_valid.value == 1:
            received = True
            dut._log.info(f"[COCOTB] Multi-hop flit received at PE(1,1) with payload: {hex(int(dut.pe11_rx_data.value) & 0xFFFF)}")
            break

    assert received, "Multi-hop diagonal routing failed!"
    dut._log.info("[COCOTB] Multi-Hop Diagonal Test PASSED!")
