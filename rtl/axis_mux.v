`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2026 12:29:14 AM
// Design Name: 
// Module Name: concat_axis
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


module axis_mux #(
    parameter WIDTH = 16
)(
    input aclk,
    input aresetn,

    input [WIDTH-1:0] s_axis_tdata_0,
    input s_axis_tvalid_0,
    output s_axis_tready_0,

    input [WIDTH-1:0] s_axis_tdata_1,
    input s_axis_tvalid_1,
    output s_axis_tready_1,

    output [WIDTH-1:0] m_axis_tdata,
    output m_axis_tvalid,
    input m_axis_tready,

    output reg error
);

    assign m_axis_tvalid = s_axis_tvalid_0 || s_axis_tvalid_1;
    assign m_axis_tdata  = s_axis_tvalid_0 ? s_axis_tdata_0 : s_axis_tdata_1;

    assign s_axis_tready_0 = m_axis_tready;
    assign s_axis_tready_1 = m_axis_tready;
    //assign s_axis_tready_1 = m_axis_tready && s_axis_tvalid_1 && !s_axis_tvalid_0;

    always @(posedge aclk) begin
        if (!aresetn) begin
            error <= 1'b0;
        end else begin
            if (s_axis_tvalid_0 && s_axis_tvalid_1) begin
                error <= 1'b1;
            end else begin
                error <= 1'b0;
            end
        end
    end

endmodule
