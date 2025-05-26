library verilog;
use verilog.vl_types.all;
entity cnn is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        en              : in     vl_logic;
        data_in         : in     vl_logic_vector(7 downto 0);
        pos_data        : out    vl_logic_vector(9 downto 0);
        finish          : out    vl_logic;
        cnn_out         : out    vl_logic_vector(3 downto 0)
    );
end cnn;
