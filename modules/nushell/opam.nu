# opam (OCaml Package Manager) integration for Nushell
# Initializes opam environment once at shell startup
# Use `opam-env-refresh` to manually update after switching opam switches

def --env load-opam-env [] {
  let opam_output = (^"/usr/bin/env" opam env --shell=sh | parse "{var}='{val}'; export {var2};")

  for row in $opam_output {
    if $row.var == 'PATH' {
      $env.PATH = ($row.val | split row ":")
    } else {
      load-env {($row.var): $row.val}
    }
  }
}

export-env {
  $env.OPAM_SHELL = "nu"

  # Initialize opam environment once at startup
  if (which opam | is-not-empty) {
    try {
      load-opam-env
    } catch {
      # Silently ignore errors (opam not initialized, etc.)
    }
  }
}

# Manually refresh opam environment (e.g., after `opam switch`)
export def --env "opam-env-refresh" [] {
  if (which opam | is-empty) {
    print "opam not found in PATH"
    return
  }

  try {
    load-opam-env
    print "opam environment refreshed"
  } catch {|e|
    print $"Failed to refresh opam environment: ($e.msg)"
  }
}
