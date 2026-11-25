# Portable Logic Synthesis Script Reference (Synopsys DC / OpenROAD Yosys Template)
set TOP_MODULE "noc_mesh_2x2"
set SDC_FILE   "syn/noc_mesh_2x2.sdc"
set rtl_files [glob -nocomplain rtl/*.v rtl/*/*.v]
read_verilog $rtl_files
elaborate $TOP_MODULE
link
source $SDC_FILE
compile_ultra -no_autoungroup
report_timing -max_paths 10 > syn/reports/timing_summary.rpt
report_area   > syn/reports/area_summary.rpt
