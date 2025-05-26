library verilog;
use verilog.vl_types.all;
entity SIPO110 is
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        serial_in       : in     vl_logic;
        shift           : in     vl_logic;
        parallel_out    : out    vl_logic_vector(9 downto 0)
    );
end SIPO110;
