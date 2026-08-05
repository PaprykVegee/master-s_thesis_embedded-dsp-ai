`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/28/2026 02:14:22 AM
// Design Name: 
// Module Name: threshold_axis
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

module threshold_axis #(
    parameter real TRESH = 0.1,
    parameter COLOR_CH = 3 
)(
    input  wire        aclk,
    input  wire        aresetn,

    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tlast,
    input  wire [COLOR_CH*8 - 1:0] s_axis_tdata,

    output reg         m_axis_tvalid,
    output reg         m_axis_tlast,
    output reg  [COLOR_CH*8 - 1:0] m_axis_tdata,
    input  wire        m_axis_tready
);

    localparam [7:0] T = TRESH * 255;
    
    assign s_axis_tready = m_axis_tready;

    integer i;
    always @(posedge aclk) begin
        if (!aresetn) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
            m_axis_tdata  <= {COLOR_CH*8{1'b0}};
        end else if (m_axis_tready) begin
            m_axis_tvalid <= s_axis_tvalid;
            m_axis_tlast  <= s_axis_tlast;
            
            if (s_axis_tvalid) begin
                for (i = 0; i < COLOR_CH; i = i + 1) begin
                    m_axis_tdata[i*8 +: 8] <= (s_axis_tdata[i*8 +: 8] > T) ? 8'hFF : 8'h00;
                end
            end
        end
    end
endmodule