; Xonsh highlights for Helix
; Inherit Python queries and add a few xonsh-specific identifiers.
; inherits: python

; Xonsh-specific builtins (when used as function calls)
((call
  function: (identifier) @function.builtin)
 (#any-of?
  @function.builtin
  "aliases" "source" "execx" "evalx" "compilex"))

; Xonsh special identifiers
((identifier) @variable.special
 (#any-of? @variable.special "__xonsh__" "XSH" "aliases" "events"))
