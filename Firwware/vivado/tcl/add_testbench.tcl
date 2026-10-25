# Add testbench sources
add_files -norecurse $origin_dir/sources/zynq/video/types_arty_video.vhd
add_files -norecurse $origin_dir/sources/types_emulator_top.vhd
add_files -norecurse $origin_dir/sources/zynq/audio/types_arty_audio.vhd
add_files -norecurse $origin_dir/sources/zynq/axi_ddr/types_axi_ddr.vhd
add_files -norecurse $origin_dir/sources/msx/types_emsx_top.vhd
add_files -norecurse $origin_dir/sim/video_tb.vhd
add_files -norecurse $origin_dir/sim/emu_top_tb.vhd
add_files -norecurse $origin_dir/sim/axi_s2mm_slave_wr_stub.vhd
add_files -norecurse $origin_dir/sim/axi_s2mm_slave_rd_stub.vhd
add_files -norecurse $origin_dir/sources/zynq/video/scandoubler.vhd
add_files -norecurse $origin_dir/sources/zynq/video/timing_generator.vhd
add_files -norecurse $origin_dir/sources/zynq/video/framebuf_calc.vhd
add_files -norecurse $origin_dir/sources/zynq/video/resolution_detector.vhd
add_files -norecurse $origin_dir/sources/msx/peripheral/rtc.vhd
