`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/07/2025 05:44:04 PM
// Design Name: 
// Module Name: hann_win_applayer
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


module hann_win_applayer #(
    parameter DATA_WIDTH = 20,
    parameter WINDOW_SIZE = 256
)(
    input aclk,
    input resetn, 

    input  [DATA_WIDTH-1:0] s_axis_tdata,
    input                   s_axis_tlast,
    input                   s_axis_tvalid,
    output                  s_axis_tready,

    output [DATA_WIDTH-1:0] m_axis_tdata,
    output                  m_axis_tlast,
    output                  m_axis_tvalid,
    input                   m_axis_tready
);

    assign s_axis_tready = m_axis_tready;

    reg [DATA_WIDTH-1:0] m_axis_tdata_r = 0;
    reg m_axis_tlast_r  = 0;
    reg m_axis_tvalid_r = 0;

    assign m_axis_tdata  = m_axis_tdata_r;
    assign m_axis_tlast  = m_axis_tlast_r;
    assign m_axis_tvalid = m_axis_tvalid_r;

    reg [7:0] counts = 0;
    reg [DATA_WIDTH-1:0] hann_val;

    hann_rom hann(
        .addr(counts),
        .data(hann_val)
    );

    always @(posedge aclk) begin
        if (!resetn) begin
            counts          <= 0;
            m_axis_tvalid_r <= 0;
            m_axis_tlast_r  <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            counts          <= counts + 1;
            m_axis_tdata_r  <= hann_val * s_axis_tdata;
            m_axis_tlast_r  <= s_axis_tlast;
            m_axis_tvalid_r <= 1;
        end
    end

endmodule

