# CLAUDE.md

## Claude Tool Execution Safety Template

Follow these rules for all execution inside the Bash/Code tool:

---

## 0. Initialize Environment

```bash
safe() {
    stdbuf -oL -eL script -q -c "$1" /dev/null
}

run() {
    timeout 20s bash -lc "$1" | sed -r "s/\x1B\[[0-9;]*[A-Za-z]//g"
}

stripansi() {
    sed -r "s/\x1B\[[0-9;]*[A-Za-z]//g"
}
```

---

# 1. Absolutely No Interactive Commands

Avoid tools that prompt or require TTY.

---

# 2. Do Not Run Daemons or Servers

Use nohup if needed.

---

# 3. Avoid Unlimited Output

Pipe through head.

---

# 4. Strip ANSI Output

safe "command" | stripansi

---

# 5. Use Timeouts

timeout 20s cmd

---

# 6. Unbuffered Python/Node

python -u script.py
node --unhandled-rejections=strict script.js

---

# 7. Wrap All Commands

safe "cmd"
run "cmd"


## Safe vs Unsafe Commands in Claude’s Bash/Code Tool

Concrete examples of commands that behave reliably vs. commands that cause hangs, stalls, or invisible prompts.

---

# 1. Interactive / Prompting Commands

### ❌ UNSAFE (Causes Hangs)
git add -p
npm init
pip install package
ffmpeg -i in.mp4 out.mp4
cargo new myproj
python

### ✅ SAFE
git add .
npm init -y
pip install package --no-input
ffmpeg -y -i in.mp4 out.mp4
cargo new myproj --vcs none
python -u script.py

---

# 2. Daemons and Servers

### ❌ UNSAFE
npm run dev
node server.js &
uvicorn app:app
gunicorn app:app

### ✅ SAFE
nohup npm run dev > dev.log 2>&1 &
echo "Server started (backgrounded)."

uvicorn app:app --no-use-colors --lifespan off --help

---

# 3. Large Output Tools

### ❌ UNSAFE
cat hugefile.txt
pytest -vvv
npm install

### ✅ SAFE
cat hugefile.txt | head -n 200
pytest -q | head -n 200
npm install --no-progress --quiet

---

# 4. PTY-Only Applications

### ❌ UNSAFE
vim file.txt
less README.md
top
htop
fzf
man ffmpeg

### ✅ SAFE
sed -n '1,200p' file.txt
less README.md +q
top -b -n 1
man ffmpeg | cat

---

# 5. Child Process Forking / Daemonizing

### ❌ UNSAFE
service start something
openvpn --config file.ovpn
electron app.js
webpack serve

### ✅ SAFE
service something status
webpack --help
node app.js --no-daemon

---

# 6. Unbuffered Output Examples

### ❌ UNSAFE
python script.py
node script.js

### ✅ SAFE
python -u script.py
node --unhandled-rejections=strict script.js

---

# 7. Recommended Wrappers

safe "your_command"
run  "your_command"
stripansi < file

## Rust development

Follow rules at @RUST_CLAUDE.md
