# Rising Edge System Synchronous Inputs
#
# A Single Data Rate (SDR) System Synchronous interface is
# an interface where the external device and the FPGA use
# the same clock, and a new data is captured one clock cycle
# after being launched
#
# input      __________            __________
# clock   __|          |__________|          |__
#           |
#           |------> (tco_min+trce_dly_min)
#           |------------> (tco_max+trce_dly_max)
#         __________      ________________
# data    __________XXXXXX_____ Data _____XXXXXXX
#

#create_generated_clock -name fwd_clk -multiply_by 1 -source [get_pins ODDR_inst/C] [get_ports CLKOUT]
create_clock -period 11.637 -name clk_85_9 [get_ports SDRAM_CLK]


# Input Delay Constraint
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[0]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[0]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[1]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[1]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[2]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[2]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[3]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[3]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[4]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[4]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[5]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[5]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[6]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[6]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[7]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[7]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[8]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[8]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[9]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[9]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[10]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[10]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[11]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[11]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[12]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[12]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[13]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[13]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[14]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[14]}]
set_input_delay -clock clk_85_9 -max 9.000 [get_ports {SDRAM_DQ[15]}]
set_input_delay -clock clk_85_9 -min 3.500 [get_ports {SDRAM_DQ[15]}]
# Report Timing Template
# report_timing -from [get_ports $input_ports] -max_paths 20 -nworst 1 -delay_type min_max -name sys_sync_rise_in  -file sys_sync_rise_in.txt;


# Rising Edge System Synchronous Outputs
#
# A System Synchronous design interface is a clocking technique in which the same
# active-edge of a system clock is used for both the source and destination device.
#
# dest        __________            __________
# clk    ____|          |__________|
#                                  |
#     (trce_dly_max+tsu) <---------|
#             (trce_dly_min-thd) <-|
#                        __    __
# data   XXXXXXXXXXXXXXXX__DATA__XXXXXXXXXXXXX
#

#set destination_clock <clock_name>;     # Name of destination clock

# Output Delay Constraint
set_output_delay -clock clk_85_9 -max 2.500 [get_ports SDRAM_CS]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports SDRAM_CS]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports SDRAM_RAS]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports SDRAM_RAS]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports SDRAM_CAS]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports SDRAM_CAS]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports SDRAM_WE]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports SDRAM_WE]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_BA[1]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_BA[1]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_BA[0]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_BA[0]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_A[0]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_A[0]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_A[1]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_A[1]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_A[2]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_A[2]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_A[3]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_A[3]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_A[4]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_A[4]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_A[5]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_A[5]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_A[6]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_A[6]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_A[7]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_A[7]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_A[8]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_A[8]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_A[9]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_A[9]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_A[10]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_A[10]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_A[11]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_A[11]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_A[12]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_A[12]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[0]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[0]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[1]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[1]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[2]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[2]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[3]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[3]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[4]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[4]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[5]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[5]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[6]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[6]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[7]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[7]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[8]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[8]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[9]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[9]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[10]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[10]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[11]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[11]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[12]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[12]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[13]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[13]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[14]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[14]}]
set_output_delay -clock clk_85_9 -max 2.500 [get_ports {SDRAM_DQ[15]}]
set_output_delay -clock clk_85_9 -min 0.200 [get_ports {SDRAM_DQ[15]}]

# Report Timing Template
# report_timing -to [get_ports $output_ports] -max_paths 20 -nworst 1 -delay_type min_max -name sys_sync_rise_out -file sys_sync_rise_out.txt;


