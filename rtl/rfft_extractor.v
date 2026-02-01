module rfft_extractor #(
    parameter DATA_WIDTH = 32,
    parameter COUNTS = 256
)(
    input  wire aclk,
    input  wire aresetn,

    // input AXI-stream (FFT output)
    input  wire s_axis_tvalid,
    output wire s_axis_tready,
    input  wire s_axis_tlast,
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,

    // output AXI-stream (half spectrum)
    output reg  m_axis_tvalid,
    input  wire m_axis_tready,
    output reg  m_axis_tlast,
    output reg  [DATA_WIDTH-1:0] m_axis_tdata
);

    localparam HALF = COUNTS/2;

    reg [$clog2(COUNTS)-1:0] bin_cnt;

    // always ready (najprościej)
    assign s_axis_tready = m_axis_tready;

    always @(posedge aclk) begin
        if (!aresetn) begin
            bin_cnt        <= 0;
            m_axis_tvalid  <= 0;
            m_axis_tlast   <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin

            if (bin_cnt <= HALF) begin
                m_axis_tdata  <= s_axis_tdata;
                m_axis_tvalid <= 1;
                m_axis_tlast  <= (bin_cnt == HALF);
            end else begin
                m_axis_tvalid <= 0;
                m_axis_tlast  <= 0;
            end

            if (s_axis_tlast)
                bin_cnt <= 0;
            else
                bin_cnt <= bin_cnt + 1;
        end else begin
            m_axis_tvalid <= 0;
            m_axis_tlast  <= 0;
        end
    end

endmodule
