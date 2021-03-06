module max6675_decoder(
			input clk,
			input miso,
			input start,
			output finish,
			output idle,
			output cs,
			output sclk,
			output [15:0]temp_max6675
	);
							  ///finish___idle___sclk___cs____state
localparam IDLE	=	   10'b0________1______0_______1________000001;		
localparam STATE1	=		10'b0________0______0_______0________000010;
localparam STATE2	=		10'b0________0______1_______0________000100;
localparam STATE3	=		10'b0________0______0_______0________001000;
localparam STATE4	=		10'b0________0______0_______1________010000;	
localparam FINISH	=		10'b1________0______0_______1________100000;
localparam DELAY_1ms = 17'd100000;
//localparam DELAY_1ms = 17'd100000;

reg [9:0]state=IDLE;
reg [16:0]delay=DELAY_1ms;
reg [3:0]conteo=4'd0;
reg [15:0]max6675_data=15'd0;
reg [15:0]max6675_data2=15'd0;
assign temp_max6675[15:0]=max6675_data2[15:0];
assign finish=state[9];
assign idle=state[8];
assign sclk=~state[7];
assign cs=state[6];

always@(posedge clk)
begin
	case(state[9:0])
	IDLE	:begin
				conteo[3:0]<=4'd0;
				delay[16:0]<=DELAY_1ms;
				state[9:0]<=STATE1;
				if(!start)
					begin
						state[9:0]<=IDLE;
					end
			 end
	STATE1:begin
				conteo[3:0]<=4'd0;
				delay[16:0]<=delay[16:0]-1'b1;
				state[9:0]<=STATE1;
				if(delay[16:0]==0)
					begin
						delay[16:0]<=DELAY_1ms;
						state[9:0]<=STATE2;
					end
			 end
	STATE2:begin
				conteo[3:0]<=conteo[3:0];
				delay[16:0]<=delay[16:0]-1'b1;
				state[9:0]<=STATE2;
				if(delay[16:0]==0)
					begin
						delay[16:0]<=DELAY_1ms;
						state[9:0]<=STATE3;
					end
			 end
	STATE3:begin
				conteo[3:0]<=conteo[3:0];
				delay[16:0]<=delay[16:0]-1'b1;
				state[9:0]<=STATE3;
				if(delay[16:0]==0)
					begin
						conteo[3:0]<=conteo[3:0]+1'b1;
						delay[16:0]<=DELAY_1ms;
						state[9:0]<=STATE2;
						if(conteo[3:0]==15)
							begin
								delay[16:0]<=DELAY_1ms;
								state[9:0]<=STATE4;
							end
					end
			 end
	STATE4:begin
				conteo[3:0]<=conteo[3:0];
				delay[16:0]<=delay[16:0]-1'b1;
				state[9:0]<=STATE4;
				if(delay[16:0]==0)
					begin
						state[9:0]<=FINISH;
					end
			 end
	FINISH:begin
				conteo[3:0]<=4'd0;
				delay[16:0]<=10'd0;
				state[9:0]<=IDLE;
			 end
	default:begin
				conteo[3:0]<=4'd0;
				delay[16:0]<=10'd0;
				state[9:0]<=IDLE;
			 end
	endcase
end


always@(posedge sclk)
begin
	max6675_data[15:0]<={max6675_data[14:0],miso};
end

always@(posedge finish)
begin
	max6675_data2[15:0]<=max6675_data[15:0];
end





endmodule
