`timescale 1ns / 1ps

//instruction set macros
`define LDA 'd1
`define LDB 'd2
`define ADD 'd3
`define SUB 'd4
`define MLT 'd5
`define DIV 'd6
`define OUT 'd7
`define IN 'd8
`define JCZ 'd9
`define JCE 'd10
`define JMP 'd11
`define STR 'd12

module PROCESSOR#(size = 16)(clk__, rst, output_, input_, Eq);

input clk__;
input rst;
wire [size - 1:0] BUSS;
wire [size - 1:0] ADDR;
output [size - 1:0] output_;
input [size - 1:0] input_; 

wire [size - 1:0] buss;
wire [size - 1:0] addr;

wire [size - 1:0] TOcont;

wire [size - 1:0] A;
wire [size - 1:0] B;

assign BUSS = buss;
assign ADDR = addr;

wire ce;
wire j;
wire ROA;
wire RIA;
wire [1:0] f;
wire So;
wire ROB;
wire RIB; 
wire RAMO;
wire OI;
wire II;
wire AI;
wire AO;
wire INO;

wire [15:0] cmd;
wire [size - 1:0] rawSum;
output Eq;

assign CMD = cmd;


assign ce = cmd[0];
assign j = cmd[1];
assign ROA = cmd[2];
assign RIA = cmd[3];
assign f[0] = cmd[4];
assign f[1] = cmd[5];
assign So = cmd[6];
assign ROB = cmd[7];
assign RIB = cmd[8];
assign RAMO = cmd[9];
assign OI = cmd[10];
assign II = cmd[11];
assign AI = cmd[12];
assign AO = cmd[13];
assign INO = cmd[14];
assign RAMI = cmd[15];

PRESCALER#(19)(clk__, clk_);
PC#(size)(clk_, rst, buss, addr, j, ce);
register#(size)(clk_, rst, buss, A, RIA, ROA);  // A register
ALU#(size)(buss, A, B, f, So, Cout, rawSum, Eq);       //Arithmetic logic unit
register#(size)(clk_, rst, buss, B, RIB, ROB);  // B register
RAM_ROM#(size)(clk_, rst, addr, buss, RAMO, RAMI);              //Program memory
ADRregister#(size)(clk_, rst, buss, addr, AI, AO);   //Addres keep register
OUT#(size)(clk_, rst, buss, output_, OI);       //output port
IN#(size)(clk_, buss, input_, INO);             //input port
register#(size)(clk_, rst, buss, TOcont, II, ); // Instruction register
CU#(size)(clk_, rst, TOcont, cmd, Eq, rawSum);            // CPU control logic


 
endmodule

module PRESCALER#(size = 10)(clk__, clk_);

input clk__;
output clk_;

reg [size - 1:0] R;
assign clk_ = R[size - 1];

always@(posedge clk__)begin
    R <= R + 1;
end

endmodule

module PC#(size = 8)(clk_, rst, buss, addr, j, ce);
//pin settup
input clk_;         //clock input
input rst;
input j;            //jump to data buss number
input ce;           //count enable
output [size - 1:0] addr;  //address bar
input [size - 1:0] buss;   //data buss

reg [size - 1:0] R;        //register
assign addr = R;    //addr output

wire [1:0] X;
assign X[0] = ce;
assign X[1] = j;

always@(posedge (clk_ ^ rst))begin
    if(!rst)begin
        case(X)
            2'd0 : R <= R;
            2'd1 : R <= R + 1;
            2'd2 : R <= buss;
            2'd3 : R <= R;
        endcase
    end
    if(rst) R <= 0;
    
end 
endmodule

module register#(size = 8)(clk_, rst, buss, toALU, RI, RO);
    input clk_;
    input rst;
    inout [size - 1:0] buss;
    output [size - 1:0] toALU;
    input RI;
    input RO;

    reg [size - 1:0] R;

    assign buss = RO ? R : 'hz;
    assign toALU = R;

always@(posedge (clk_ ^ rst))begin
    if(!rst)begin
          if(RI & !RO)
            R <= buss;
    end
    if(rst) R <= 0;
end

endmodule

module ALU#(size = 8)(buss, A, B, f, So, Cout, rawSum, Eq);

output [size - 1:0] buss;
input [size - 1:0] A;
input [size - 1:0] B;
input [1:0] f;
input So;
output Cout, Eq;
output [size - 1:0] rawSum;

reg [size : 0] R;

assign buss = So ? R : 'hz;
assign Cout = R[size];
assign rawSum = R[size - 1:0];
assign Eq = A == B;

always@(1)begin

case(f)
    2'd0 : R <= A + B;
    2'd1 : R <= A - B;
    2'd2 : R <= A * B;
    2'd3 : R <= A / B;
    default: R <= A + B;
    
endcase

end

endmodule 

module RAM_ROM#(size = 8)(clk_, rst, addr, buss, RAMO, RAMI);
input clk_;
input rst;
input [size - 1:0] addr;
inout [size - 1:0] buss;
input RAMO;
input RAMI;

integer halfsize = size / 2;

reg [size - 1:0] rom [(2**(size / 2)) - 1:0];
initial
    $readmemb("rom.mem", rom, 0, (2**(size / 2)) - 1);
reg [size - 1:0] ram[2**size - 1 : (2**(size / 2))];

wire [size - 1:0] R;
reg Pick;


assign R = Pick ? rom[addr] : ram[addr];
assign buss = RAMO ? R : 'hz;

always@(1)begin
if(addr > 2**halfsize)
    Pick <= 0;
if(addr < 2**halfsize)
    Pick <= 1;
end

integer i;
always@(posedge (clk_ ^ rst))begin
    if(!rst)begin
        if(RAMI == 1)ram[addr] <= buss;
    end
end


endmodule

module ADRregister#(size = 8)(clk_, rst, buss, addr, RI, RO);
    input clk_;
    input rst;
    output [size - 1:0] buss;
    input [size - 1:0] addr;
    input RI;
    input RO;

    reg [size - 1:0] R;

    assign buss = RO ? R : 'hz;
    assign toALU = R;

always@(posedge (clk_ ^ rst))begin
    if(!rst)begin
      if(RI & !RO)
        R <= addr;
    end
    if(rst) R <= 0;
end

endmodule

module OUT#(size = 8)(clk_, rst, buss, output_, OI);
input clk_;           //clock signal
input rst;
input [size - 1:0] buss;     //data buss
output [size - 1:0] output_; //output port
input OI;             //write enable

reg [size - 1:0] R;
assign output_ = R;

always@(posedge (clk_ ^ rst))begin
    if(!rst)
        if(OI) R <= buss;
    if(rst) R <= 0;
end

endmodule

module IN#(size = 8)(clk_, buss, input_, INO);

input clk_;
output [size - 1:0] buss;
input [size - 1:0] input_;
input INO;

assign buss = INO ? input_ : 'hz;

endmodule



module CU#(size = 8)(clk_, rst, inst, cmd, Eq, rawSum);

input clk_;
input rst;
input [size - 1:0] inst;
output [15:0] cmd;
input Eq;
input [size - 1:0] rawSum;

wire Zflag;
assign Zflag = rawSum == 0;

reg [3:0] T;
reg [15:0] CMD;
reg Tcheck;

assign cmd = CMD;


always@(posedge (!clk_ ^ rst))begin
if(!rst)begin
    T <= T + 1;
    if(T > 6) T <= 0;
    if(Tcheck) T <= 0; 
    end
if(rst)
   T <= 0;  
end

always@(1)begin
case(T) //instruction fetch
       'd0 : begin
              CMD <= 'b0000101000000001;
              Tcheck <= 0;
              end
       'd1 : begin
              CMD <= 'b0001000000000000;
              end
endcase

case(inst)
    'd1 : begin //LDA
            case(T)
                4'd2 : CMD <= 'b0000001000000010;
                4'd3 : CMD <= 'b0000001000001000;
                4'd4 : CMD <= 'b0010000000000010;
                4'd5 : begin
                CMD <= 'b0000000000000001;
                Tcheck <= 1;
                end
                4'd6 : CMD <= 'd0;
                4'd7 : CMD <= 'd0;
            endcase
           end
           
    'd2 : begin //LDB
            case(T)
               4'd2 : CMD <= 'b0000001000000010;  
               4'd3 : CMD <= 'b0000001100000000;
               4'd4 : CMD <= 'b0010000000000010;
               4'd5 : begin
               CMD <= 'b0000000000000001;
               Tcheck <= 1;
               end
               4'd6 : CMD <= 'd0;    
               4'd7 : CMD <= 'd0;
            endcase
           end
           
    'd3 : begin //ADD
            case(T)
                4'd2 : CMD <= 'b0000001000000010;
                4'd3 : CMD <= 'b0000001100000000;
                4'd4 : CMD <= 'b0000000001001000;
                4'd5 : CMD <= 'b0010000000000010;
                4'd6 : begin
                CMD <= 'b0000000000000001;
                Tcheck <= 1;
                end
                4'd7 : CMD <= 'b0;
            endcase
           end
           
    'd4 : begin //SUB
            case(T)
                4'd2 : CMD <= 'b0000001000000010;
                4'd3 : CMD <= 'b0000001100000000;
                4'd4 : CMD <= 'b0000000001011000;
                4'd5 : CMD <= 'b0010000000000010;
                4'd6 : begin
                CMD <= 'b0000000000000001;
                Tcheck <= 1;
                end
                4'd7 : CMD <= 'b0;
            endcase
           end

    'd5 : begin //MLT
            case(T)
                4'd2 : CMD <= 'b0000001000000010;
                4'd3 : CMD <= 'b0000001100000000;
                4'd4 : CMD <= 'b0000000001101000;
                4'd5 : CMD <= 'b0010000000000010;
                4'd6 : begin
                CMD <= 'b0000000000000001;
                Tcheck <= 1;
                end
                4'd7 : CMD <= 'b0;
            endcase
           end
           
    'd6 : begin //DIV
            case(T)
                4'd2 : CMD <= 'b0000001000000010;
                4'd3 : CMD <= 'b0000001100000000;
                4'd4 : CMD <= 'b0000000001111000;
                4'd5 : CMD <= 'b0010000000000010;
                4'd6 : begin
                CMD <= 'b0000000000000001;
                Tcheck <= 1;
                end
                4'd7 : CMD <= 'b0;
            endcase
           end

    'd7 : begin //OUT
             case(T)
                4'd2 : CMD <= 'b0000010000000100;                     
                4'd3 : begin
                CMD <= 'b0010000000000010;  
                Tcheck <= 1;
                end                    
                4'd4 : CMD <= 'b0;                      
                4'd5 : CMD <= 'b0;                      
                4'd6 : CMD <= 'b0;                      
                4'd7 : CMD <= 'b0;
                       
            endcase
           end

    'd8 : begin // IN
            case(T)
                4'd2 : CMD <= 'b0100000000001000;
                4'd3 : begin
                CMD <= 'b0010000000000010; 
                Tcheck <= 1;
                end
                4'd4 : CMD <= 'd0;
                4'd5 : CMD <= 'd0;
                4'd6 : CMD <= 'd0;
                4'd7 : CMD <= 'd0;
            endcase
           end

    'd9 : begin // JCZ
            case(T)
                4'd2 : CMD <= 'd0000000000010000;
                4'd3 : begin
                    if(Zflag)begin
                        CMD <= 'b0000001000000010;
                        Tcheck <= 1;
                        end
                    if(~Zflag)begin
                        CMD <= 'b0000000000000001; 
                        Tcheck <= 1; 
                        end  
                end
                4'd4 : CMD <= 'd0; 
                4'd5 : CMD <= 'd0;
                4'd6 : CMD <= 'd0;
                4'd7 : CMD <= 'd0;

            endcase
           end
           
    'd10 : begin //JCE
            case(T)
                4'd2 : begin
                    if(Eq)
                        CMD <= 'b0000001000000010;
                        Tcheck <= 1;
                    if(~Eq)
                        CMD <= 'b0000000000000001;  
                        Tcheck <= 1;  
                end
                4'd3 : CMD <= 'd0; 
                4'd4 : CMD <= 'd0;
                4'd5 : CMD <= 'd0;
                4'd6 : CMD <= 'd0;
                4'd7 : CMD <= 'd0;
            endcase
           end

    'd11 : begin //JMP
            case(T)
                4'd2 : begin
                CMD <= 'b000001000000010;
                Tcheck <= 1;
                end
                4'd3 : CMD <= 'd0; 
                4'd4 : CMD <= 'd0;
                4'd5 : CMD <= 'd0;
                4'd6 : CMD <= 'd0;
                4'd7 : CMD <= 'd0;
            endcase
           end

     'd12 : begin //STR
            case(T)
                4'd2 : CMD <= 'b0000001000000010;
                4'd3 : CMD <= 'b1000000000000100; 
                4'd4 : begin
                CMD <= 'b0010000000000010;
                Tcheck <= 1;
                end
                4'd5 : CMD <= 'd0;
                4'd6 : CMD <= 'd0;
                4'd7 : CMD <= 'd0;
            endcase
           end
                     
    default : begin //NOP
            case(T)
                4'd2 : begin
                CMD <= 'd0;
                Tcheck <= 1;
                end
                4'd3 : CMD <= 'd0; 
                4'd4 : CMD <= 'd0;
                4'd5 : CMD <= 'd0;
                4'd6 : CMD <= 'd0;
                4'd7 : CMD <= 'd0;
            endcase
           end
endcase
end

endmodule

