#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { Command } = require('commander');
const parinfer = require('parinfer');

const program = new Command();

// Package version
const packageJson = require('./package.json');

program
  .name('elisp-formatter')
  .description('Check and format Elisp S-expressions using Parinfer with auto-repair capabilities')
  .version(packageJson.version || '1.0.0')
  .addHelpText('before', `
🔧 Elisp Formatter - Advanced S-expression formatting with auto-repair

This tool formats Elisp files using Parinfer and can automatically repair
structural issues like missing parentheses or unbalanced expressions.
`)
  .addHelpText('after', `
📖 FORMATTING MODES:
  • check     - Validate S-expression balance (no changes made)
  • indent    - Indentation drives structure (aggressive paren fixing)
  • paren     - Parentheses drive structure (preserves existing parens)
  • smart     - Intelligent hybrid mode (recommended for most cases)
  • elisp     - Smart mode + Elisp-specific formatting rules (recommended)
  • batch     - Process multiple .el files in a directory

🔧 AUTO-REPAIR FEATURES:
  The formatter can automatically fix common structural issues:
  • Missing closing parentheses
  • Unbalanced expressions
  • Malformed S-expressions
  
  Auto-repair is enabled by default. Use --no-auto-repair to disable.

📋 USAGE EXAMPLES:

  Basic formatting:
    elisp-formatter elisp my-config.el
    elisp-formatter smart my-config.el

  Check without modifying:
    elisp-formatter elisp my-config.el --check
    elisp-formatter check my-config.el

  Output to stdout:
    elisp-formatter elisp my-config.el --stdout

  Disable auto-repair:
    elisp-formatter elisp my-config.el --no-auto-repair

  Process entire directory:
    elisp-formatter batch ./config
    elisp-formatter batch ./config --mode elisp
    elisp-formatter batch ./config --check

  Advanced batch processing:
    elisp-formatter batch ./config --mode smart --no-auto-repair
    elisp-formatter batch ./config --stdout

🚀 RECOMMENDED WORKFLOWS:

  For custom Emacs configs:
    elisp-formatter batch ~/.emacs.d --mode elisp

  Quick validation:
    elisp-formatter batch . --check

  Safe preview before changes:
    elisp-formatter batch . --stdout | less

💡 TIP: Use 'elisp' mode for best results with Emacs Lisp files.
     It includes specialized formatting rules for Elisp constructs.
`);

// Helper function to read file
function readFile(filePath) {
  try {
    return fs.readFileSync(filePath, 'utf8');
  } catch (error) {
    console.error(`Error reading file ${filePath}: ${error.message}`);
    process.exit(1);
  }
}

// Helper function to write file
function writeFile(filePath, content) {
  try {
    fs.writeFileSync(filePath, content, 'utf8');
  } catch (error) {
    console.error(`Error writing file ${filePath}: ${error.message}`);
    process.exit(1);
  }
}

// Helper function to get all .el files in directory
function getElispFiles(directory) {
  try {
    const files = fs.readdirSync(directory, { withFileTypes: true });
    let elFiles = [];
    
    for (const file of files) {
      const fullPath = path.join(directory, file.name);
      if (file.isDirectory()) {
        // Recursively search subdirectories
        elFiles = elFiles.concat(getElispFiles(fullPath));
      } else if (file.name.endsWith('.el')) {
        elFiles.push(fullPath);
      }
    }
    
    return elFiles;
  } catch (error) {
    console.error(`Error reading directory ${directory}: ${error.message}`);
    process.exit(1);
  }
}

// Helper function to process parinfer result
function processResult(result, filePath, mode) {
  if (result.success) {
    return result;
  } else {
    console.error(`Error in ${filePath} (${mode} mode):`);
    if (result.error) {
      console.error(`  ${result.error.name}: ${result.error.message}`);
      if (result.error.lineNo !== undefined) {
        console.error(`  Line: ${result.error.lineNo + 1}, Column: ${result.error.x + 1}`);
      }
    }
    return null;
  }
}

// Helper function to attempt auto-repair of structural issues
function attemptAutoRepair(content, filePath) {
  console.log(`Attempting to auto-repair structural issues in ${filePath}...`);
  
  // Try indent mode first - it's most aggressive at fixing missing parens
  let repairResult = parinfer.indentMode(content);
  
  if (repairResult.success) {
    console.log(`✓ Auto-repair successful using indent mode`);
    return repairResult.text;
  }
  
  // If indent mode fails, try smart mode
  repairResult = parinfer.smartMode(content);
  
  if (repairResult.success) {
    console.log(`✓ Auto-repair successful using smart mode`);
    return repairResult.text;
  }
  
  // If both fail, try some basic structural repairs manually
  console.log(`Parinfer modes failed, attempting manual structural repairs...`);
  
  let repairedContent = content;
  
  // Count opening and closing parens
  const openParens = (repairedContent.match(/\(/g) || []).length;
  const closeParens = (repairedContent.match(/\)/g) || []).length;
  
  if (openParens > closeParens) {
    // Add missing closing parens at the end
    const missingParens = openParens - closeParens;
    console.log(`Adding ${missingParens} missing closing parentheses...`);
    repairedContent += ')'.repeat(missingParens);
    
    // Try parinfer again after adding missing parens
    const retryResult = parinfer.indentMode(repairedContent);
    if (retryResult.success) {
      console.log(`✓ Manual repair successful`);
      return retryResult.text;
    }
  } else if (closeParens > openParens) {
    console.log(`Warning: More closing parens than opening parens. This requires manual intervention.`);
  }
  
  console.log(`✗ Auto-repair failed. Manual intervention required.`);
  return null;
}

// Enhanced function to format with auto-repair capability
function formatWithAutoRepair(content, filePath, mode, options = {}) {
  let result;
  let formattedText;
  
  // First, try the requested mode directly
  switch (mode) {
    case 'indent':
      result = parinfer.indentMode(content);
      break;
    case 'paren':
      result = parinfer.parenMode(content);
      break;
    case 'smart':
      result = parinfer.smartMode(content);
      break;
    case 'elisp':
      result = parinfer.smartMode(content);
      break;
    default:
      throw new Error(`Unknown mode: ${mode}`);
  }
  
  // If successful, apply any additional formatting
  if (result.success) {
    formattedText = (mode === 'elisp') ? applyElispFormatting(result.text) : result.text;
    return { success: true, text: formattedText, wasRepaired: false };
  }
  
  // If failed and auto-repair is enabled, attempt repair
  if (options.autoRepair !== false) { // Default to true unless explicitly disabled
    const repairedContent = attemptAutoRepair(content, filePath);
    
    if (repairedContent) {
      // Try formatting the repaired content
      switch (mode) {
        case 'indent':
          result = parinfer.indentMode(repairedContent);
          break;
        case 'paren':
          result = parinfer.parenMode(repairedContent);
          break;
        case 'smart':
          result = parinfer.smartMode(repairedContent);
          break;
        case 'elisp':
          result = parinfer.smartMode(repairedContent);
          break;
      }
      
      if (result.success) {
        formattedText = (mode === 'elisp') ? applyElispFormatting(result.text) : result.text;
        return { success: true, text: formattedText, wasRepaired: true };
      }
    }
  }
  
  // If all attempts failed, return the original error
  return { success: false, error: result.error, wasRepaired: false };
}

// Check command
program
  .command('check')
  .description('Check if S-expressions are balanced (validation only, no formatting)')
  .argument('<file>', 'Elisp file to validate')
  .addHelpText('after', `
Validates that parentheses are properly balanced without making any changes.
Exit code 0 = balanced, 1 = unbalanced or errors found.`)
  .action((file) => {
    const content = readFile(file);
    const result = parinfer.parenMode(content);
    
    if (result.success) {
      console.log(`✓ ${file}: S-expressions are balanced`);
      process.exit(0);
    } else {
      console.error(`✗ ${file}: S-expressions are not balanced`);
      if (result.error) {
        console.error(`  Error: ${result.error.message}`);
        if (result.error.lineNo !== undefined) {
          console.error(`  Line: ${result.error.lineNo + 1}, Column: ${result.error.x + 1}`);
        }
      }
      process.exit(1);
    }
  });

// Indent command
program
  .command('indent')
  .description('Format using Indent Mode (indentation drives structure, aggressive paren fixing)')
  .argument('<file>', 'Elisp file to format')
  .option('-s, --stdout', 'Output formatted content to stdout instead of modifying file')
  .option('-c, --check', 'Check if file needs formatting without making changes (exit code 1 if changes needed)')
  .option('--no-auto-repair', 'Disable automatic repair of structural issues like missing parentheses')
  .addHelpText('after', `
Indent Mode lets indentation drive the structure. It will automatically add
missing closing parentheses based on indentation levels. Most aggressive
at fixing structural issues.`)
  .action((file, options) => {
    const content = readFile(file);
    const result = formatWithAutoRepair(content, file, 'indent', { autoRepair: options.autoRepair });
    
    if (!result.success) {
      console.error(`✗ ${file}: Failed to format`);
      if (result.error) {
        console.error(`  Error: ${result.error.message}`);
        if (result.error.lineNo !== undefined) {
          console.error(`  Line: ${result.error.lineNo + 1}, Column: ${result.error.x + 1}`);
        }
      }
      process.exit(1);
    }
    
    if (result.wasRepaired) {
      console.log(`⚠ ${file}: Structural issues were automatically repaired`);
    }
    
    if (options.check) {
      if (content !== result.text) {
        console.log(`File ${file} needs formatting`);
        process.exit(1);
      } else {
        console.log(`File ${file} is already formatted`);
        process.exit(0);
      }
    }
    
    if (options.stdout) {
      process.stdout.write(result.text);
    } else {
      if (content !== result.text) {
        writeFile(file, result.text);
        console.log(`✓ Formatted ${file}`);
      } else {
        console.log(`✓ ${file} already formatted`);
      }
    }
  });

// Paren command
program
  .command('paren')
  .description('Format using Paren Mode (preserves parentheses, adjusts indentation)')
  .argument('<file>', 'Elisp file to format')
  .option('-s, --stdout', 'Output formatted content to stdout instead of modifying file')
  .option('-c, --check', 'Check if file needs formatting without making changes (exit code 1 if changes needed)')
  .option('--no-auto-repair', 'Disable automatic repair of structural issues like missing parentheses')
  .addHelpText('after', `
Paren Mode preserves existing parentheses and adjusts indentation to match.
Best when you trust your parentheses are correct and just want proper
indentation.`)
  .action((file, options) => {
    const content = readFile(file);
    const result = formatWithAutoRepair(content, file, 'paren', { autoRepair: options.autoRepair });
    
    if (!result.success) {
      console.error(`✗ ${file}: Failed to format`);
      if (result.error) {
        console.error(`  Error: ${result.error.message}`);
        if (result.error.lineNo !== undefined) {
          console.error(`  Line: ${result.error.lineNo + 1}, Column: ${result.error.x + 1}`);
        }
      }
      process.exit(1);
    }
    
    if (result.wasRepaired) {
      console.log(`⚠ ${file}: Structural issues were automatically repaired`);
    }
    
    if (options.check) {
      if (content !== result.text) {
        console.log(`File ${file} needs formatting`);
        process.exit(1);
      } else {
        console.log(`File ${file} is already formatted`);
        process.exit(0);
      }
    }
    
    if (options.stdout) {
      process.stdout.write(result.text);
    } else {
      if (content !== result.text) {
        writeFile(file, result.text);
        console.log(`✓ Formatted ${file}`);
      } else {
        console.log(`✓ ${file} already formatted`);
      }
    }
  });

// Smart command
program
  .command('smart')
  .description('Format using Smart Mode (intelligent hybrid of indent and paren modes)')
  .argument('<file>', 'Elisp file to format')
  .option('-s, --stdout', 'Output formatted content to stdout instead of modifying file')
  .option('-c, --check', 'Check if file needs formatting without making changes (exit code 1 if changes needed)')
  .option('--no-auto-repair', 'Disable automatic repair of structural issues like missing parentheses')
  .addHelpText('after', `
Smart Mode intelligently combines indent and paren modes. It makes smart
decisions about when to fix parentheses vs. when to preserve them.
Recommended for most general-purpose formatting.`)
  .action((file, options) => {
    const content = readFile(file);
    const result = formatWithAutoRepair(content, file, 'smart', { autoRepair: options.autoRepair });
    
    if (!result.success) {
      console.error(`✗ ${file}: Failed to format`);
      if (result.error) {
        console.error(`  Error: ${result.error.message}`);
        if (result.error.lineNo !== undefined) {
          console.error(`  Line: ${result.error.lineNo + 1}, Column: ${result.error.x + 1}`);
        }
      }
      process.exit(1);
    }
    
    if (result.wasRepaired) {
      console.log(`⚠ ${file}: Structural issues were automatically repaired`);
    }
    
    if (options.check) {
      if (content !== result.text) {
        console.log(`File ${file} needs formatting`);
        process.exit(1);
      } else {
        console.log(`File ${file} is already formatted`);
        process.exit(0);
      }
    }
    
    if (options.stdout) {
      process.stdout.write(result.text);
    } else {
      if (content !== result.text) {
        writeFile(file, result.text);
        console.log(`✓ Formatted ${file}`);
      } else {
        console.log(`✓ ${file} already formatted`);
      }
    }
  });

// Apply Elisp-specific formatting rules
function applyElispFormatting(text) {
  let formattedText = text;
  
  // Fix function definitions where parameters are on separate lines
  // This handles cases like:
  // (defun my/function
  //   ()
  // and turns them into:
  // (defun my/function ()
  formattedText = formattedText.replace(
    /(\(defun\s+[^\s\(\)]+)\s*\n\s*(\([^\)]*\))/g,
    '$1 $2'
  );
  
  // Fix other definition forms similarly
  formattedText = formattedText.replace(
    /(\(def(?:macro|var|custom|group|face)\s+[^\s\(\)]+)\s*\n\s*(\([^\)]*\)|[^\s\(\)]+)/g,
    '$1 $2'
  );
  
  // Ensure proper spacing after opening parens for common Elisp forms
  // Using a safer approach that only adds space when there's immediately a non-whitespace character
  // but never splits existing words or tokens
  const elispForms = [
    'defun', 'defmacro', 'defvar', 'defcustom', 'defgroup', 'defface', 
    'lambda', 'let', 'let\\*', 'when', 'unless', 'if', 'cond', 
    'condition-case', 'case', 'progn', 'save-excursion', 
    'save-window-excursion', 'with-current-buffer', 'while', 'dolist', 'dotimes'
  ];
  
  // Process each form individually to ensure no word-splitting occurs
  for (const form of elispForms) {
    // Only match complete words (word boundaries) followed immediately by a non-space character
    const regex = new RegExp(`\\(${form}\\b([^\\s])`, 'g');
    formattedText = formattedText.replace(regex, `(${form.replace(/\\\\/g, '')} $1`);
  }
  
  // Preserve meaningful whitespace while cleaning up excessive spaces
  // 1. Remove trailing spaces from lines but preserve the newlines
  formattedText = formattedText.replace(/[ \t]+$/gm, '');
  
  // 2. Normalize whitespace: preserve single blank lines, reduce excessive blank lines
  // This preserves intentional spacing between code blocks while removing excessive whitespace
  formattedText = formattedText.replace(/\n{4,}/g, '\n\n\n'); // Max 2 blank lines between blocks
  
  // 3. Clean up any trailing whitespace at the very end of the file
  formattedText = formattedText.replace(/\s+$/, '\n');
  
  // 4. Ensure file doesn't start with blank lines
  formattedText = formattedText.replace(/^\n+/, '');
  
  return formattedText;
}

// Elisp command (custom rules for Elisp)
program
  .command('elisp')
  .description('Format specifically for Elisp with custom rules (RECOMMENDED for .el files)')
  .argument('<file>', 'Elisp file to format')
  .option('-s, --stdout', 'Output formatted content to stdout instead of modifying file')
  .option('-c, --check', 'Check if file needs formatting without making changes (exit code 1 if changes needed)')
  .option('--no-auto-repair', 'Disable automatic repair of structural issues like missing parentheses')
  .addHelpText('after', `
Elisp Mode combines Smart Mode with specialized Elisp formatting rules:
• Proper spacing for defun, defvar, let, condition-case, etc.
• Function parameter alignment
• Elisp-specific indentation conventions
• Whitespace cleanup and normalization

This is the recommended mode for Emacs Lisp files.`)
  .action((file, options) => {
    const content = readFile(file);
    const result = formatWithAutoRepair(content, file, 'elisp', { autoRepair: options.autoRepair });
    
    if (!result.success) {
      console.error(`✗ ${file}: Failed to format`);
      if (result.error) {
        console.error(`  Error: ${result.error.message}`);
        if (result.error.lineNo !== undefined) {
          console.error(`  Line: ${result.error.lineNo + 1}, Column: ${result.error.x + 1}`);
        }
      }
      process.exit(1);
    }
    
    if (result.wasRepaired) {
      console.log(`⚠ ${file}: Structural issues were automatically repaired`);
    }
    
    if (options.check) {
      if (content !== result.text) {
        console.log(`File ${file} needs formatting`);
        process.exit(1);
      } else {
        console.log(`File ${file} is already formatted`);
        process.exit(0);
      }
    }
    
    if (options.stdout) {
      process.stdout.write(result.text);
    } else {
      if (content !== result.text) {
        writeFile(file, result.text);
        console.log(`✓ Formatted ${file}`);
      } else {
        console.log(`✓ ${file} already formatted`);
      }
    }
  });

// Batch command
program
  .command('batch')
  .description('Process all .el files in directory (recursively scans subdirectories)')
  .argument('<directory>', 'Directory to scan for .el files')
  .option('-m, --mode <mode>', 'Formatting mode: check|indent|paren|smart|elisp (default: elisp)', 'elisp')
  .option('-c, --check', 'Check if files need formatting without making changes (validation mode)')
  .option('-s, --stdout', 'Output all formatted content to stdout instead of modifying files')
  .option('--no-auto-repair', 'Disable automatic repair of structural issues like missing parentheses')
  .addHelpText('after', `
Batch processing recursively finds all .el files in the specified directory
and applies the chosen formatting mode to each one.

Formatting modes:
  elisp   - Elisp-specific rules (recommended)
  smart   - Intelligent hybrid mode
  indent  - Indentation-driven (aggressive paren fixing)
  paren   - Parentheses-driven (preserve existing parens)

Examples:
  elisp-formatter batch ./config                    # Format all files with elisp mode
  elisp-formatter batch ./config --check            # Validate without changes
  elisp-formatter batch ./config --mode smart       # Use smart mode
  elisp-formatter batch ./config --stdout | less    # Preview changes`)
  .action((directory, options) => {
    const elFiles = getElispFiles(directory);
    
    if (elFiles.length === 0) {
      console.log(`No .el files found in ${directory}`);
      return;
    }
    
    console.log(`Found ${elFiles.length} .el files in ${directory}`);
    
    let needsFormatting = [];
    let hasErrors = false;
    let repaired = [];
    
    for (const file of elFiles) {
      const content = readFile(file);
      const formattingResult = formatWithAutoRepair(content, file, options.mode, { autoRepair: options.autoRepair });
      
      if (!formattingResult.success) {
        console.error(`✗ ${file}: Failed to format`);
        if (formattingResult.error) {
          console.error(`  Error: ${formattingResult.error.message}`);
          if (formattingResult.error.lineNo !== undefined) {
            console.error(`  Line: ${formattingResult.error.lineNo + 1}, Column: ${formattingResult.error.x + 1}`);
          }
        }
        hasErrors = true;
        continue;
      }
      
      if (formattingResult.wasRepaired) {
        repaired.push(file);
      }
      
      if (content !== formattingResult.text) {
        needsFormatting.push(file);
        
        if (options.check) {
          console.log(`- ${file} needs formatting`);
        } else if (options.stdout) {
          console.log(`\n=== ${file} ===`);
          process.stdout.write(formattingResult.text);
          console.log(`\n=== End ${file} ===\n`);
        } else {
          writeFile(file, formattingResult.text);
          console.log(`✓ Formatted ${file}`);
        }
      } else {
        if (!options.check) {
          console.log(`✓ ${file} already formatted`);
        }
      }
    }
    
    if (repaired.length > 0 && !options.check && !options.stdout) {
      console.log(`\n⚠ ${repaired.length} files were automatically repaired:`);
      repaired.forEach(file => console.log(`  - ${file}`));
    }
    
    if (hasErrors) {
      console.error('\nSome files had errors and could not be processed.');
      process.exit(1);
    }
    
    if (options.check && needsFormatting.length > 0) {
      console.log(`\n${needsFormatting.length} files need formatting`);
      process.exit(1);
    }
    
    if (needsFormatting.length === 0) {
      console.log('\nAll files are properly formatted!');
    } else if (!options.check && !options.stdout) {
      console.log(`\nFormatted ${needsFormatting.length} files`);
    }
  });

program.parse();
