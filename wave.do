vlog -work work -vopt -stats=none {C:\Users\smm.hatami\Desktop\daneshgah\term_3\DSD\Project\git\DSD-project\matrix_multiplier.v}

vsim -gui work.matrix_multiplier_tb -voptargs=+acc




onerror {resume}

quietly WaveActivateNextPane {} 0

add wave -noupdate   sim:/matrix_multiplier_tb/*

add wave -noupdate   sim:/matrix_multiplier_tb/mm/*


add wave -position end {sim:/matrix_multiplier_tb/mm/genblk1[1]/pe/a}
add wave -position end {sim:/matrix_multiplier_tb/mm/genblk1[1]/pe/b}
add wave -position end {sim:/matrix_multiplier_tb/mm/genblk1[0]/pe/a}
add wave -position end {sim:/matrix_multiplier_tb/mm/genblk1[0]/pe/b}
add wave -position end {sim:/matrix_multiplier_tb/mm/genblk1[1]/pe/output_a}
add wave -position end {sim:/matrix_multiplier_tb/mm/genblk1[1]/pe/output_b}
add wave -position end {sim:/matrix_multiplier_tb/mm/genblk1[0]/pe/output_a}
add wave -position end {sim:/matrix_multiplier_tb/mm/genblk1[0]/pe/output_b}


run 100000 ns