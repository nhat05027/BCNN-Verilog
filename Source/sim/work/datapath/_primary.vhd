library verilog;
use verilog.vl_types.all;
entity datapath is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        new_data        : in     vl_logic_vector(7 downto 0);
        rst_conv        : in     vl_logic;
        en_conv         : in     vl_logic;
        finish_conv     : out    vl_logic;
        addr_crom       : in     vl_logic_vector(7 downto 0);
        rst_buff_bn     : in     vl_logic;
        wre_buff_bn     : in     vl_logic;
        rst_bn          : in     vl_logic;
        ready_bn        : in     vl_logic;
        bn_addr         : in     vl_logic_vector(5 downto 0);
        finish_bn       : out    vl_logic;
        rst_mp          : in     vl_logic;
        end_mp          : in     vl_logic;
        finish_mp       : out    vl_logic;
        wre_ram         : in     vl_logic;
        addr_ram        : in     vl_logic_vector(13 downto 0);
        fc_addr         : in     vl_logic_vector(7 downto 0);
        rst_fc          : in     vl_logic;
        pos_fc          : out    vl_logic_vector(3 downto 0);
        finish_fc       : out    vl_logic;
        cnn_out         : out    vl_logic_vector(3 downto 0);
        dat_sel         : in     vl_logic_vector(1 downto 0)
    );
end datapath;
