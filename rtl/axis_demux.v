`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2026 02:57:15 AM
// Design Name: 
// Module Name: axis_demux
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


module axis_demux #(
    parameter WIDTH = 16
)(
    input aclk,
    input aresetn, 

    input  s_axis_tvalid,
    output s_axis_tready,
    input  [WIDTH-1:0] s_axis_tdata,
    
    output m_axis_tvalid_0,
    output [WIDTH-1:0] m_axis_tdata_0,
    input  m_axis_tready_0,

    output m_axis_tvalid_1,
    output [WIDTH-1:0] m_axis_tdata_1,
    input  m_axis_tready_1
);
    assign m_axis_tdata_0 = s_axis_tdata;
    assign m_axis_tdata_1 = s_axis_tdata;

    assign s_axis_tready = m_axis_tready_0 || m_axis_tready_1;

    assign m_axis_tvalid_0 = s_axis_tvalid;
    assign m_axis_tvalid_1 = s_axis_tvalid;
endmodule
