# Project status

This project is considered feature complete. New features will be rejected.

Bug fixes are welcome as long as they don't rock the boat too much.

# Benchmarking

- Benchmarks are located in [tests/bench/](tests/bench/).
- The local environment influences the benchmark results.  
  Thus, the results can not be compared across different environments.

**Bench move.lua**

- Setup: run inside a vertical split in Zellij.

    ```console
    nvim -l tests/bench/move.lua
    ```

**Bench resize.lua**

- Setup: run inside a vertical split in Zellij.

    ```console
    nvim -l tests/bench/move.lua
    ```

**Run all benchmarks**

- Setup: run inside a vertical split in Zellij.

    ```console
    nvim -l tests/bench/all.lua
    ```
