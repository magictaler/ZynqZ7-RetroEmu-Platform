# Add xci sources
switch $board {
    arty-z7-20 {
        add_files -norecurse $origin_dir/constraints/ArtyZ7_B.xdc
    }
    AX7020 {
        add_files -norecurse $origin_dir/constraints/AX7020.xdc
    }
    default {
        error "Unknown board: $board"
    }
}
# Common to both boards
add_files -norecurse $origin_dir/constraints/ext_sdram.xdc