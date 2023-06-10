transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/jacob/Documents/GitHub/ECE\ 111/ECE_111_Bitcoin_Miner/parallel_bitcoin_hash {C:/Users/jacob/Documents/GitHub/ECE 111/ECE_111_Bitcoin_Miner/parallel_bitcoin_hash/simplified_sha256.sv}
vlog -sv -work work +incdir+C:/Users/jacob/Documents/GitHub/ECE\ 111/ECE_111_Bitcoin_Miner/parallel_bitcoin_hash {C:/Users/jacob/Documents/GitHub/ECE 111/ECE_111_Bitcoin_Miner/parallel_bitcoin_hash/parallel_bitcoin_hash.sv}

