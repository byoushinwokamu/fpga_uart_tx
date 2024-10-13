`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/13 18:44:19
// Design Name: 
// Module Name: aaaa
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module uart_tx (
    input wire CLK12MHZ,         // 시스템 클럭
    input wire tx_start,         // 전송 시작 신호
    input wire [7:0] data_in,    // 전송할 데이터 (8비트)
    output reg uart_rxd_out,      // UART 송신 핀
    output reg tx_done           // 전송 완료 신호
);

parameter CLK_FREQ = 12_000_000;   // 시스템 클럭 주파수 (12MHz)
parameter BAUD_RATE = 460800;      // UART 통신 속도 (460800bps)
localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;

reg [31:0] clk_counter = 0;      // 비트 전송 주기를 맞추기 위한 카운터
reg [3:0] bit_index = 0;         // 전송할 비트 인덱스
reg [9:0] tx_shift_reg;          // Start, Data, Stop 비트 포함한 시프트 레지스터
reg tx_busy = 0;                 // UART가 바쁜지 확인
// reg tx_start = 0;                // 전송 시작 신호
// reg [7:0] data_in = 8'b01000001; // 'A'

initial begin
    uart_rxd_out = 1'b1;
end

always @(posedge CLK12MHZ) begin
    if (tx_start && !tx_busy) begin
        // 송신 시작: Start bit (0) + 8 Data bits + Stop bit (1)
        tx_shift_reg <= {1'b1, data_in, 1'b0};  // Start + Data + Stop 비트 설정
        clk_counter <= 0;
        bit_index <= 0;
        tx_busy <= 1;
        tx_done <= 0;
    end else if (tx_busy) begin
        // 비트 전송: 비트 주기 동안 대기 후 전송
        if (clk_counter < BIT_PERIOD - 1) begin
            clk_counter <= clk_counter + 1;
        end else begin
            clk_counter <= 0;
            uart_rxd_out <= tx_shift_reg[bit_index];  // 현재 비트 전송
            bit_index <= bit_index + 1;
            if (bit_index == 9) begin
                // 마지막 비트(Stop bit) 전송 후 완료
                tx_busy <= 0;
                tx_done <= 1;
            end
        end
    end
end

endmodule

module data_producer (
	input wire CLK12MHZ,
	input wire tx_done,
	output reg tx_start,
	output reg [7:0] data_to_transmit
);

parameter CLK_FREQ = 12_000_000;   // 시스템 클럭 주파수 (12MHz)
localparam ONE_SECOND = CLK_FREQ;  // 1초에 해당하는 클럭 수

reg [31:0] sec_counter = 0;      // 1초 측정을 위한 카운터
reg [7:0] abc = 8'b01000001;

always @(posedge CLK12MHZ) begin
    // 1초 타이머 로직
    if (sec_counter < ONE_SECOND - 1) begin
        sec_counter <= sec_counter + 1;
        tx_start <= 1'b0;
    end else begin
        sec_counter <= 0;
        tx_start <= 1'b1;  // 1초마다 전송 시작 신호를 활성화
				data_to_transmit <= abc;
		    abc <= abc + 1;
		    if (abc >= 8'b01000100) begin
				    abc <= 8'b01000001;
		    end
    end
end

endmodule

module supermodule (
	input wire CLK12MHZ,
	output wire uart_rxd_out
);

wire tx_done;
wire tx_start;
wire [7:0] data_wire;

uart_tx Tx (
	.CLK12MHZ(CLK12MHZ),
	.tx_start(tx_start),
	.tx_done(tx_done),
	.data_in(data_wire),
	.uart_rxd_out(uart_rxd_out)
);

data_producer dp (
	.CLK12MHZ(CLK12MHZ),
	.tx_start(tx_start),
	.tx_done(tx_done),
	.data_to_transmit(data_wire)
);

endmodule