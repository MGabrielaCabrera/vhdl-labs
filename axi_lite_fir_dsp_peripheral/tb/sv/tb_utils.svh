`ifndef TB_UTILS_SVH
`define TB_UTILS_SVH

int unsigned fail_count = 0;

`define CHECK(label, cond, msg) \
   label: assert (cond) \
      else begin \
         $error("[%0t ns] %s", $realtime, msg); \
         fail_count++; \
      end

`endif