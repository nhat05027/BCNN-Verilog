module cnn (
    input wire clk,
    input wire rst,
    input wire en,
    input wire[7:0] data_in, // Data in type 8bit
    output reg[9:0] pos_data,
    output reg finish,
    output reg[3:0] cnn_out // output
);
    reg [7:0] addr_crom;
    reg [5:0] bn_addr;

    reg rst_buff_bn, wre_buff_bn;

    wire finish_bn;
    reg rst_bn, ready_bn;

    reg rst_mp, end_mp;
    wire finish_mp;

    reg wre_ram;
    reg [13:0] addr_ram;

    wire[3:0] pos_fc;
    reg[7:0] fc_addr;
    reg rst_fc;
    // wire ld_w_fc;
    wire finish_fc;

    reg [1:0]dat_sel;
    reg rst_conv;
    reg en_conv;

    datapath DP (
    .clk(clk),
    .rst(rst),

    .new_data(data_in),

    .rst_conv(rst_conv),
    .en_conv(en_conv),
    .finish_conv(finish_conv),

    .addr_crom(addr_crom),

    .rst_buff_bn(rst_buff_bn),
    .wre_buff_bn(wre_buff_bn),

    .rst_bn(rst_bn), 
    .ready_bn(ready_bn), 
    .bn_addr(bn_addr),
    .finish_bn(finish_bn),

    .rst_mp(rst_mp),
    .end_mp(end_mp), 
    .finish_mp(finish_mp),

    .wre_ram(wre_ram),
    .addr_ram(addr_ram),

    .fc_addr(fc_addr),
    .rst_fc(rst_fc),
    .pos_fc(pos_fc),
    // .ld_w_fc(ld_w_fc),
    .finish_fc(finish_fc),
    .cnn_out(cnn_out),   

    .dat_sel(dat_sel)
);
    // Block FSM
    reg [3:0]block_no;

    localparam LOAD = 4'd0;
    localparam CONV1 = 4'd1;
    localparam CONV2 = 4'd2;
    localparam MPOOL1 = 4'd3;
    localparam CONV3 = 4'd4;
    localparam CONV4 = 4'd5;
    localparam MPOOL2 = 4'd6;
    localparam CONV5 = 4'd7;
    localparam GMPOOL = 4'd8;
    localparam FULLCONN = 4'd9;
    localparam FINISH = 4'd15;


    localparam CONV1_ST_MEM = 14'd1;
    localparam CONV1_ST_CROM = 8'd0;
    localparam CONV1_ST_TPROM = 6'd0;

    localparam CONV2_ST_MEM = 14'd785;
    localparam CONV2_ST_CROM = 8'd4;
    localparam CONV2_ST_TPROM = 6'd4;

    localparam MPOOL1_ST_MEM = 14'd3921;

    localparam CONV3_ST_MEM = 14'd7057;
    localparam CONV3_ST_CROM = 8'd20;
    localparam CONV3_ST_TPROM = 6'd8;

    localparam CONV4_ST_MEM = 14'd7841;
    localparam CONV4_ST_CROM = 8'd52;
    localparam CONV4_ST_TPROM = 6'd16;

    localparam MPOOL2_ST_MEM = 14'd9409;

    localparam CONV5_ST_MEM = 14'd10977;
    localparam CONV5_ST_CROM = 8'd116;
    localparam CONV5_ST_TPROM = 6'd24;

    localparam GMPOOL_ST_MEM = 14'd11369;

    localparam DENSE_ST_MEM = 14'd12153;

    //Conv temp
    reg [4:0] x_pos_temp_conv, y_pos_temp_conv;
    reg [2:0] x_pos_kernel, y_pos_kernel;
    reg next_block;
    reg [4:0] kernel_no_conv;
    reg [3:0] window_no_conv;
    reg lastpixel;


    
    //
    initial begin
        pos_data=0;
        block_no =0;
        next_block = 0;
        kernel_no_conv = 0;
        window_no_conv = 0;
        x_pos_temp_conv = 0;
        x_pos_kernel = 0;
        y_pos_temp_conv = 0;
        y_pos_kernel = 0;
        lastpixel = 0;
        finish = 0;
    end
    //
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pos_data <= 0;
            block_no <= 4'd0;
            next_block <= 0;
            kernel_no_conv <= 0;
            window_no_conv <= 0;
            x_pos_temp_conv <= 0;
            x_pos_kernel <= 0;
            y_pos_temp_conv <= 0;
            y_pos_kernel <= 0;
            lastpixel <=0;
            finish <=0;
   

        end else if (en) begin
            case (block_no)
                LOAD: begin
                    rst_conv <=1;
                    dat_sel <= 2'b00;
                    if (pos_data < 785) begin
                        wre_ram <= 1;
                        addr_ram <= CONV1_ST_MEM + pos_data;
                        pos_data <= pos_data+1;
                    end else begin 
                        block_no <= CONV1;
                    end
                end
                CONV1: begin
                    dat_sel <= 2'b01;
                    bn_addr <= CONV1_ST_TPROM + kernel_no_conv;
                    addr_crom <= CONV1_ST_CROM + kernel_no_conv;

                    if (next_block) begin
                        ready_bn <=1;
                        addr_ram <= CONV2_ST_MEM + kernel_no_conv*784 + y_pos_temp_conv*28 + x_pos_temp_conv-1+lastpixel;
                        rst_conv <=1;
                        wre_buff_bn <=0;
                        if (finish_bn) begin
                            next_block <= 0;
                            ready_bn <= 0;
                            wre_ram <=1;

                            if (y_pos_temp_conv==27&x_pos_temp_conv==27) begin
                                if (lastpixel) begin
                                    kernel_no_conv <= kernel_no_conv + 1;
                                    y_pos_temp_conv <= 0;
                                    x_pos_temp_conv <= 0;
                                    lastpixel <= 0;
                                    if (kernel_no_conv>=3) begin
                                        block_no <= CONV2;
                                        kernel_no_conv <= 0;
                                        next_block <=0;
                                        rst_buff_bn <=1;
                                    end
                                end else begin
                                    lastpixel <= 1;
                                end
                            end
                        end
                    end
                    else begin
                        rst_bn <= 1;
                        wre_ram <=0;
                        rst_buff_bn <=1;
                        rst_conv <=0;
                        en_conv <= 1;

                        if (((x_pos_temp_conv==0)&(x_pos_kernel==0))|
                            ((x_pos_temp_conv==27)&(x_pos_kernel==2))|
                            ((y_pos_temp_conv==0)&(y_pos_kernel==0))|
                            ((y_pos_temp_conv==27)&(y_pos_kernel==2))) begin

                            addr_ram <= 14'd0; // dia chi chua zero
                        end
                        else begin
                            addr_ram <= CONV1_ST_MEM + (y_pos_temp_conv + y_pos_kernel -1)*28 + (x_pos_temp_conv + x_pos_kernel -1);
                        end

                        if (x_pos_kernel<2) x_pos_kernel <= x_pos_kernel+1;
                        else begin
                            if (y_pos_kernel<2) begin
                                y_pos_kernel <= y_pos_kernel+1;
                                x_pos_kernel <= 3'd0;
                            end
                            else begin // xong conv
                                if (finish_conv) begin
                                    rst_buff_bn <=0;
                                    wre_buff_bn <=1;
                                    next_block <= 1'b1;
                                    rst_bn <= 0;
                                    en_conv <=0;

                                    x_pos_kernel <= 3'd0;
                                    y_pos_kernel <= 3'd0;

                                    if (x_pos_temp_conv<27) x_pos_temp_conv <= x_pos_temp_conv+1;
                                    else begin
                                        if (y_pos_temp_conv<27) begin
                                            y_pos_temp_conv <= y_pos_temp_conv+1;
                                            x_pos_temp_conv <= 5'd0;
                                        end
                                    end 
                                end
                            end 
                        end
                    end
                end

                CONV2: begin
                    dat_sel <= 2'b01;
                    bn_addr <= CONV2_ST_TPROM + kernel_no_conv;


                    if (next_block) begin
                        ready_bn <=1;
                        addr_ram <= MPOOL1_ST_MEM + kernel_no_conv*784 + y_pos_temp_conv*28 + x_pos_temp_conv+lastpixel;
                        wre_ram <=1;
                        rst_conv <=1;
                        wre_buff_bn <=0;
                        if (finish_bn) begin
                            next_block <= 0;
                            ready_bn <= 0;

                            if (window_no_conv > 3) begin
                                if (x_pos_temp_conv<27) x_pos_temp_conv <= x_pos_temp_conv+1;
                                else if (y_pos_temp_conv<27) begin
                                    y_pos_temp_conv <= y_pos_temp_conv+1;
                                    x_pos_temp_conv <= 5'd0;
                                end
                                else if (y_pos_temp_conv==27&x_pos_temp_conv==27) begin
                                    if (lastpixel) begin
                                        kernel_no_conv <= kernel_no_conv + 1;
                                        y_pos_temp_conv <= 0;
                                        x_pos_temp_conv <= 0;
                                        lastpixel <= 0;

                                        if (kernel_no_conv>=3) begin
                                            wre_ram <=0;
                                            block_no <= MPOOL1;
                                            rst_mp <= 1;
                                            kernel_no_conv <= 0;
                                            next_block <=0;
                                            rst_buff_bn <=1;
                                        end
                                    end else begin
                                        lastpixel <= 1;
                                    end
                                end

                                window_no_conv <=0;
                            end
                        end
                    end
                    else begin
                        addr_crom <= CONV2_ST_CROM + kernel_no_conv*4 + window_no_conv;
                        rst_bn <= 1;
                        wre_ram <=0;
                        rst_conv <=0;
                        en_conv <= 1;
                        if (window_no_conv == 0) rst_buff_bn <=1;

                        if (((x_pos_temp_conv==0)&(x_pos_kernel==0))|
                            ((x_pos_temp_conv==27)&(x_pos_kernel==2))|
                            ((y_pos_temp_conv==0)&(y_pos_kernel==0))|
                            ((y_pos_temp_conv==27)&(y_pos_kernel==2))) begin

                            addr_ram <= 14'd0; // dia chi chua zero
                        end
                        else begin
                            addr_ram <= CONV2_ST_MEM + window_no_conv*784 + (y_pos_temp_conv + y_pos_kernel -1)*28 + (x_pos_temp_conv + x_pos_kernel -1);
                        end

                        if (x_pos_kernel<2) x_pos_kernel <= x_pos_kernel+1;
                        else begin
                            if (y_pos_kernel<2) begin
                                y_pos_kernel <= y_pos_kernel+1;
                                x_pos_kernel <= 3'd0;
                            end
                            else begin // xong conv
                                if (finish_conv) begin
                                    wre_buff_bn <=1;
                                    rst_buff_bn <= 0;
                                    next_block <= 1'b1;
                                    rst_bn <= 0;
                                    en_conv <=0;

                                    x_pos_kernel <= 3'd0;
                                    y_pos_kernel <= 3'd0;

                                    window_no_conv <= window_no_conv+1;
                                end
                            end 
                        end
                    end
                end

                MPOOL1: begin
                    dat_sel <= 2'b10;

                    if (next_block) begin
                        next_block <= 0;
                        wre_ram <=0;
                        rst_mp <= 1;
                        end_mp <=0;

                        if (x_pos_temp_conv<13) x_pos_temp_conv <= x_pos_temp_conv+1;
                        else if (y_pos_temp_conv<13) begin
                            y_pos_temp_conv <= y_pos_temp_conv+1;
                            x_pos_temp_conv <= 5'd0;
                        end
                        else begin
                            kernel_no_conv <= kernel_no_conv + 1;
                            y_pos_temp_conv <= 0;
                            x_pos_temp_conv <= 0;
                            if (kernel_no_conv>=3) begin
                                block_no <= CONV3;
                                kernel_no_conv <= 0;
                                next_block <=0;
                                rst_buff_bn <=1;
                            end

                        end
                    end

                    else begin
                        rst_mp <=0;
                        end_mp <=0;

                        addr_ram <= MPOOL1_ST_MEM + kernel_no_conv*784 + (y_pos_temp_conv*2 + y_pos_kernel)*28 + (x_pos_temp_conv*2 + x_pos_kernel);

                        if (x_pos_kernel<1) x_pos_kernel <= x_pos_kernel+1;
                        else begin
                            if (y_pos_kernel<1) begin
                                y_pos_kernel <= y_pos_kernel+1;
                                x_pos_kernel <= 3'd0;
                            end
                            else begin // xong mp
                                if (!lastpixel) lastpixel <=1;
                                else begin
                                    end_mp <= 1;
                                    addr_ram <= CONV3_ST_MEM + kernel_no_conv*196 + y_pos_temp_conv*14 + x_pos_temp_conv;
                                    wre_ram <=1;
                                    if (finish_mp) begin
                                        next_block <= 1'b1;
                                        lastpixel <=0;
                                        x_pos_kernel <= 3'd0;
                                        y_pos_kernel <= 3'd0;

                                    end
                                end
                            end 
                        end
                    end
                end

                CONV3: begin
                    dat_sel <= 2'b01;
                    bn_addr <= CONV3_ST_TPROM + kernel_no_conv;


                    if (next_block) begin
                        ready_bn <=1;
                        addr_ram <= CONV4_ST_MEM + kernel_no_conv*196 + y_pos_temp_conv*14 + x_pos_temp_conv+lastpixel;
                        wre_ram <=1;
                        rst_conv <=1;
                        wre_buff_bn <=0;
                        if (finish_bn) begin
                            next_block <= 0;
                            ready_bn <= 0;

                            if (window_no_conv > 3) begin
                                if (x_pos_temp_conv<13) x_pos_temp_conv <= x_pos_temp_conv+1;
                                else if (y_pos_temp_conv<13) begin
                                    y_pos_temp_conv <= y_pos_temp_conv+1;
                                    x_pos_temp_conv <= 5'd0;
                                end
                                else if (y_pos_temp_conv==13&x_pos_temp_conv==13) begin
                                    if (lastpixel) begin
                                        kernel_no_conv <= kernel_no_conv + 1;
                                        y_pos_temp_conv <= 0;
                                        x_pos_temp_conv <= 0;
                                        lastpixel <= 0;

                                        if (kernel_no_conv>=7) begin
                                            wre_ram <=0;
                                            block_no <= CONV4;
                                            rst_mp <= 1;
                                            kernel_no_conv <= 0;
                                            next_block <=0;
                                            rst_buff_bn <=1;
                                        end
                                    end else begin
                                        lastpixel <= 1;
                                    end
                                end

                                window_no_conv <=0;
                            end
                        end
                    end
                    else begin
                        addr_crom <= CONV3_ST_CROM + kernel_no_conv*4 + window_no_conv;
                        rst_bn <= 1;
                        wre_ram <=0;
                        rst_conv <=0;
                        en_conv <= 1;
                        if (window_no_conv == 0) rst_buff_bn <=1;

                        if (((x_pos_temp_conv==0)&(x_pos_kernel==0))|
                            ((x_pos_temp_conv==13)&(x_pos_kernel==2))|
                            ((y_pos_temp_conv==0)&(y_pos_kernel==0))|
                            ((y_pos_temp_conv==13)&(y_pos_kernel==2))) begin

                            addr_ram <= 14'd0; // dia chi chua zero
                        end
                        else begin
                            addr_ram <= CONV3_ST_MEM + window_no_conv*196 + (y_pos_temp_conv + y_pos_kernel -1)*14 + (x_pos_temp_conv + x_pos_kernel -1);
                        end

                        if (x_pos_kernel<2) x_pos_kernel <= x_pos_kernel+1;
                        else begin
                            if (y_pos_kernel<2) begin
                                y_pos_kernel <= y_pos_kernel+1;
                                x_pos_kernel <= 3'd0;
                            end
                            else begin // xong conv
                                if (finish_conv) begin
                                    wre_buff_bn <=1;
                                    rst_buff_bn <= 0;
                                    next_block <= 1'b1;
                                    rst_bn <= 0;
                                    en_conv <=0;

                                    x_pos_kernel <= 3'd0;
                                    y_pos_kernel <= 3'd0;

                                    window_no_conv <= window_no_conv+1;
                                end
                            end 
                        end
                    end
                end


                CONV4: begin
                    dat_sel <= 2'b01;
                    bn_addr <= CONV4_ST_TPROM + kernel_no_conv;


                    if (next_block) begin
                        ready_bn <=1;
                        addr_ram <= MPOOL2_ST_MEM + kernel_no_conv*196 + y_pos_temp_conv*14 + x_pos_temp_conv+lastpixel;
                        wre_ram <=1;
                        rst_conv <=1;
                        wre_buff_bn <=0;
                        if (finish_bn) begin
                            next_block <= 0;
                            ready_bn <= 0;

                            if (window_no_conv > 7) begin
                                if (x_pos_temp_conv<13) x_pos_temp_conv <= x_pos_temp_conv+1;
                                else if (y_pos_temp_conv<13) begin
                                    y_pos_temp_conv <= y_pos_temp_conv+1;
                                    x_pos_temp_conv <= 5'd0;
                                end
                                else if (y_pos_temp_conv==13&x_pos_temp_conv==13) begin
                                    if (lastpixel) begin
                                        kernel_no_conv <= kernel_no_conv + 1;
                                        y_pos_temp_conv <= 0;
                                        x_pos_temp_conv <= 0;
                                        lastpixel <= 0;

                                        if (kernel_no_conv>=7) begin
                                            wre_ram <=0;
                                            block_no <= MPOOL2;
                                            rst_mp <= 1;
                                            kernel_no_conv <= 0;
                                            next_block <=0;
                                            rst_buff_bn <=1;
                                        end
                                    end else begin
                                        lastpixel <= 1;
                                    end
                                end

                                window_no_conv <=0;
                            end
                        end
                    end
                    else begin
                        addr_crom <= CONV4_ST_CROM + kernel_no_conv*8 + window_no_conv;
                        rst_bn <= 1;
                        wre_ram <=0;
                        rst_conv <=0;
                        en_conv <= 1;
                        if (window_no_conv == 0) rst_buff_bn <=1;

                        if (((x_pos_temp_conv==0)&(x_pos_kernel==0))|
                            ((x_pos_temp_conv==13)&(x_pos_kernel==2))|
                            ((y_pos_temp_conv==0)&(y_pos_kernel==0))|
                            ((y_pos_temp_conv==13)&(y_pos_kernel==2))) begin

                            addr_ram <= 14'd0; // dia chi chua zero
                        end
                        else begin
                            addr_ram <= CONV4_ST_MEM + window_no_conv*196 + (y_pos_temp_conv + y_pos_kernel -1)*14 + (x_pos_temp_conv + x_pos_kernel -1);
                        end

                        if (x_pos_kernel<2) x_pos_kernel <= x_pos_kernel+1;
                        else begin
                            if (y_pos_kernel<2) begin
                                y_pos_kernel <= y_pos_kernel+1;
                                x_pos_kernel <= 3'd0;
                            end
                            else begin // xong conv
                                if (finish_conv) begin
                                    wre_buff_bn <=1;
                                    rst_buff_bn <= 0;
                                    next_block <= 1'b1;
                                    rst_bn <= 0;
                                    en_conv <=0;

                                    x_pos_kernel <= 3'd0;
                                    y_pos_kernel <= 3'd0;

                                    window_no_conv <= window_no_conv+1;
                                end
                            end 
                        end
                    end
                end

                MPOOL2: begin
                    dat_sel <= 2'b10;

                    if (next_block) begin
                        next_block <= 0;
                        wre_ram <=0;
                        rst_mp <= 1;
                        end_mp <=0;

                        if (x_pos_temp_conv<6) x_pos_temp_conv <= x_pos_temp_conv+1;
                        else if (y_pos_temp_conv<6) begin
                            y_pos_temp_conv <= y_pos_temp_conv+1;
                            x_pos_temp_conv <= 5'd0;
                        end
                        else begin
                            kernel_no_conv <= kernel_no_conv + 1;
                            y_pos_temp_conv <= 0;
                            x_pos_temp_conv <= 0;
                            if (kernel_no_conv>=7) begin
                                block_no <= CONV5;
                                kernel_no_conv <= 0;
                                next_block <=0;
                                rst_buff_bn <=1;
                            end

                        end
                    end

                    else begin
                        rst_mp <=0;
                        end_mp <=0;

                        addr_ram <= MPOOL2_ST_MEM + kernel_no_conv*196 + (y_pos_temp_conv*2 + y_pos_kernel)*14 + (x_pos_temp_conv*2 + x_pos_kernel);

                        if (x_pos_kernel<1) x_pos_kernel <= x_pos_kernel+1;
                        else begin
                            if (y_pos_kernel<1) begin
                                y_pos_kernel <= y_pos_kernel+1;
                                x_pos_kernel <= 3'd0;
                            end
                            else begin // xong mp
                                if (!lastpixel) lastpixel <=1;
                                else begin
                                    end_mp <= 1;
                                    addr_ram <= CONV5_ST_MEM + kernel_no_conv*49 + y_pos_temp_conv*7 + x_pos_temp_conv;
                                    wre_ram <=1;
                                    if (finish_mp) begin
                                        next_block <= 1'b1;
                                        lastpixel <=0;
                                        x_pos_kernel <= 3'd0;
                                        y_pos_kernel <= 3'd0;

                                    end
                                end
                            end 
                        end
                    end
                end

                CONV5: begin
                    dat_sel <= 2'b01;
                    bn_addr <= CONV5_ST_TPROM + kernel_no_conv;


                    if (next_block) begin
                        ready_bn <=1;
                        addr_ram <= GMPOOL_ST_MEM + kernel_no_conv*49 + y_pos_temp_conv*7 + x_pos_temp_conv+lastpixel;
                        wre_ram <=1;
                        rst_conv <=1;
                        wre_buff_bn <=0;
                        if (finish_bn) begin
                            next_block <= 0;
                            ready_bn <= 0;

                            if (window_no_conv > 7) begin
                                if (x_pos_temp_conv<6) x_pos_temp_conv <= x_pos_temp_conv+1;
                                else if (y_pos_temp_conv<6) begin
                                    y_pos_temp_conv <= y_pos_temp_conv+1;
                                    x_pos_temp_conv <= 5'd0;
                                end
                                else if (y_pos_temp_conv==6&x_pos_temp_conv==6) begin
                                    if (lastpixel) begin
                                        kernel_no_conv <= kernel_no_conv + 1;
                                        y_pos_temp_conv <= 0;
                                        x_pos_temp_conv <= 0;
                                        lastpixel <= 0;

                                        if (kernel_no_conv>=15) begin
                                            wre_ram <=0;
                                            block_no <= GMPOOL;
                                            rst_mp <= 1;
                                            kernel_no_conv <= 0;
                                            next_block <=0;
                                            rst_buff_bn <=1;
                                        end
                                    end else begin
                                        lastpixel <= 1;
                                    end
                                end

                                window_no_conv <=0;
                            end
                        end
                    end
                    else begin
                        addr_crom <= CONV5_ST_CROM + kernel_no_conv*8 + window_no_conv;
                        rst_bn <= 1;
                        wre_ram <=0;
                        rst_conv <=0;
                        en_conv <= 1;
                        if (window_no_conv == 0) rst_buff_bn <=1;

                        if (((x_pos_temp_conv==0)&(x_pos_kernel==0))|
                            ((x_pos_temp_conv==6)&(x_pos_kernel==2))|
                            ((y_pos_temp_conv==0)&(y_pos_kernel==0))|
                            ((y_pos_temp_conv==6)&(y_pos_kernel==2))) begin

                            addr_ram <= 14'd0; // dia chi chua zero
                        end
                        else begin
                            addr_ram <= CONV5_ST_MEM + window_no_conv*49 + (y_pos_temp_conv + y_pos_kernel -1)*7 + (x_pos_temp_conv + x_pos_kernel -1);
                        end

                        if (x_pos_kernel<2) x_pos_kernel <= x_pos_kernel+1;
                        else begin
                            if (y_pos_kernel<2) begin
                                y_pos_kernel <= y_pos_kernel+1;
                                x_pos_kernel <= 3'd0;
                            end
                            else begin // xong conv
                                if (finish_conv) begin
                                    wre_buff_bn <=1;
                                    rst_buff_bn <= 0;
                                    next_block <= 1'b1;
                                    rst_bn <= 0;
                                    en_conv <=0;

                                    x_pos_kernel <= 3'd0;
                                    y_pos_kernel <= 3'd0;

                                    window_no_conv <= window_no_conv+1;
                                end
                            end 
                        end
                    end
                end

                GMPOOL: begin
                    dat_sel <= 2'b10;

                    if (next_block) begin
                        next_block <= 0;
                        wre_ram <=0;
                        rst_mp <= 1;
                        end_mp <=0;

                        kernel_no_conv <= kernel_no_conv + 1;
                        if (kernel_no_conv>=15) begin
                            block_no <= FULLCONN;
                            kernel_no_conv <= 0;
                            x_pos_temp_conv <= 0;
                            next_block <=0;
                            rst_fc <= 1;
                        end
                    end

                    else begin
                        rst_mp <=0;
                        end_mp <=0;

                        addr_ram <= GMPOOL_ST_MEM + kernel_no_conv*49 + y_pos_temp_conv*7 + x_pos_temp_conv;

                        if (x_pos_temp_conv<6) x_pos_temp_conv <= x_pos_temp_conv+1;
                        else begin
                            if (y_pos_temp_conv<6) begin
                                y_pos_temp_conv <= y_pos_temp_conv+1;
                                x_pos_temp_conv <= 0;
                            end
                            else begin // xong mp
                                if (!lastpixel) lastpixel <=1;
                                else begin
                                    end_mp <= 1;
                                    addr_ram <= DENSE_ST_MEM + kernel_no_conv;
                                    wre_ram <=1;
                                    if (finish_mp) begin
                                        next_block <= 1'b1;
                                        lastpixel <=0;
                                        x_pos_temp_conv <= 0;
                                        y_pos_temp_conv <= 0;

                                    end
                                end
                            end 
                        end
                    end
                end

                // FULLCONN: begin
                //     rst_fc <= 0;
                //     addr_ram <= DENSE_ST_MEM + pos_fc;
                //     if (x_pos_temp_conv<10) begin
                //         if (ld_w_fc) begin
                //             fc_addr <= kernel_no_conv + (9-x_pos_temp_conv)*16;
                //             x_pos_temp_conv <= x_pos_temp_conv + 1;
                //         end
                //     end
                //     else begin
                //         x_pos_temp_conv <= 0;
                //         kernel_no_conv <= kernel_no_conv + 1;
                //     end
                //     if (finish_fc) begin
                //         block_no <= FINISH;
                //     end
                // end
                FULLCONN: begin
                    rst_fc <= 0;
                    addr_ram <= DENSE_ST_MEM + pos_fc;
                    fc_addr <= pos_fc;
 
                    if (finish_fc) begin
                        block_no <= FINISH;
                    end
                end

                FINISH:
                    finish <= 1;

                default: begin
                end
            endcase
        end
    end

endmodule
