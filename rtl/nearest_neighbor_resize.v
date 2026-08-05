module neighbors_resize_axis #(
    parameter COLOR_CH = 3,

    parameter IN_WIDTH = 129,
    parameter IN_HEIGHT = 129,
    parameter OUT_WIDTH = 224,
    parameter OUT_HEIGHT = 224
)(
    input  wire                    aclk,
    input  wire                    areset, 

    input  wire                    s_axis_tvalid,
    output reg                     s_axis_tready,
    input  wire                    s_axis_tlast,
    input  wire [COLOR_CH*8 - 1:0]             s_axis_tdata,

    output reg                     m_axis_tvalid,
    output reg                     m_axis_tlast,
    output reg [COLOR_CH*8 - 1:0]              m_axis_tdata,
    input  wire                    m_axis_tready,
    
    output wire [23:0] debug,

    output reg                     bram_en_a,
    output reg                     bram_we_a,
    output reg [$clog2(IN_WIDTH)-1:0] bram_addr_a,
    output reg [COLOR_CH*8 - 1:0]              bram_din_a, 
    output reg                     bram_en_b,
    output reg [$clog2(IN_WIDTH)-1:0] bram_addr_b,
    input  wire [COLOR_CH*8 - 1:0]             bram_dout_b
);
    assign debug = s_axis_tdata;
    
    localparam FRAC_BITS = 16;
    localparam [31:0] X_STEP = (IN_WIDTH << FRAC_BITS) / OUT_WIDTH;
    localparam [31:0] Y_STEP = (IN_HEIGHT << FRAC_BITS) / OUT_HEIGHT;

    reg [31:0] x_acc; 
    reg [31:0] y_acc; 
    
    reg [$clog2(OUT_WIDTH)-1:0]  x_out_cnt;
    reg [$clog2(OUT_HEIGHT)-1:0] y_out_cnt;
    reg [$clog2(IN_HEIGHT)-1:0]  y_in_cnt;

    reg row_available, row_consumed, frame_done;

    always @(posedge aclk) begin
        if (!areset) begin
            s_axis_tready <= 0;
            bram_addr_a   <= 0;
            row_available <= 0;
            y_in_cnt      <= 0;
            bram_en_a     <= 0;
            bram_we_a     <= 0;
        end else begin
            s_axis_tready <= !row_available;
            
            if (s_axis_tvalid && s_axis_tready) begin
                bram_en_a  <= 1; 
                bram_we_a  <= 1; 
                bram_din_a <= s_axis_tdata;
                
                if (s_axis_tlast) begin
                    bram_addr_a <= 0; 
                    row_available <= 1; 
                    y_in_cnt <= y_in_cnt + 1;
                end else begin
                    bram_addr_a <= bram_addr_a + 1;
                end
            end else begin
                bram_en_a <= 0; 
                bram_we_a <= 0;
                if (row_consumed) row_available <= 0;
            end
            
            if (frame_done) y_in_cnt <= 0;
        end
    end

    reg vld_p1, lst_p1;
    
    wire [$clog2(IN_WIDTH)-1:0] current_x_in = x_acc >> FRAC_BITS;
    wire [$clog2(IN_HEIGHT)-1:0] current_y_in = y_acc >> FRAC_BITS;

    always @(posedge aclk) begin
        if (!areset) begin
            x_out_cnt <= 0; y_out_cnt <= 0;
            x_acc <= 0; y_acc <= 0;
            m_axis_tvalid <= 0; m_axis_tlast <= 0;
            row_consumed <= 0; frame_done <= 0;
            vld_p1 <= 0; lst_p1 <= 0;
            bram_en_b <= 0;
        end else begin
            row_consumed <= 0; 
            frame_done   <= 0;

            if (m_axis_tready) begin
                
                if (row_available && (current_y_in == (y_in_cnt - 1))) begin
                    bram_en_b   <= 1;
                    bram_addr_b <= (current_x_in >= IN_WIDTH) ? IN_WIDTH-1 : current_x_in;
                    
                    vld_p1 <= 1;
                    lst_p1 <= (x_out_cnt == OUT_WIDTH-1);


                    if (x_out_cnt == OUT_WIDTH-1) begin
                        x_out_cnt <= 0;
                        x_acc     <= 0;
                        if (y_out_cnt == OUT_HEIGHT-1) begin
                            y_out_cnt  <= 0; 
                            y_acc      <= 0;
                            frame_done <= 1; 
                            row_consumed <= 1;
                        end else begin
                            y_out_cnt <= y_out_cnt + 1;
                            y_acc     <= y_acc + Y_STEP;
                            if (((y_acc + Y_STEP) >> FRAC_BITS) != current_y_in) row_consumed <= 1;
                        end
                    end else begin
                        x_out_cnt <= x_out_cnt + 1;
                        x_acc     <= x_acc + X_STEP;
                    end
                end else begin
                    bram_en_b <= 0;
                    vld_p1    <= 0;
                    lst_p1    <= 0;
                end

                m_axis_tvalid <= vld_p1;
                m_axis_tlast  <= lst_p1;
                m_axis_tdata  <= (vld_p1) ? bram_dout_b : 0;
            end
        end
    end
endmodule