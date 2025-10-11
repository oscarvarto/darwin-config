# Nix created scripts

Make sure that when modifying nix files, you use correct nix syntax. For the case when adding scripts in a specific
programming/scripting language (like bash, python, nushell, etc.) make sure to correctly escape special characters so
that the script can be embedded in nix files.

Nix String Literal Escaping Rules
=================================

For Double-Quoted Strings ("..."):
---------------------------------

1. To escape a double quote: \" Example: "\"" produces "

2. To escape a backslash: \\ Example: "\\" produces \

3. To escape dollar-curly (${): \${ Example: "\${" produces ${ Note: This prevents string interpolation

4. Special characters:
   - Newline: \n
   - Carriage return: \r
   - Tab: \t

5. Double-dollar-curly (${) can be written literally: Example: "$${" produces ${

For Indented Strings (''...''):
-------------------------------

1. To escape $ (dollar): ''$ Example: '' ''$ '' produces "$\n"

2. To escape '' (double single quote): ' Example: '' ''' '' produces "''\n"

3. Special characters:
   - Linefeed: ''\n
   - Carriage return: ''\r
   - Tab: ''\t

4. To escape any other character: ''\

5. To write dollar-curly (${) literally: ''${ Example: '' echo ''${PATH} '' produces "echo ${PATH}\n" Note: This is
   different from double-quoted strings!

6. Double-dollar-curly ($${) can be written literally: Example: '' $${ '' produces "$\${\n"

Key Points for Embedded Scripts:
-------------------------------

- In double-quoted strings: Use \${ to prevent interpolation
- In indented strings: Use ''${ to prevent interpolation
- @ symbol in bash arrays like ${ARRAY[@]} does NOT need escaping
- Only $ needs escaping when it precedes { for interpolation

Common Patterns:
---------------

1. Bash array expansion in double-quoted Nix string: "\${ARRAY[@]}" # Escapes the $ to prevent Nix interpolation

2. Bash array expansion in indented Nix string: '' for item in "\${ARRAY[@]}"; do echo $item done ''

3. Bash variable in double-quoted Nix string: "\$HOME" # Escapes $ to prevent Nix interpolation

4. Bash variable in indented Nix string: '' echo \$HOME ''
