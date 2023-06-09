module bitcoin_hash (input logic        clk, reset_n, start,
                     input logic [15:0] message_addr, output_addr,
                    output logic        done, mem_clk, mem_we,
                    output logic [15:0] mem_addr,
                    output logic [31:0] mem_write_data,
                     input logic [31:0] mem_read_data);

parameter num_nonces = 16;

//logic [ 4:0] state;
logic [31:0] hout[num_nonces];
parameter int SHA_256_constants[7:0] = '{32'h6a09e667,32'hbb67ae85,32'h3c6ef372,32'ha54ff53a,32'h510e527f,32'h9b05688c,
32'h1f83d9ab,32'h5be0cd19};
logic [15:0] internal_output_addr;

parameter int k[64] = '{
    32'h428a2f98,32'h71374491,32'hb5c0fbcf,32'he9b5dba5,32'h3956c25b,32'h59f111f1,32'h923f82a4,32'hab1c5ed5,
    32'hd807aa98,32'h12835b01,32'h243185be,32'h550c7dc3,32'h72be5d74,32'h80deb1fe,32'h9bdc06a7,32'hc19bf174,
    32'he49b69c1,32'hefbe4786,32'h0fc19dc6,32'h240ca1cc,32'h2de92c6f,32'h4a7484aa,32'h5cb0a9dc,32'h76f988da,
    32'h983e5152,32'ha831c66d,32'hb00327c8,32'hbf597fc7,32'hc6e00bf3,32'hd5a79147,32'h06ca6351,32'h14292967,
    32'h27b70a85,32'h2e1b2138,32'h4d2c6dfc,32'h53380d13,32'h650a7354,32'h766a0abb,32'h81c2c92e,32'h92722c85,
    32'ha2bfe8a1,32'ha81a664b,32'hc24b8b70,32'hc76c51a3,32'hd192e819,32'hd6990624,32'hf40e3585,32'h106aa070,
    32'h19a4c116,32'h1e376c08,32'h2748774c,32'h34b0bcb5,32'h391c0cb3,32'h4ed8aa4a,32'h5b9cca4f,32'h682e6ff3,
    32'h748f82ee,32'h78a5636f,32'h84c87814,32'h8cc70208,32'h90befffa,32'ha4506ceb,32'hbef9a3f7,32'hc67178f2
};

// Student to add rest of the code here

logic [31:0] H_B1 [7:0]; //hash of block 1
logic [31:0] H_B2 [7:0]; //hash of block 2
wire [31:0] sha_H_in [7:0]; //chooses which value to put into sha


//logic [31:0] final_hash [num_nonces:0];
enum logic[2:0] {
	IDLE = 3'b000,
	PHASE_1 = 3'b001,
	PHASE_2 = 3'b010,
	PHASE_3 = 3'b110,
	DONE = 3'b100
} state ;

//instantiate SHA
int nonce;
logic [15:0] sha_message_addr, sha_output_addr, sha_mem_addr;
logic [31:0] sha_write_data, sha_read_data;
logic sha_start, sha_done, sha_mem_we;
simplified_sha256 sha_inst(
	.clk(clk),
	.reset_n
	(reset_n),
	.start(sha_start),
	.message_addr(sha_message_addr),
	.output_addr(sha_output_addr),
	.done(sha_done),
	.mem_clk(mem_clk),
	.mem_we(sha_mem_we),
	.mem_addr(sha_mem_addr),
	.mem_write_data(sha_write_data),
	.mem_read_data(sha_read_data),
	.hin(sha_H_in)
);
	
	

always_ff@(posedge clk or negedge reset_n)begin
	if(!reset_n) begin //resets everything
		done <= 1'b0;
		mem_we <= 1'b0;
		mem_write_data <=0;
		mem_addr <= 16'd0;
		sha_output_addr <= 0;
		sha_start <= 1'b0;
		sha_read_data <= 0;
		internal_output_addr <= 0;
		sha_H_in <= SHA_256_constants;
		nonce <= 0;
		for(int i = 0; i<8;i++)begin//reset through arrays
			H_B1[i] <= 0;
			H_B2[i] <= 0;
		end
		state <= IDLE;
	end
	else begin:case_statement
	
	case(state)
	IDLE: begin:idle_state
		sha_start <= 1'b0;
		nonce <= 0;
		mem_addr <= 16'd0;
		mem_write_data <=0;
		sha_read_data <= 0;
		done <= 1'b0;
		internal_output_addr <= 0;
		sha_output_addr <= 0;
		mem_we <= 1'b0;
		sha_message_addr <= 0;
		sha_H_in <= SHA_256_constants;
		if(start) begin
			state <= PHASE_1;
		end
		else begin
			state<=IDLE;
		end
	end:idle_state
	
	PHASE_1: begin:first_phase
		done <= 1'b0;
		mem_write_data <=0;
		sha_H_in <= SHA_256_constants;
		sha_start <= 1'b1;
		mem_we <= 1'b0;
		nonce <= 0;
		sha_output_addr <= 0;
		internal_output_addr <= output_addr;
		sha_message_addr <= message_addr;
		mem_addr <= sha_mem_addr;
		if(sha_mem_addr < 16)begin
			sha_read_data <= mem_read_data;
			state<= PHASE_1;
		end
		else if(sha_done) begin
			sha_read_data <= 0;
			state <= PHASE_2;
		end
		else if(sha_mem_we) begin
			sha_read_data <= 0;
			H_B1[sha_mem_addr] <= sha_write_data;
			state<= PHASE_1;
		end
		else begin
			H_B1[sha_mem_addr] <=0;
			mem_addr <= 0;
			sha_read_data <= 0;
			state<= PHASE_1;
		end	
	end:first_phase
	
	
	PHASE_2: begin:second_phase
		state<=PHASE_2;
		sha_start <= 1'b1;
		done <= 1'b0;
		sha_H_in <= H_B1;
		mem_write_data <=0;
		mem_we <= 1'b0;
		sha_output_addr <= 0;
		nonce <= nonce;
		internal_output_addr <= internal_output_addr;
		sha_message_addr <= message_addr+16'd16;
		mem_addr <= sha_mem_addr;
		if(sha_mem_addr < 19) begin //load the last three words into sha
			sha_read_data <= mem_read_data;
		end
		else if(sha_mem_addr == 19) begin //load nonce into sha
			sha_read_data <= nonce;
		end
		//load 12 padding words into sha
		else if(sha_mem_addr == 20)begin
			sha_read_data <= 32'h80000000;
		end
		else if(sha_mem_addr <31) begin
			sha_read_data <= 32'h00000000;
		end
		else if(sha_mem_addr <32) begin
			sha_read_data <= 32'd640;//640 bit input
		end
		else begin
			sha_read_data <= 0;
		end
		//done loading
		
		if(sha_mem_we) begin//save output
			H_B2[sha_mem_addr] <= sha_write_data;
		end	
		else begin
			H_B2[sha_mem_addr] <= H_B2[sha_mem_addr];
		end
		
		if(sha_done) begin//move state
			state <= PHASE_3;
		end
		else begin
			state <= PHASE_2;
		end
	end:second_phase
	
	
	PHASE_3: begin:third_phase
		sha_start <= 1'b1;
		state <= PHASE_3;
		done <= 1'b0;
		sha_H_in <= SHA_256_constants;
		sha_output_addr <= internal_output_addr;
		internal_output_addr <= internal_output_addr;
		sha_message_addr <= 0;
		mem_we <= sha_mem_we;
		mem_write_data <= sha_write_data;
		mem_addr <= sha_mem_addr;
		sha_message_addr <= 1'b0;
		if(sha_mem_addr<8) begin//load previous hash
			sha_read_data <= H_B2[sha_mem_addr];
			nonce <= nonce;
			internal_output_addr <= internal_output_addr;
		end
		//load [adding bits
		else if(sha_mem_addr < 9) begin
			sha_read_data <= 32'h80000000;
		end
		else if(sha_mem_addr <15)begin 
			sha_read_data <= 32'h00000000;
		end		
		else if(sha_mem_addr <16)begin 
			sha_read_data <= 32'd256;//256 bit input
		end
		else begin
			sha_read_data <=0;
		end
		//done loading padding
		
		if(sha_done && nonce < num_nonces) begin//repeat 2 and 3 for next nonces
			state <= PHASE_2;
			internal_output_addr <= internal_output_addr + 16'd8;//increment output addr by 8 words for next nonce
			nonce<=nonce+1;
		end
		else if(sha_done) begin
			nonce <= 0;
			state <= DONE;
			internal_output_addr <= internal_output_addr;
		end
		else begin
			state <= PHASE_3;
			nonce <= nonce;
			internal_output_addr <= internal_output_addr;
		end
	end:third_phase
	
	
	DONE: begin
		sha_start <= 1'b0;
		state<=DONE;
		sha_output_addr <= 0;
		sha_H_in <= SHA_256_constants;
		sha_message_addr <= 0;
		mem_we <= 1'b0;
		mem_addr <= 16'd0;
		mem_write_data <= 0;
		sha_read_data <= 0;
		internal_output_addr <= 0;
		mem_we <= 1'b0;
		done <= 1'b1;
		nonce <= 0;
		mem_write_data <=0;
	end
	
	
	default: begin
		sha_start <= 1'b0;
		sha_output_addr <= 0;
		sha_H_in <= SHA_256_constants;
		sha_message_addr <= 0;
		mem_addr <= 16'd0;
		sha_read_data <= 0;
		internal_output_addr <= 0;
		mem_we <= 1'b0;
		nonce <= 0;
		mem_write_data <=0;
		done <= 1'b0;
		state <= IDLE;
	end
	endcase
	end:case_statement
end
endmodule
