module bcd_to_7seg(
    input [3:0] bcd_in,     // Đầu vào số BCD 4-bit (0-9)
    output reg [6:0] seg_out // Đầu ra 7 đoạn [a, b, c, d, e, f, g]
);

// Mã hóa cho led 7 đoạn loại common cathode (đoạn sáng khi mức logic 1)
always @(*) begin
    case (bcd_in)
        4'd0: seg_out = 7'b0000001; // Số 0 - Các đoạn a,b,c,d,e,f sáng
        4'd1: seg_out = 7'b1001111; // Số 1 - Các đoạn b,c sáng
        4'd2: seg_out = 7'b0010010; // Số 2 - Các đoạn a,b,g,e,d sáng
        4'd3: seg_out = 7'b0000110; // Số 3 - Các đoạn a,b,g,c,d sáng
        4'd4: seg_out = 7'b1001100; // Số 4 - Các đoạn f,g,b,c sáng
        4'd5: seg_out = 7'b0100100; // Số 5 - Các đoạn a,f,g,c,d sáng
        4'd6: seg_out = 7'b0100000; // Số 6 - Các đoạn a,f,g,c,d,e sáng
        4'd7: seg_out = 7'b0001111; // Số 7 - Các đoạn a,b,c sáng
        4'd8: seg_out = 7'b0000000; // Số 8 - Tất cả đoạn sáng
        4'd9: seg_out = 7'b0000100; // Số 9 - Các đoạn a,b,c,d,f,g sáng
        default: seg_out = 7'b1111110; // Trường hợp khác: chỉ đoạn g sáng (hiển thị dấu -)
    endcase
end

endmodule

// seg_out[6]: a (đoạn trên cùng)
// seg_out[5]: b (đoạn phải trên)
// seg_out[4]: c (đoạn phải dưới)
// seg_out[3]: d (đoạn dưới cùng)
// seg_out[2]: e (đoạn trái dưới)
// seg_out[1]: f (đoạn trái trên)
// seg_out[0]: g (đoạn giữa)