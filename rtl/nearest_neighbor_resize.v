module neighbors_resize #(
    parameter IN_WIDTH = 100,
    parameter IN_HEIGHT = 100,
    parameter OUT_WIDTH = 200,
    parameter OUT_HEIGHT = 200
)(
    input  wire                    aclk,
    input  wire                    areset,
    
    input  wire                    s_axis_tvalid,
    output reg                     s_axis_tready,
    input  wire                    s_axis_tlast,
    input  wire [23:0]             s_axis_tdata,
    
    output reg                     m_axis_tvalid,
    output reg                     m_axis_tlast,
    output reg [23:0]              m_axis_tdata,
    input  wire                    m_axis_tready,
    
    output reg                     bram_en_a,
    output reg                     bram_we_a,
    output reg [$clog2(IN_WIDTH)-1:0] bram_addr_a,
    output reg [23:0]              bram_din_a,
    
    output reg                     bram_en_b,
    output reg [$clog2(IN_WIDTH)-1:0] bram_addr_b,
    input  wire [23:0]             bram_dout_b
);

localparam FRAC_BITS = 12; 

localparam INT_BITS_Y = $clog2(IN_HEIGHT);
localparam INT_BITS_X = $clog2(IN_WIDTH);

localparam TOTAL_BITS_Y = INT_BITS_Y + FRAC_BITS;
localparam TOTAL_BITS_X = INT_BITS_X + FRAC_BITS;

localparam [TOTAL_BITS_Y-1:0] Y_RATIO = ((IN_HEIGHT-1) << FRAC_BITS) / (OUT_HEIGHT-1);
localparam [TOTAL_BITS_X-1:0] X_RATIO = ((IN_WIDTH-1) << FRAC_BITS) / (OUT_WIDTH-1);

reg [$clog2(OUT_WIDTH)-1:0]  x_out_r;
reg [$clog2(OUT_HEIGHT)-1:0] y_out_r;

reg [$clog2(IN_HEIGHT)-1:0] y_in_r;
wire [$clog2(IN_WIDTH)-1:0] x_in;
wire [$clog2(IN_HEIGHT)-1:0] y_in;

assign x_in = (x_out_r * X_RATIO) >> FRAC_BITS;
assign y_in = (y_out_r * Y_RATIO) >> FRAC_BITS;

reg [$clog2(IN_WIDTH)-1:0] d_addr_a;
reg [$clog2(IN_HEIGHT)-1:0] current_row; // wiersz w BRAM
reg row_rdy;

always @(posedge aclk) begin
    if (!areset) begin
        s_axis_tready <= 0;
        bram_din_a <= 0;
        d_addr_a <= 0;
        bram_en_a <= 0;
        bram_we_a <= 0;
        current_row <= 0;
        row_rdy <= 0;
    end else begin
        s_axis_tready <= ~row_rdy;

        if (s_axis_tvalid && ~row_rdy) begin
            bram_en_a <= 1;
            bram_we_a <= 1;
            bram_addr_a <= d_addr_a;
            bram_din_a <= s_axis_tdata;

            if (s_axis_tlast) begin
                d_addr_a <= 0;
                current_row <= current_row + 1;
                row_rdy <= 1; 
            end else begin
                d_addr_a <= d_addr_a + 1;
            end
        end else begin
            bram_en_a <= 0;
            bram_we_a <= 0;
        end
    end
end

reg frame_active;

always @(posedge aclk) begin
    if (!areset) begin
        m_axis_tvalid <= 0;
        m_axis_tlast  <= 0;
        m_axis_tdata  <= 0;
        bram_en_b     <= 0;
        bram_addr_b   <= 0;
        x_out_r       <= 0;
        y_out_r       <= 0;
        y_in_r        <= 0;
        row_rdy       <= 0;
        frame_active <= 1;
    end else begin
        y_in_r <= y_in;

        row_rdy <= (current_row != y_in_r);

        if (m_axis_tready && !row_rdy) begin
            m_axis_tvalid <= 0;
            bram_en_b <= 0;
        end else if (m_axis_tready && row_rdy && frame_active) begin
            m_axis_tvalid <= 1;
            bram_en_b <= 1;
            bram_addr_b <= x_in;
            m_axis_tdata <= bram_dout_b;

            if (x_out_r == OUT_WIDTH-1 && y_out_r == OUT_HEIGHT-1) begin
                m_axis_tlast <= 1;
                frame_active <= 0;
            end else
                m_axis_tlast <= 0;

            if (x_out_r == OUT_WIDTH-1) begin
                x_out_r <= 0;
                if (y_out_r < OUT_HEIGHT-1)
                    y_out_r <= y_out_r + 1;
            end else begin
                x_out_r <= x_out_r + 1;
            end
        end else begin
            m_axis_tvalid <= 0;
            bram_en_b <= 0;
        end
    end
end

assign x_out = x_out_r;
assign y_out = y_out_r;

endmodule
