module bitcoin_hash (input logic        clk, reset_n, start,
                     input logic [15:0] message_addr, output_addr,
                    output logic        done, mem_clk, mem_we,
                    output logic [15:0] mem_addr,
                    output logic [31:0] mem_write_data,
                     input logic [31:0] mem_read_data);

parameter num_nonces = 16;

//logic [ 4:0] state;
logic [31:0] hout[num_nonces];
parameter int SHA_256_constants[7:0] = {32'6a09e667,32'bb67ae85,32'3c6ef372,32'a54ff53a,32'510e527f,32'9b05688c,
32'1f83d9ab,32'5be0cd19};

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

logic [31:0] input_message [19:0]; //original input message
logic [31:0] H_B1 [7:0]; //hash of block 1
logic [31:0] H_B2 [7:0]; //hash of block 2
logic [31:0] sha_input1 [15:0];//input for the sha_instance
logic [31:0] sha_input2 [7:0];//input for the sha_instance
logic [31:0] sha_output [15:0];//input for the sha_instance

//logic [31:0] final_hash [num_nonces:0];
enum logic[2:0] {
	IDLE = 2b'000;
	LOAD = 2b'001
	PHASE_1 = 2'b010;
	PHASE_2 = 2b'011;
	PHASE_3 = 2b'100;
	DONE = 2b'101;
} state;

//instantiate SHA
int load_counter = 0;

always_ff@(posedge clk, negedge reset_n)begin
	if(!reset_n) begin //resets everything
		done <= 1b'0;
		wr_en <= 1b'0;
		mem_write_data <=0;
		load_counter <= 0;
		for(int i = 0; i<num_nonces;i++)begin//reset through arrays
			h_b1[i] <= 0;
			h_b2[i] <= 0;
			sha_input[i] <= 0;
			sha_output[i] <= 0;
			hout[i] <= 0;
		end
		state <= IDLE;
	end
	
	case(state)begin
	IDLE: begin
		if(start) begin
			state <= LOAD;
		end
	end

	LOAD: begin
		mem_addr <= message_addr;
		if(load_counter >21) begin
			state = PHASE_1;
		end
		else begin
			input_message[load_counter] <= mem_read_data;
			load_counter++;
		end
	end
	
	PHASE_1: begin
		sha_input1 <= input_message[15:0];
		sha_input2 <= SHA_256_constants;	
	end
	

	DONE: begin
		mem_we <= 1b'1;
		mem_addr <= output_addr;
		mem_write_data = final_hash;
		done <= 1b'1;
	end
	
	
	default: begin
		state <= IDLE;
	end
	end
end
endmodule
