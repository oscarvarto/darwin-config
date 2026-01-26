#!/usr/bin/env nu

# RAM usage percentage for the Zellij status bar, works on Linux/macOS.

def main [] {
    try {
        let mem = sys mem
        let used = $mem.used
        let total = $mem.total
        let percent = ($used / $total * 100 | math round | into int)
        print $"($percent)%"
    } catch {
        print "??%"
    }
}
