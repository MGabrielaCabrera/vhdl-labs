// Simple scoreboard class for tracking test results

class Scoreboard;
  int fail_count = 0;
  int fail_count_prev = 0;

  task check(string name, bit cond, string msg);
    assert (cond) else begin
      $error("[FAIL] %s: %s", name, msg);
      fail_count++;
    end
  endtask

  function void init_test(string test_name);
    $display("[%0t ns] %s", $realtime, test_name);

    fail_count_prev = fail_count; // Save current fail count to track new failures
  endfunction

  function void test_report(string test_name);
    if (fail_count - fail_count_prev == 0)
      $display("%s PASSED", test_name);
    else
      $display("%s FAILED: %0d errors", test_name, fail_count - fail_count_prev);
  endfunction


  function void general_report();
    if (fail_count == 0)
      $display("ALL TESTS PASSED");
    else
      $display("FAILED: %0d errors", fail_count);
  endfunction
endclass