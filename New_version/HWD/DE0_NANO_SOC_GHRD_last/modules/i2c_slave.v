/*
 written by: Holguer A. Becerra
 Adrizcorp@gmail.com
 holguer.becerra@upb.edu.co
*/

module i2c_slave(
	input clk,//50 MHZ
	input start,
	input mode_w_r,//1'b1 wr, and 1'b0 read
	input [7:0]data2_write,
	output reg [7:0]read_data=8'd0, // ack , data[7:0]
	output reg receive_ack=1'b0,
	output idle,
	output scl,
	inout sda
	);
									//SACK______GACK__FINISH_SCL___DIR_OUT__DIR_IN_____STATE
localparam IDLE 	   	=		'b0________0______0____0____0______0____________0000;
localparam SET_DIR   	=		'b0________0______0____0____0______0____________0001;
localparam SET_INPUT1	=		'b0________0______0____0____0______1____________0010;
localparam SET_OUPUT1	=		'b0________0______0____0____1______0____________0011;
localparam SET_INPUT2	=		'b0________0______0____0____0______1____________1010;
localparam SET_OUPUT2	=		'b0________0______0____0____1______0____________1011;
localparam SCL_HIGH  	=		'b0________0______0____1____0______0____________0100;
localparam SCL_LOW  		=		'b0________0______0____0____0______0____________0101;
localparam SCL_HIGH2 	=		'b0________0______0____1____0______0____________1110;
localparam SCL_LOW2  	=		'b0________0______0____0____0______0____________1111;
localparam SET_ACK   	=		'b1________0______0____0____1______0____________0110;
localparam GET_ACK   	=		'b0________1______0____0____0______1____________0111;
localparam FINISH	   	=		'b0________0______1____0____0______0____________1000;


localparam DELAY_7us=32'd350;
localparam DELAY_5us=32'd250;

reg [7:0]read_data_temp=8'd0;
reg [2:0]counter=3'd0;
reg [3:0]number_of_scl=4'd0;
reg [31:0]delay=31'd0;
reg dir=1'b0;
reg [9:0]state=IDLE;
wire finish=state[7];
assign scl=state[6];
wire scl_out=state[5];
wire scl_in=state[4];
reg bit_to_send=1'b0;
reg set_ack_en_reg=1'b0;
reg get_ack_en_reg=1'b0;
wire set_ack_en=state[9];
wire get_ack_en=state[8];
assign idle= state[9:0]==IDLE;
wire bit_to_send2= set_ack_en_reg ? 1'b1: bit_to_send | set_ack_en_reg | dir;
assign sda = dir ? bit_to_send2 : 1'bZ ;
wire in_sda  = sda;

always@(posedge clk) 
begin
	if(!scl)bit_to_send=data2_write[3'd7-counter[2:0]] |set_ack_en_reg;// se envia el bit q se desearia enviar 
	else bit_to_send=bit_to_send | set_ack_en_reg;
end

always@(posedge clk)
begin
	case(state[9:0])
	IDLE 	   	:
	begin
		delay[31:0]<=32'd0;
		state[9:0]<=IDLE;
		if(start)
		begin
			state[9:0]<=SET_DIR;
		end
	end
	SET_DIR   	:
	begin
		if(delay[31:0]<DELAY_7us)
		begin
			delay[31:0]<=delay[31:0]+1'b1;
			state[9:0]<=SET_DIR;
		end
		else if(mode_w_r)
		begin
			delay[31:0]<=32'd0;
			state[9:0]<=SET_OUPUT1;
		end
		else
		begin
			delay[31:0]<=32'd0;
			state[9:0]<=SET_INPUT1;
		end
	end
	SET_INPUT1	:
	begin
		delay[31:0]<=32'd0;
		state[9:0]<=SCL_LOW;
	end
	SET_OUPUT1	:
	begin
		delay[31:0]<=32'd0;
		state[9:0]<=SCL_LOW;
	end
	SET_INPUT2	:
	begin
		delay[31:0]<=32'd0;
		state[9:0]<=SCL_HIGH2;
	end
	SET_OUPUT2	:
	begin
		delay[31:0]<=32'd0;
		state[9:0]<=SCL_HIGH2;
	end
	SCL_HIGH  	:
	begin
		delay[31:0]<=32'd0;
		state[9:0]<=SCL_LOW;
		if(delay[31:0]<DELAY_7us)
		begin
			delay[31:0]<=delay[31:0]+1'b1;
			state[9:0]<=SCL_HIGH;
		end
	end
	SCL_LOW  	:	
	begin
		delay[31:0]<=32'd0;
		state[9:0]<=SCL_HIGH;
		if(number_of_scl[3:0]>3'd7 && delay[31:0]>=DELAY_7us)
		begin
			delay[31:0]<=32'd0;
			state[9:0]<=dir? SET_INPUT2:SET_OUPUT2;
		end
		else if(delay[31:0]<DELAY_7us)
		begin
				delay[31:0]<=delay[31:0]+1'b1;
				state[9:0]<=SCL_LOW;
		end
	end
	SCL_HIGH2 	:
	begin
		delay[31:0]<=32'd0;
		state[9:0]<=(dir==1'b0)? GET_ACK:SET_ACK;
		if(delay[31:0]<DELAY_7us)
		begin
			delay[31:0]<=delay[31:0]+1'b1;
			state[9:0]<=SCL_HIGH2;
		end
	end
	SCL_LOW2  	:
	begin
		delay[31:0]<=32'd0;
		state[9:0]<=FINISH;
		if(delay[31:0]<DELAY_7us)
		begin
			delay[31:0]<=delay[31:0]+1'b1;
			state[9:0]<=SCL_LOW2;
		end
	end
	SET_ACK   	:
	begin
		delay[31:0]<=32'd0;
		state[9:0]<=SCL_LOW2;
	end
	GET_ACK   	:
	begin
		delay[31:0]<=32'd0;
		state[9:0]<=SCL_LOW2;
	end
	FINISH	  :	
	begin
		delay[31:0]<=32'd0;
		state[9:0]<=IDLE;
	end
	default    :
	begin
		delay[31:0]<=32'd0;
		state[9:0]<=IDLE;
	end
	endcase
	
end

always@(posedge scl, posedge finish)
begin
	if(finish)number_of_scl[3:0]<=4'd0;
	else number_of_scl[3:0]<=number_of_scl[3:0]+1'b1;
end


always@(negedge scl)
begin
	read_data[7:0]<=read_data[7:0];
	if(number_of_scl[3:0]==4'd8)
	begin
		read_data[7:0]<=read_data_temp[7:0];//se salva el ultimo valor :D
	end
end
always@(posedge scl, posedge finish)
begin
	read_data_temp[7:0]<={read_data_temp[6:0],in_sda};//se hace corrimiento en la recepcion temporal
	if(finish)
	begin
		read_data_temp[7:0]<=8'd0;
	end
end



always@(posedge clk)
begin
	receive_ack<=receive_ack;
	if(get_ack_en_reg) // si la direccion esta en salida y el modo es escritura y hay clock de scl y ademas estamos en get ACK
	begin
		receive_ack<=in_sda;
	end
end


always@(posedge scl)
begin
	if(dir)counter[2:0]<=counter[2:0]+1'b1;
	else counter[2:0]<=3'd0;
end


always@(posedge clk)
begin
	dir<=dir;
	if(scl_out)
	begin
		dir<=1'b1;
	end
	else if(scl_in)
	begin
		dir<=1'b0;
	end
end


always@(posedge clk,posedge finish)
begin
	if(finish)
	begin
		set_ack_en_reg<=1'b0;
	end
	else
	begin	
		if(set_ack_en)
		begin
			set_ack_en_reg<=1'b1;
		end
		else
		begin
			set_ack_en_reg<=set_ack_en_reg;
		end
	end
end



always@(posedge clk,posedge finish)
begin
	if(finish)
	begin
		get_ack_en_reg<=1'b0;
	end
	else
	begin	
		if(get_ack_en)
		begin
			get_ack_en_reg<=1'b1;
		end
		else
		begin
			get_ack_en_reg<=get_ack_en_reg;
		end
	end
end



endmodule

