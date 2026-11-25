#!/usr/bin/env python3
import os
from build_layout_engine import build_asic_layout

if __name__ == "__main__":
    lay_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    gds_out = os.path.join(lay_root, "gds", "noc_mesh_2x2.gds")
    rep_out = os.path.join(lay_root, "reports", "drc_report.txt")
    build_asic_layout(
        gds_path=gds_out,
        report_path=rep_out,
        top_name="noc_mesh_2x2",
        libname="NOC_MESH_2X2_LIB",
        die_w=420000,
        die_h=420000,
        macro_cols=2,
        macro_rows=2,
        pad_count_per_side=4,
    )
