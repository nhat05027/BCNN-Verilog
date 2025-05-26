library verilog;
use verilog.vl_types.all;
entity maxpool is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        data_in         : in     vl_logic_vector(11 downto 0);
        end_data        : in     vl_logic;
        finish          : out    vl_logic;
        \out\           : out    vl_logic_vector(11 downto 0)
    );
end maxpool;
