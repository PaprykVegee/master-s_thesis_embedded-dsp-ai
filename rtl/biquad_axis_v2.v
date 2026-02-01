module biquad_axis_v3 #(
    /* ================= Fixed-point formats ================= */
    parameter inout_width           = 16,
    parameter inout_decimal_width   = 15,
    parameter coefficient_width         = 16,
    parameter coefficient_decimal_width = 15,
    parameter internal_width         = 32,
    parameter internal_decimal_width = 30,

    /* ================= Biquad coefficients (Q format) ================= */
    parameter signed [coefficient_width-1:0] B0 = 0,
    parameter signed [coefficient_width-1:0] B1 = 0,
    parameter signed [coefficient_width-1:0] B2 = 0,
    parameter signed [coefficient_width-1:0] A1 = 0,
    parameter signed [coefficient_width-1:0] A2 = 0
)(
    input  wire                         aclk,
    input  wire                         resetn,

    /* ================= AXI-Stream slave ================= */
    input  wire [inout_width-1:0]       s_axis_tdata,
    input  wire                         s_axis_tvalid,
    input  wire                         s_axis_tlast,
    output wire                         s_axis_tready,

    /* ================= AXI-Stream master ================= */
    output reg  [inout_width-1:0]       m_axis_tdata,
    output reg                          m_axis_tvalid,
    output reg                          m_axis_tlast,
    input  wire                         m_axis_tready
);

    /* ====================================================== */
    /* Width calculations                                     */
    /* ====================================================== */
    localparam inout_integer_width      = inout_width - inout_decimal_width;
    localparam coefficient_integer_width= coefficient_width - coefficient_decimal_width;
    localparam internal_integer_width   = internal_width - internal_decimal_width;
    localparam ACC_WIDTH = internal_width*2;

    /* ====================================================== */
    /* Internal registers                                     */
    /* ====================================================== */
    reg signed [internal_width-1:0] x1, x2;
    reg signed [internal_width-1:0] y1, y2;
    reg signed [internal_width-1:0] y0_reg;

    wire signed [internal_width-1:0] x0;

    /* ====================================================== */
    /* Resize input to internal format                         */
    /* ====================================================== */
    assign x0 = {
        {(internal_integer_width-inout_integer_width){s_axis_tdata[inout_width-1]}},
        s_axis_tdata,
        {(internal_decimal_width-inout_decimal_width){1'b0}}
    };

    /* ====================================================== */
    /* Resize coefficients to internal format                  */
    /* ====================================================== */
    wire signed [internal_width-1:0] b0_i, b1_i, b2_i, a1_i, a2_i;
    assign b0_i = {{(internal_integer_width-coefficient_integer_width){B0[coefficient_width-1]}}, B0, {(internal_decimal_width-coefficient_decimal_width){1'b0}}};
    assign b1_i = {{(internal_integer_width-coefficient_integer_width){B1[coefficient_width-1]}}, B1, {(internal_decimal_width-coefficient_decimal_width){1'b0}}};
    assign b2_i = {{(internal_integer_width-coefficient_integer_width){B2[coefficient_width-1]}}, B2, {(internal_decimal_width-coefficient_decimal_width){1'b0}}};
    assign a1_i = {{(internal_integer_width-coefficient_integer_width){A1[coefficient_width-1]}}, A1, {(internal_decimal_width-coefficient_decimal_width){1'b0}}};
    assign a2_i = {{(internal_integer_width-coefficient_integer_width){A2[coefficient_width-1]}}, A2, {(internal_decimal_width-coefficient_decimal_width){1'b0}}};

    /* ====================================================== */
    /* Biquad equation (Direct Form I)                         */
    /* ====================================================== */
    wire signed [ACC_WIDTH-1:0] acc;
    assign acc = x0*b0_i + x1*b1_i + x2*b2_i - y1*a1_i - y2*a2_i;
    wire signed [internal_width-1:0] y0 = acc >>> internal_decimal_width;

    /* ====================================================== */
    /* AXI-Stream handshake                                   */
    /* ====================================================== */
    assign s_axis_tready = !m_axis_tvalid || m_axis_tready;

    /* ====================================================== */
    /* Filter registers                                       */
    /* ====================================================== */
    always @(posedge aclk) begin
        if (!resetn) begin
            x1 <= 0; x2 <= 0;
            y1 <= 0; y2 <= 0;
            y0_reg <= 0;

            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 0;
            m_axis_tlast  <= 0;
        end
        else begin
            /* Procesowanie nowej próbki tylko jeśli slave gotowy */
            if (s_axis_tvalid && s_axis_tready) begin
              //  $display("proces");
                x2 <= x1;
                x1 <= x0;
                y2 <= y1;
                y1 <= y0;

                y0_reg <= y0;

                m_axis_tdata  <= y0 >>> (internal_decimal_width - inout_decimal_width);
                m_axis_tlast  <= s_axis_tlast;
                m_axis_tvalid <= 1'b1;
            end

            /* Zerowanie tvalid po przyjęciu danych przez downstream */
            if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end

endmodule
