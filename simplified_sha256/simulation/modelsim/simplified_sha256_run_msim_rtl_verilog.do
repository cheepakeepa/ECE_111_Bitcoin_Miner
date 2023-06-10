transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/yrmho/Documents/SP23/ECE\ 111/ECE_111_Bitcoin_Miner/simplified_sha256 {C:/Users/yrmho/Documents/SP23/ECE 111/ECE_111_Bitcoin_Miner/simplified_sha256/simplified_sha256.sv}

