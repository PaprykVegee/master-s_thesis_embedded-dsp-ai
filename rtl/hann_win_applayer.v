module hann_win_applayer #(
    parameter DATA_WIDTH  = 15,   // docelowa szerokość bitowa sygnału
    parameter ROM_WIDTH   = 20,   // szerokość bitowa ROM-u
    parameter WINDOW_SIZE = 256
)(
    input  wire                     aclk,
    input  wire                     resetn,

    input  wire signed [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire                          s_axis_tlast,
    input  wire                          s_axis_tvalid,
    output wire                          s_axis_tready,

    output wire signed [DATA_WIDTH-1:0] m_axis_tdata,
    output wire                          m_axis_tlast,
    output wire                          m_axis_tvalid,
    input  wire                          m_axis_tready
);

    // AXI ready/valid
    assign s_axis_tready = m_axis_tready;

    // Rejestry wyjściowe
    reg signed [DATA_WIDTH-1:0] m_axis_tdata_r = 0;
    reg                          m_axis_tlast_r  = 0;
    reg                          m_axis_tvalid_r = 0;

    assign m_axis_tdata  = m_axis_tdata_r;
    assign m_axis_tlast  = m_axis_tlast_r;
    assign m_axis_tvalid = m_axis_tvalid_r;

    // licznik adresu ROM
    reg [7:0] counts = 0;

    // sygnał ROM
    wire signed [ROM_WIDTH-1:0] hann_val;

    hann_rom hann (
        .addr(counts),
        .data(hann_val)
    );

    // kwantyzacja ROM do DATA_WIDTH bitów z zachowaniem bitu znaku
    wire signed [DATA_WIDTH-1:0] hann_val_q;
    assign hann_val_q = hann_val[ROM_WIDTH-1 -: DATA_WIDTH];

    // wynik mnożenia
    reg signed [2*DATA_WIDTH-1:0] mult_result;

    always @(posedge aclk) begin
        if (!resetn) begin
            counts          <= 0;
            m_axis_tvalid_r <= 0;
            m_axis_tlast_r  <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            // inkrementacja licznika z cyklem
            counts <= (counts + 1) % WINDOW_SIZE;

            // mnożenie signed x signed
            mult_result <= s_axis_tdata * hann_val_q;

            // wybór DATA_WIDTH bitów z zachowaniem znaku
            m_axis_tdata_r <= mult_result[2*DATA_WIDTH-1 -: DATA_WIDTH];

            // przekazanie flagi ostatniego elementu
            m_axis_tlast_r  <= s_axis_tlast;
            m_axis_tvalid_r <= 1;
        end else begin
            // wyłącz valid jeśli brak danych
            m_axis_tvalid_r <= 0;
        end
    end

endmodule
