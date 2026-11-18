# ============================================================================
# File: run_sim.py
# Description: Automated Python EDA Simulation & Waveform Verification Script
# ============================================================================

import os
import subprocess
import sys

def main():
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    rtl_dir = os.path.join(root_dir, "rtl")
    sim_dir = os.path.join(root_dir, "sim")
    out_vvp = os.path.join(sim_dir, "noc_mesh.vvp")

    print("[EDA RUNNER] Compiling 2D Mesh NoC RTL with Icarus Verilog...")
    
    rtl_files = [
        os.path.join(rtl_dir, "noc_vc_buffer.v"),
        os.path.join(rtl_dir, "noc_xy_router.v"),
        os.path.join(rtl_dir, "noc_matrix_arbiter.v"),
        os.path.join(rtl_dir, "noc_crossbar.v"),
        os.path.join(rtl_dir, "noc_router.v"),
        os.path.join(rtl_dir, "noc_mesh_2x2.v"),
        os.path.join(sim_dir, "tb_noc_mesh_2x2.v")
    ]

    cmd_compile = [
        "iverilog",
        "-g2005",
        f"-I{rtl_dir}",
        "-o", out_vvp
    ] + rtl_files

    res_comp = subprocess.run(cmd_compile, capture_output=True, text=True, cwd=sim_dir)
    if res_comp.returncode != 0:
        print("[ERROR] Compilation failed:")
        print(res_comp.stderr)
        return 1

    print("[EDA RUNNER] Compilation SUCCESS! Executing simulation...")
    res_sim = subprocess.run(["vvp", out_vvp], capture_output=True, text=True, cwd=sim_dir)
    print(res_sim.stdout)
    if res_sim.returncode != 0:
        print("[ERROR] Simulation runtime error:")
        print(res_sim.stderr)
        return 1

    vcd_path = os.path.join(sim_dir, "noc_mesh.vcd")
    if os.path.exists(vcd_path):
        size_kb = os.path.getsize(vcd_path) / 1024.0
        print(f"[EDA RUNNER] Waveform generated: {vcd_path} ({size_kb:.1f} KB)")

    print("[EDA RUNNER] All steps completed successfully!")
    return 0

if __name__ == "__main__":
    sys.exit(main())
