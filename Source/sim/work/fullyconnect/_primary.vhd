library verilog;
use verilog.vl_types.all;
entity fullyconnect is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        data_in         : in     vl_logic_vector(11 downto 0);
        w               : in     vl_logic_vector(119 downto 0);
        pos_data        : out    vl_logic_vector(3 downto 0);
        cnn_out         : out    vl_logic_vector(3 downto 0);
        finish          : out    vl_logic
    );
end fullyconnect;
