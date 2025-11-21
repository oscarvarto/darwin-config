# RUST_CLAUDE.md

### *Additional Rules for Reliable Rust Development Inside Claude’s Bash/Code Tool*

This document extends the general *CLAUDE.md* guidelines with **Rust-specific execution rules**.
Claude’s execution sandbox has several limitations (no PTY, piped stdout, strict buffering, no interactive stdin, limited pipe size, and unreliable detection of daemon/forking processes).
Rust tools and binaries frequently trigger these limits.

These rules ensure *predictable*, *non-interactive*, *non-daemonizing*, *Claude-safe* Rust workflows.

---

# 0. Principles

Rust tooling is powerful but noisy.
Claude’s environment cannot reliably handle:

* Background tasks
* Watchers
* Servers
* Unlimited output
* ANSI colors
* Buffering delays
* Interactive binaries
* Thread leaks
* Binary output into stdout

These rules prevent stalls and hangs.

---

# 1. Critical Rules (Mandatory)

## 1.1 Never run any Rust watcher

**Do NOT use:**

```
cargo watch
cargo watch -x run
cargo-watch
```

Watchers run indefinitely → Claude never returns.

**Instead:**

```
cargo build
cargo test
cargo run --quiet
```

---

## 1.2 Avoid long-running executables without supervision

**Unsafe:**

```
cargo run
cargo run --bin api
cargo run --bin worker
```

These may run forever.

**Safe:**

```
timeout 20s cargo run
timeout 20s cargo run --bin api
```

Or background safely:

```
nohup cargo run --bin api > server.log 2>&1 &
echo "Started."
```

---

## 1.3 Prevent debug-print spamming

`dbg!`, `println!("{:#?}", ...)`, and logging crates can produce enormous output, which overwhelms Claude’s pipe buffer and causes hangs.

**Avoid:**

```rust
dbg!(big_struct);
println!("{:?}", some_massive_tree);
```

**Use concise structured output instead:**

```rust
println!("Status: {}", status);
```

Or redirect:

```
cargo run > output.log
```

---

## 1.4 Rust stdout MUST flush

Rust stdout is fully buffered when piped (Claude’s case), causing “no output” hangs.

Add manual flushing when printing important progress:

```rust
use std::io::{stdout, Write};
stdout().flush().unwrap();
```

Or wrap with pseudo-TTY:

```
safe "cargo run"
```

---

## 1.5 No interactive Rust programs

Avoid reading from stdin unless a non-interactive path exists.

**Unsafe:**

```rust
use std::io::stdin;
stdin().read_line(&mut input).unwrap();
```

**Safe pattern:**

```rust
if std::env::var("NON_INTERACTIVE").is_ok() {
    return Ok(());
}
```

Run with:

```
NON_INTERACTIVE=1 cargo run
```

---

# 2. Recommended Rules

## 2.1 Use build-before-run workflow

Avoid combined diagnostic noise:

```
cargo build --quiet
cargo run --quiet
```

---

## 2.2 Disable ANSI colors in Rust tools

Cargo emits color codes that Claude may misparse.

Set globally:

```
export CARGO_TERM_COLOR=never
```

Or per command:

```
cargo --color never build
cargo --color never test
cargo --color never run
```

---

## 2.3 Limit test output

Rust test consoles can explode with lines.

**Safer:**

```
cargo test --quiet
```

Or:

```
cargo test -- --nocapture | head -n 200
```

---

## 2.4 Avoid interactive/dynamic test frameworks

Do not use:

```
cargo nextest run --interactive
```

Nextest is safe only in non-interactive mode:

```
cargo nextest run
```

---

## 2.5 When using `rustc` directly, strip ANSI

```
run "rustc my.rs 2>&1 | stripansi"
```

---

# 3. Optional Advanced Rules (Expert-Level Stability)

## 3.1 Avoid writing binary output to stdout

Claude cannot safely consume binary bytes from pipelines.

Do NOT:

```
cargo run > out.bin
```

(where output is binary)

Better:

```rust
let mut file = std::fs::File::create("output.bin")?;
file.write_all(&binary_data)?;
```

---

## 3.2 Avoid Criterion live-mode

Criterion spawns child processes and prints ANSI charts.

Unsafe:

```
cargo bench
```

Safe:

```
cargo bench --quiet > bench.txt
```

Claude can then read the file safely.

---

## 3.3 Avoid thread leaks

Claude may wait forever if background threads keep running after `main()` returns.

Always `join` spawned threads:

```rust
let handle = std::thread::spawn(...);
handle.join().unwrap();
```

---

## 3.4 Prefer `cargo check` during iterative work

Faster, quieter, and safer:

```
cargo check --quiet
```

---

# 4. Claude-Safe Rust Command Recipes

### Quick build:

```
cargo --color never build --quiet
```

### Run with logs suppressed:

```
cargo --color never run --quiet | head -n 200
```

### Run with timeout:

```
timeout 20s cargo run --quiet
```

### Test quietly:

```
cargo --color never test --quiet
```

### Test with controlled output:

```
cargo test -- --nocapture | head -n 200
```

### Benchmark safely:

```
cargo bench --quiet > bench.txt
```

### Background server:

```
nohup cargo run --bin api > api.log 2>&1 &
echo "Running in background."
```

---

# 5. Summary

**Critical (must follow):**

* No watchers
* No servers without timeout/nohup
* Avoid debug spam
* Flush stdout
* Avoid interactive binaries

**Recommended:**

* Build before run
* Limit test output
* Avoid binary stdout
* Prefer quiet flags

**Optional:**

* Avoid live benchmark UIs
* Join threads
* Redirect heavy logs to files

