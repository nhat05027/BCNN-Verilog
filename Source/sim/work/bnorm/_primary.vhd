library verilog;
use verilog.vl_types.all;
entity bnorm is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        ready           : in     vl_logic;
        data_in         : in     vl_logic_vector(15 downto 0);
        theta           : in     vl_logic_vector(11 downto 0);
        phi             : in     vl_logic_vector(11 downto 0);
        finish          : out    vl_logic;
        \out\           : out    vl_logic_vector(11 downto 0)
    );
end bnorm;
