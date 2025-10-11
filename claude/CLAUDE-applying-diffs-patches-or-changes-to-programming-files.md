# Applying diffs/patches or changes to programming files

When applying diffs, make sure they're complete when applying them. Specially when dealing with elisp code, or
S-expressions, make sure the final code is correct and parens are properly balanced. Verify that after commenting a
section of code, proper syntax, forms and parens exist in the final code.

Do not insert intermediate comments between parens (if comments are added, put them in their own line). This would
probably make the paren balancing check easier.
