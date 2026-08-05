`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/03/2026 11:52:32 PM
// Design Name: 
// Module Name: spi_master_axis
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


`timescale 1ns / 1ps

module spi_master_axis #(
    parameter DATA_WIDTH    = 16,     
    parameter SCLK_DELAY    = 10,     // Połowa okresu SCLK
    parameter CS_SETUP_TIME = 20,     // CS niski przed SCLK (Lead)
    parameter CS_HOLD_TIME  = 20,     // CS niski po SCLK (Lag)
    parameter CS_IDLE_GAP   = 100,    // NOWOŚĆ: Ile cykli CS MUSI być wysoki (przerwa między ramkami)
    parameter MODE          = 0       
) (
    output reg [DATA_WIDTH-1:0] m_axis_tdata,
    output reg                  m_axis_tvalid,
    input  wire                 m_axis_tready, 

    input                       clock,
    input                       reset_n,
    input      [DATA_WIDTH-1:0] write_data,    
    output reg                  cs_n,
    output reg                  sclk,
    output                      mosi,
    input                       miso,
    output reg                  busy           
);

    localparam IDLE          = 3'd0;
    localparam CS_START      = 3'd1;
    localparam CLOCK_HIGH    = 3'd2;
    localparam CLOCK_LOW     = 3'd3;
    localparam CLOCK_LOW_END = 3'd4;
    localparam CS_END        = 3'd5;
    localparam SEND_VALID    = 3'd6;
    localparam GAP_WAIT      = 3'd7; 

    reg [2:0]  state;
    reg [4:0]  bit_count;
    reg [15:0] sclk_counter;
    reg [15:0] delay_counter;
    reg [DATA_WIDTH-1:0] input_shift_register;
    reg [DATA_WIDTH-1:0] output_shift_register;

    assign mosi = output_shift_register[DATA_WIDTH-1];

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            sclk  <= MODE;
            cs_n  <= 1'b1;
            busy  <= 1'b0;
            m_axis_tvalid <= 1'b0;
        end else begin
            case (state)

                IDLE: begin
                    m_axis_tvalid <= 1'b0;
                    cs_n  <= 1'b1; 
                    sclk  <= MODE;
                    if (m_axis_tready) begin
                        state         <= CS_START;
                        busy          <= 1'b1;
                        cs_n          <= 1'b0; 
                        delay_counter <= CS_SETUP_TIME;
                        bit_count     <= DATA_WIDTH - 1;
                        output_shift_register <= write_data;
                    end else begin
                        busy <= 1'b0;
                    end
                end

                CS_START: begin
                    if (delay_counter > 0) begin
                        delay_counter <= delay_counter - 1;
                    end else begin
                        state        <= CLOCK_HIGH;
                        sclk         <= ~MODE; 
                        sclk_counter <= SCLK_DELAY;
                        input_shift_register <= {input_shift_register[DATA_WIDTH-2:0], miso};
                    end
                end

                CLOCK_HIGH: begin
                    if (sclk_counter > 0) begin
                        sclk_counter <= sclk_counter - 1;
                    end else begin
                        sclk         <= MODE;
                        sclk_counter <= SCLK_DELAY;
                        if (bit_count == 0) begin
                            state <= CLOCK_LOW_END;
                        end else begin
                            bit_count <= bit_count - 1;
                            output_shift_register <= {output_shift_register[DATA_WIDTH-2:0], 1'b0};
                            state <= CLOCK_LOW;
                        end
                    end
                end

                CLOCK_LOW: begin
                    if (sclk_counter > 0) begin
                        sclk_counter <= sclk_counter - 1;
                    end else begin
                        state        <= CLOCK_HIGH;
                        sclk         <= ~MODE;
                        sclk_counter <= SCLK_DELAY;
                        input_shift_register <= {input_shift_register[DATA_WIDTH-2:0], miso};
                    end
                end

                CLOCK_LOW_END: begin
                    if (sclk_counter > 0) begin
                        sclk_counter <= sclk_counter - 1;
                    end else begin
                        state         <= CS_END;
                        delay_counter <= CS_HOLD_TIME;
                    end
                end

                CS_END: begin
                    if (delay_counter > 0) begin
                        delay_counter <= delay_counter - 1;
                    end else begin
                        cs_n  <= 1'b1; 
                        state <= SEND_VALID;
                    end
                end

                SEND_VALID: begin
                    m_axis_tdata  <= input_shift_register;
                    m_axis_tvalid <= 1'b1;
                    delay_counter <= CS_IDLE_GAP; 
                    state         <= GAP_WAIT;
                end

                GAP_WAIT: begin
                    m_axis_tvalid <= 1'b0;
                    cs_n <= 1'b1; 
                    if (delay_counter > 0) begin
                        delay_counter <= delay_counter - 1;
                    end else begin
                        state <= IDLE; 
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
