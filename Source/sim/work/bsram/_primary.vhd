library verilog;
use verilog.vl_types.all;
entity bsram is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        ce              : in     vl_logic;
        wre             : in     vl_logic;
        addr            : in     vl_logic_vector(13 downto 0);
        data_in         : in     vl_logic_vector(11 downto 0);
        data_out        : out    vl_logic_vector(11 downto 0)
    );
end bsram;
