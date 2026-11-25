# ============================================================================
# File: run_sim.py
# Description: Portable NoC Simulation Runner (Icarus Verilog + VCD Profiler + Cocotb)
# ============================================================================

import os
import shutil
import subprocess
import sys


def resolve_tool(name):
    found = shutil.which(name)
    if found:
        return found
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sibling = os.path.join(os.path.dirname(repo_root), "iverilog", "bin", name + ".exe")
    if os.path.exists(sibling):
        return sibling
    return name


def run_icarus_and_cocotb():
    sim_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.dirname(sim_dir)
    rtl_dir = os.path.join(root_dir, "rtl")

    iverilog_exe = resolve_tool("iverilog")
    vvp_exe = resolve_tool("vvp")

    os.environ["PATH"] = os.path.dirname(iverilog_exe) + os.pathsep + os.environ.get("PATH", "")

    rtl_files = [
        os.path.join(rtl_dir, "noc_vc_buffer.v"),
        os.path.join(rtl_dir, "noc_xy_router.v"),
        os.path.join(rtl_dir, "noc_matrix_arbiter.v"),
        os.path.join(rtl_dir, "noc_crossbar.v"),
        os.path.join(rtl_dir, "noc_router.v"),
        os.path.join(rtl_dir, "noc_mesh_2x2.v"),
    ]
    tb_file = os.path.join(sim_dir, "tb_noc_mesh_2x2.v")
    vvp_out = os.path.join(sim_dir, "noc_mesh.vvp")

    print("=" * 70)
    print("  2D MESH NoC ROUTER & MESH SUBSYSTEM: RTL + COCOTB VERIFICATION")
    print("=" * 70)

    print("[1/3] Compiling with Icarus Verilog (-Wall -g2005)...")
    cmd_comp = [iverilog_exe, "-Wall", "-g2005", f"-I{rtl_dir}", "-o", vvp_out] + rtl_files + [tb_file]
    res_c = subprocess.run(cmd_comp, cwd=root_dir, capture_output=True, text=True, encoding="utf-8", errors="replace", check=False)
    if res_c.returncode != 0 or res_c.stderr.strip():
        print("[COMPILE STDOUT/STDERR]:\n" + res_c.stdout + res_c.stderr)
        return 1

    print("[2/3] Executing VVP Verilog Testbench & VCD Analyzer...")
    res_v = subprocess.run([vvp_exe, vvp_out], cwd=root_dir, capture_output=True, text=True, encoding="utf-8", errors="replace", check=False)
    print(res_v.stdout)
    if res_v.returncode != 0 or "10/10 TESTS PASSED" not in res_v.stdout:
        print("[ERROR] Verilog TB failed!")
        if res_v.stderr:
            print(res_v.stderr)
        return 1

    vcd_script = os.path.join(root_dir, "cocotb_sim", "vcd_analyzer.py")
    res_a = subprocess.run([sys.executable, vcd_script], cwd=root_dir, check=False)
    if res_a.returncode != 0:
        return 1

    print("[3/3] Executing Python Cocotb Co-Simulation (cocotb_sim/test_noc_mesh.py)...")
    try:
        from cocotb_tools.runner import get_runner
        sys.path.insert(0, os.path.join(root_dir, "cocotb_sim"))
        runner = get_runner("icarus")
        build_dir = os.path.join(sim_dir, "cocotb_build")
        runner.build(
            sources=rtl_files,
            hdl_toplevel="noc_mesh_2x2",
            includes=[rtl_dir],
            build_dir=build_dir,
            always=True,
        )
        runner.test(
            hdl_toplevel="noc_mesh_2x2",
            test_module="test_noc_mesh",
            test_dir=build_dir,
        )
        print("[SUCCESS] Both Icarus Verilog TB and Cocotb Suite PASSED!")
    except Exception as exc:
        print(f"[ERROR] Cocotb execution failed: {exc}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(run_icarus_and_cocotb())
