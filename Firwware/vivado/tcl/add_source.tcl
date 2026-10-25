# Add Source files
add_files -norecurse $origin_dir/sources/zynq/video/types_arty_video.vhd
add_files -norecurse $origin_dir/sources/types_emulator_top.vhd
add_files -norecurse $origin_dir/sources/zynq/audio/types_arty_audio.vhd
add_files -norecurse $origin_dir/sources/zynq/axi_ddr/types_axi_ddr.vhd
add_files -norecurse $origin_dir/sources/msx/types_emsx_top.vhd
add_files -norecurse $origin_dir/sources/emulator_top.vhd
add_files -norecurse $origin_dir/sources/zynq/video/arty_video_top.vhd
add_files -norecurse $origin_dir/sources/zynq/video/timing_generator.vhd
add_files -norecurse $origin_dir/sources/zynq/video/scandoubler.vhd
add_files -norecurse $origin_dir/sources/zynq/video/mem2hdmi.vhd
add_files -norecurse $origin_dir/sources/zynq/video/emu2mem.vhd
add_files -norecurse $origin_dir/sources/zynq/video/resolution_detector.vhd
add_files -norecurse $origin_dir/sources/zynq/video/framebuf_calc.vhd
add_files -norecurse $origin_dir/sources/zynq/video/bicubic_scaler.vhd
add_files -norecurse $origin_dir/sources/zynq/registers/registers.vhd
add_files -norecurse $origin_dir/sources/zynq/registers/registers_top.vhd
add_files -norecurse $origin_dir/sources/zynq/audio/pwm.vhd
add_files -norecurse $origin_dir/sources/zynq/audio/i2s.vhd
add_files -norecurse $origin_dir/sources/zynq/audio/arty_audio_mixer.vhd
add_files -norecurse $origin_dir/sources/zynq/audio/arty_audio_top.vhd
add_files -norecurse $origin_dir/sources/zynq/axi_ddr/axi_ddr_top.vhd
add_files -norecurse $origin_dir/sources/zynq/axi_ddr/axi_ddr.vhd
add_files -norecurse $origin_dir/sources/zynq/ps2/ps2.vhd
add_files -norecurse $origin_dir/sources/zynq/ps2/types_ps2_kbd_emu.vhd
add_files -norecurse $origin_dir/sources/zynq/ps2/ps2_kbd.vhd
add_files -norecurse $origin_dir/sources/zynq/ps2/ps2_kbd_emu.vhd
add_files -norecurse $origin_dir/sources/zynq/ps2/ps2_mouse.vhd
add_files -norecurse $origin_dir/sources/msx/z80/t80_pack.vhd
add_files -norecurse $origin_dir/sources/msx/z80/t80.vhd
add_files -norecurse $origin_dir/sources/msx/z80/t80_alu.vhd
add_files -norecurse $origin_dir/sources/msx/z80/t80_mcode.vhd
add_files -norecurse $origin_dir/sources/msx/z80/t80_reg.vhd
add_files -norecurse $origin_dir/sources/msx/z80/t80pa.vhd
add_files -norecurse $origin_dir/sources/msx/emsx_top.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_package.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_colordec.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_command.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_doublebuf.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_graphic123m.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_graphic4567.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_hvcounter.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_interrupt.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_linebuf.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_ntsc_pal.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_register.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_spinforam.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_sprite.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_ssg.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_text12.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_vga.vhd
add_files -norecurse $origin_dir/sources/msx/video/vdp_wait_control.vhd
add_files -norecurse $origin_dir/sources/msx/peripheral/eseps2.vhd
add_files -norecurse $origin_dir/sources/msx/peripheral/iplrom.vhd
add_files -norecurse $origin_dir/sources/msx/peripheral/kanji.vhd
add_files -norecurse $origin_dir/sources/msx/peripheral/keymap.vhd
add_files -norecurse $origin_dir/sources/msx/peripheral/mapper.vhd
add_files -norecurse $origin_dir/sources/msx/peripheral/megasd.vhd
add_files -norecurse $origin_dir/sources/msx/peripheral/ram.vhd
add_files -norecurse $origin_dir/sources/msx/peripheral/rtc.vhd
add_files -norecurse $origin_dir/sources/msx/peripheral/swioports.vhd
add_files -norecurse $origin_dir/sources/msx/peripheral/systemtimer.vhd
add_files -norecurse $origin_dir/sources/msx/peripheral/ps2mouse.v
add_files -norecurse $origin_dir/sources/msx/audio/scc/megaram.vhd
add_files -norecurse $origin_dir/sources/msx/audio/scc/scc_wave.vhd
add_files -norecurse $origin_dir/sources/msx/audio/tr_pcm/tr_pcm.v
add_files -norecurse $origin_dir/sources/msx/audio/psg/ym2149.sv
add_files -norecurse $origin_dir/sources/msx/audio/psg/psg.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/eseopll.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/attacktable.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/controller.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/envelopegenerator.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/envelopememory.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/feedbackmemory.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/lineartable.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/operator.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/opll.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/outputgenerator.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/outputmemory.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/phasegenerator.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/phasememory.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/registermemory.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/sinetable.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/slotcounter.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/temporalmixer.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/vm2413.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/voicememory.vhd
add_files -norecurse $origin_dir/sources/msx/audio/OPLL/VM2413/voicerom.vhd
add_files -norecurse $origin_dir/sources/mem_test/memtest_top.vhd
add_files -norecurse $origin_dir/sources/mem_test/tester.v
add_files -norecurse $origin_dir/sources/mem_test/sdram.v
add_files -norecurse $origin_dir/sources/mem_test/rnd_vec_gen.v
add_files -norecurse $origin_dir/sources/msx/sys/audio_out.sv
add_files -norecurse $origin_dir/sources/msx/sys/iir_filter.sv
add_files -norecurse $origin_dir/sources/msx/sys/mist_adapter.v

set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/video/types_arty_video.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/types_emulator_top.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/emulator_top.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/video/arty_video_top.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/video/timing_generator.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/video/scandoubler.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/video/mem2hdmi.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/video/emu2mem.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/video/resolution_detector.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/video/framebuf_calc.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/video/bicubic_scaler.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/registers/registers.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/registers/registers_top.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/audio/types_arty_audio.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/audio/pwm.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/audio/i2s.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/audio/arty_audio_mixer.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/audio/arty_audio_top.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/axi_ddr/types_axi_ddr.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/axi_ddr/axi_ddr_top.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/axi_ddr/axi_ddr.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/ps2/ps2.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/ps2/types_ps2_kbd_emu.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/ps2/ps2_kbd_emu.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/ps2/ps2_kbd.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zynq/ps2/ps2_mouse.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/z80/t80.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/z80/t80_alu.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/z80/t80_mcode.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/z80/t80_reg.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/z80/t80pa.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/z80/t80_pack.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/types_emsx_top.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/emsx_top.vhd]
set_property file_type {VHDL} [get_files $origin_dir/sources/msx/video/*.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/peripheral/eseps2.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/peripheral/iplrom.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/peripheral/kanji.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/peripheral/keymap.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/peripheral/mapper.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/peripheral/megasd.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/peripheral/ram.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/peripheral/rtc.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/peripheral/swioports.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/peripheral/systemtimer.vhd]
set_property file_type {SystemVerilog} [get_files $origin_dir/sources/msx/peripheral/ps2mouse.v]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/scc/megaram.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/scc/scc_wave.vhd]
set_property file_type {Verilog} [get_files $origin_dir/sources/msx/audio/tr_pcm/tr_pcm.v]
set_property file_type {SystemVerilog} [get_files $origin_dir/sources/msx/audio/psg/ym2149.sv]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/psg/psg.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/eseopll.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/attacktable.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/controller.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/envelopegenerator.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/envelopememory.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/feedbackmemory.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/lineartable.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/operator.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/opll.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/outputgenerator.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/outputmemory.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/phasegenerator.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/phasememory.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/registermemory.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/sinetable.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/slotcounter.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/temporalmixer.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/vm2413.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/voicememory.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/msx/audio/OPLL/VM2413/voicerom.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/mem_test/memtest_top.vhd]
set_property file_type {SystemVerilog} [get_files $origin_dir/sources/mem_test/tester.v]
set_property file_type {SystemVerilog} [get_files $origin_dir/sources/mem_test/sdram.v]
set_property file_type {SystemVerilog} [get_files $origin_dir/sources/mem_test/rnd_vec_gen.v]
set_property file_type {SystemVerilog} [get_files $origin_dir/sources/msx/sys/audio_out.sv]
set_property file_type {SystemVerilog} [get_files $origin_dir/sources/msx/sys/iir_filter.sv]
set_property file_type {Verilog} [get_files $origin_dir/sources/msx/sys/mist_adapter.v]

