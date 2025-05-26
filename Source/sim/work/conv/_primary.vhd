library verilog;
use verilog.vl_types.all;
entity conv is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        en_conv         : in     vl_logic;
        data_in         : in     vl_logic_vector(11 downto 0);
        w               : in     vl_logic_vector(8 downto 0);
        finish          : out    vl_logic;
        \out\           : out    vl_logic_vector(15 downto 0)
    );
end conv;
