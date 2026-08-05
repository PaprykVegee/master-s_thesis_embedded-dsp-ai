`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/13/2026 07:07:21 PM
// Design Name: 
// Module Name: frame_extractor
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


module frame_extractor #(
    parameter EXTRACT_NUM = 64,
    parameter DATA_WIDTH = 20
)(
    input  aclk,
    input  resetn, 

    input  signed [DATA_WIDTH-1:0] s_axis_tdata,
    input                          s_axis_tvalid,
    output                         s_axis_tready,

    output reg signed [DATA_WIDTH-1:0] m_axis_tdata,
    output reg                        m_axis_tvalid,
    input                             m_axis_tready
);

    reg [31:0] counter;

    assign s_axis_tready = m_axis_tready;

    always @(posedge aclk) begin
        if (!resetn) begin
            m_axis_tdata  <= 0;
            m_axis_tvalid <= 0;
            counter       <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            if (counter < EXTRACT_NUM) begin
                counter <= counter + 1;
                m_axis_tvalid <= 0;
            end else begin
                m_axis_tdata  <= s_axis_tdata;
                m_axis_tvalid <= 1;
                counter <= counter; 
            end
        end else begin
            m_axis_tvalid <= 0;
        end
    end
endmodule
