module parallel_bitcoin_hash (input logic        clk, reset_n, start,
                     input logic [15:0] message_addr, output_addr,
                    output logic        done, mem_clk, mem_we,
                    output logic [15:0] mem_addr,
                    output logic [31:0] mem_write_data,
                     input logic [31:0] mem_read_data);

parameter num_nonces = 16;

//logic [ 4:0] state;
logic [31:0] hout[num_nonces];
parameter logic [31:0] SHA_256_constants[7:0] = '{32'h5be0cd19, 32'h1f83d9ab, 32'h9b05688c, 32'h510e527f, 32'ha54ff53a, 32'h3c6ef372, 32'hbb67ae85, 32'h6a09e667};

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
logic [31:0] H_B2 [num_nonces/2:0][7:0]; //hash of block 2
logic [31:0] sha_output [num_nonces-1:0];//input for the sha_instance
int loop2;
int row;
int column;
logic [31:0] sha_H_in [7:0]; //chooses which value to put into sha
assign mem_clk = clk;

//logic [31:0] final_hash [num_nonces:0];
enum logic[2:0] {
	IDLE = 3'b000,
	PHASE_1 = 3'b001,
	PHASE_2 = 3'b010,
	PHASE_3 = 3'b011,
	OUTPUT = 3'b100,
	DONE = 3'b101
} state;

//instantiate SHA
int load_counter = 0;
logic [15:0] sha_message_addr;
logic [15:0] sha_output_addr; 
logic [15:0] sha_mem_addr [num_nonces/2-1:0];
logic [31:0] sha_write_data[num_nonces/2-1:0]; 
logic [31:0] sha_read_data [num_nonces/2-1:0];
logic sha_start, sha_reset_n;
logic [num_nonces/2-1:0] sha_done;
logic sha_mem_we[num_nonces/2-1:0];
logic [7:0] sha_buffer;
genvar i;
generate for(i = 0; i<num_nonces/2;i++) begin:sha_gen_loop
	simplified_sha256 sha_inst(
	.clk(clk),
	.reset_n(sha_reset_n),
	.start(sha_start),
	.message_addr(sha_message_addr),
	.output_addr(sha_output_addr),
	.done(sha_done[i]),
	.mem_clk(),
	.mem_we(sha_mem_we[i]),
	.mem_addr(sha_mem_addr[i]),
	.mem_write_data(sha_write_data[i]),
	.mem_read_data(sha_read_data[i]),
	.hin(sha_H_in),
	.read_buffer(sha_buffer)
);
end:sha_gen_loop
endgenerate
	
	

always_ff@(posedge clk or negedge reset_n)begin
	if(!reset_n) begin //resets everything
		done <= 1'b0;
		mem_we <= 1'b0;
		mem_write_data <=0;
		load_counter <= 0;
		sha_reset_n <= reset_n;
		row<= 0;
		column <= 0;
		loop2 <= 0;
		for(int i = 0; i<8;i++)begin//reset through arrays
			H_B1[i] <= 0;
			for(int j=0; j<num_nonces/2;j++) begin
				H_B2[i][j] <= 0;
				sha_output[i][j] <= 0;
			end
		end
		state <= IDLE;
	end
	
	else begin:case_statement
	
	case(state)
	IDLE: begin
		load_counter <= 0;
		mem_we <= 1'b0;
		mem_write_data <=0;
		row<= 0;
		sha_reset_n <= reset_n;
		column <= 0;
		sha_buffer <= 8'd1;
		loop2 <= 0;
		sha_H_in <= SHA_256_constants;
		if(start) begin
			state <= PHASE_1;
		end
	end
	
	PHASE_1: begin
		done <= 1'b0;
		sha_start <= 1'b1;
		sha_reset_n <= reset_n;
		sha_output_addr <=0;
		mem_we <= 1'b0;
		mem_write_data <=0;
		sha_message_addr <= message_addr;
		sha_H_in <= SHA_256_constants;
		mem_addr <= sha_mem_addr[0]+16'd1;
		row<= 0;
		column <= 0;
		loop2 <= 0;
		if(sha_done[0]) begin
			state <= PHASE_2;
			sha_buffer <= 8'd2;
			sha_reset_n <= 1'b0;
			sha_message_addr <= message_addr+16'd16;
			sha_start <= 1'b0;
		end
		else if(sha_mem_we[0]) begin
				H_B1[sha_mem_addr[0]] <= sha_write_data[0];
		end
		else if(sha_mem_addr[0] < 16+sha_buffer)begin
			
			sha_read_data[0] <= mem_read_data;
			sha_output_addr <= 0;
			load_counter<=load_counter +1;
		end
		else begin
			//H_B1[sha_mem_addr] <=0;
			mem_addr <= 0;
			//sha_read_data <= 0;
			state<= PHASE_1;
			end
	end
	
	
	PHASE_2: begin:second_phase
		done <= 1'b0;
		sha_reset_n <= 1'b1;
		sha_start <= 1'b1;
		mem_we <= 1'b0;
		mem_write_data <=0;
		sha_H_in <= H_B1;
		sha_output_addr <= 0;
		row<= 0;
		column <= 0;
		load_counter <= 16;
		sha_message_addr <= message_addr+16'd16;
		mem_addr = sha_mem_addr[0];
		for(int j = 0; j < num_nonces/2; j++)begin:phase_2_loop
		sha_output_addr[j] <= 0;
			if(is_sha_done(sha_done)) begin//move state
				state <= PHASE_3;
				load_counter <= 0;
				sha_buffer <= 8'd0;
				sha_reset_n <= 1'b0;
				sha_start <= 1'b0;
			end
			else if(sha_mem_we[j]) begin//save output
				H_B2[j][sha_mem_addr[j]] <= sha_write_data[j];
			end	

			else if(sha_mem_addr[j]-sha_buffer < 19) begin //load the last three words into sha
				mem_addr <= sha_mem_addr[0];
				sha_read_data[j] <= mem_read_data;
				load_counter<=load_counter +1;
			end
			else if(sha_mem_addr[j]-sha_buffer == 19) begin //load nonce into sha
				if(loop2) begin
					sha_read_data[j] <= j+8;
				end
				else begin
					sha_read_data[j] <= j;
				end
				//sha_read_data[j]<= j+8*loop2;//add 8 if we are on loop 2
				load_counter <=load_counter +1;
			end
			//load 12 padding words into sha
			else if(sha_mem_addr[j]-sha_buffer == 20)begin
				sha_read_data[j] <= 32'h80000000;
				load_counter<=load_counter +1;
			end
			else if(sha_mem_addr[j]-sha_buffer <31) begin
				sha_read_data[j] <= 32'h00000000;
				load_counter <=load_counter +1;
			end
			else if(sha_mem_addr[j]-sha_buffer <32) begin
				sha_read_data[j] <= 32'd640;//640 bit input
			end
			//done loading
			else begin
				state <= PHASE_2;
			end
		end:phase_2_loop
	end:second_phase
	
	
	PHASE_3: begin:third_phase
		sha_reset_n <= 1'b1;
		done <= 1'b0;
		sha_start <= 1'b1;
		mem_we <= 0;
		//mem_write_data <=0;
		row<= 0;
		sha_H_in <= SHA_256_constants;
		sha_message_addr <= 0;
		sha_output_addr <= output_addr;
		for(int j = 0; j < num_nonces/2; j++)begin:phase_3_loop
			sha_message_addr[j] <= 0;

			if(sha_mem_we[j] && sha_mem_addr[j] == output_addr)begin//save to output array
				//sha_output[j+8*loop2] <= sha_write_data[j]; //original
				//lol
				if(loop2) begin
					sha_output[j+8] <= sha_write_data[j];
				end
				else begin
					sha_output[j] <= sha_write_data[j];
				end
				//mem_addr <= output_addr +j+loop2*8;
				//mem_write_data <= sha_write_data[j];
			end
			else if(sha_mem_addr[j]<8) begin//load previous hash
				sha_read_data[j] <= H_B2[j][sha_mem_addr[j]];
				load_counter <= load_counter +1;
			end
			//load [adding bits
			else if(sha_mem_addr[j] < 9) begin
				sha_read_data[j] <= 32'h80000000;
				load_counter<=load_counter +1;
			end
			else if(sha_mem_addr[j] <15)begin 
				sha_read_data[j] <= 32'h00000000;
				load_counter<=load_counter +1;
			end		
			else if(sha_mem_addr[j] <16)begin 
				sha_read_data[j] <= 32'd256;//256 bit input
			end
			else begin
				state <= PHASE_3;
			end
			//done loading padding

		end:phase_3_loop
		if(is_sha_done(sha_done)) begin// go to output state
				//state <= OUTPUT;
				if(!loop2)begin
					state <= PHASE_2;
					sha_buffer <= 8'd2;
					sha_reset_n <= 1'b0;
					loop2 <=1'b1;
					sha_start <= 1'b0;
					sha_message_addr <= message_addr+16'd16;
				end
				else begin
					done <= 1'b0;
					state <= OUTPUT;
				end
			end
	end:third_phase
	
	OUTPUT: begin
		
		done <= 1'b0;
		mem_we <= 1'b1;
		mem_addr <= output_addr+row;
		mem_write_data = sha_output[row];
		sha_H_in <= SHA_256_constants;
		load_counter <= 0;	
		if(row == 16)begin
			done <=1'b1;
			state <= DONE;
		end
		else begin
			row <= row+1;
			state <= OUTPUT;
		end
		

	end
	DONE: begin
		mem_we <= 1'b0;
		mem_write_data <=0;
		row<= 0;
		sha_H_in <= SHA_256_constants;
		column <= 0;
		load_counter <= 0;
		loop2 <=0;
		done <= 1'b1;
		state<= IDLE;
	end
	
	
	default: begin
		state <= IDLE;
		mem_we <= 1'b0;
		sha_H_in <= SHA_256_constants;
		done <= 1'b0;
		load_counter <= 0;
	end
	endcase
	end:case_statement
end
//function to determine when all of the sha instances are finished
function logic is_sha_done(input logic [num_nonces/2-1:0] sha_done_func);
	for(int c = 0; c<num_nonces/2;c++)begin
		if(sha_done_func == 8'b1111_1111)begin
			is_sha_done = 1'b1;
		end
		else begin
			is_sha_done = 1'b0;
		end
	end
endfunction
endmodule
