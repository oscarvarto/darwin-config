#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { Command } = require('commander');
const parinfer = require('parinfer');

const program = new Command();

// Package version
const packageJson = require('./package.json');

program
  .name('elisp-formatter.js')
  .description('Check and format Elisp S-expressions using Parinfer')
  .version(packageJson.version || '1.0.0');

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

// Check command
program
  .command('check')
  .description('Check if S-expressions are balanced')
  .argument('<file>', 'File to check')
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
  .description('Format using Indent Mode (indentation drives structure)')
  .argument('<file>', 'File to format')
  .option('-w, --write', 'Write changes to file instead of stdout')
  .option('-c, --check', 'Check if file needs formatting (exit code 1 if changes needed)')
  .action((file, options) => {
    const content = readFile(file);
    const result = parinfer.indentMode(content);
    
    const processed = processResult(result, file, 'indent');
    if (!processed) {
      process.exit(1);
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
    
    if (options.write) {
      if (content !== result.text) {
        writeFile(file, result.text);
        console.log(`Formatted ${file}`);
      } else {
        console.log(`${file} already formatted`);
      }
    } else {
      process.stdout.write(result.text);
    }
  });

// Paren command
program
  .command('paren')
  .description('Format using Paren Mode (parentheses drive structure)')
  .argument('<file>', 'File to format')
  .option('-w, --write', 'Write changes to file instead of stdout')
  .option('-c, --check', 'Check if file needs formatting (exit code 1 if changes needed)')
  .action((file, options) => {
    const content = readFile(file);
    const result = parinfer.parenMode(content);
    
    const processed = processResult(result, file, 'paren');
    if (!processed) {
      process.exit(1);
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
    
    if (options.write) {
      if (content !== result.text) {
        writeFile(file, result.text);
        console.log(`Formatted ${file}`);
      } else {
        console.log(`${file} already formatted`);
      }
    } else {
      process.stdout.write(result.text);
    }
  });

// Smart command
program
  .command('smart')
  .description('Format using Smart Mode (intelligent hybrid)')
  .argument('<file>', 'File to format')
  .option('-w, --write', 'Write changes to file instead of stdout')
  .option('-c, --check', 'Check if file needs formatting (exit code 1 if changes needed)')
  .action((file, options) => {
    const content = readFile(file);
    const result = parinfer.smartMode(content);
    
    const processed = processResult(result, file, 'smart');
    if (!processed) {
      process.exit(1);
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
    
    if (options.write) {
      if (content !== result.text) {
        writeFile(file, result.text);
        console.log(`Formatted ${file}`);
      } else {
        console.log(`${file} already formatted`);
      }
    } else {
      process.stdout.write(result.text);
    }
  });

// Elisp command (custom rules for Elisp)
program
  .command('elisp')
  .description('Format specifically for Elisp with custom rules')
  .argument('<file>', 'File to format')
  .option('-w, --write', 'Write changes to file instead of stdout')
  .option('-c, --check', 'Check if file needs formatting (exit code 1 if changes needed)')
  .action((file, options) => {
    const content = readFile(file);
    
    // For Elisp, we'll use smart mode with some additional processing
    let result = parinfer.smartMode(content);
    
    const processed = processResult(result, file, 'elisp');
    if (!processed) {
      process.exit(1);
    }
    
    // Apply Elisp-specific formatting rules
    let formattedText = result.text;
    
    // Ensure proper spacing around certain forms
    formattedText = formattedText
      // Add space after opening parens for common Elisp forms
      .replace(/\((defun|defmacro|defvar|defcustom|defgroup|defface|lambda|let|let\*|when|unless|if|cond|case|progn|save-excursion|save-window-excursion|with-current-buffer)([^\s])/g, '($1 $2')
      // Ensure newlines after certain opening forms
      .replace(/\((defun|defmacro|defvar|defcustom|defgroup|defface)\s+([^\s\)]+)\s*([^\n]*)/g, (match, form, name, rest) => {
        if (rest.trim() && !rest.startsWith('\n')) {
          return `(${form} ${name}\n  ${rest.trim()}`;
        }
        return match;
      });
    
    if (options.check) {
      if (content !== formattedText) {
        console.log(`File ${file} needs formatting`);
        process.exit(1);
      } else {
        console.log(`File ${file} is already formatted`);
        process.exit(0);
      }
    }
    
    if (options.write) {
      if (content !== formattedText) {
        writeFile(file, formattedText);
        console.log(`Formatted ${file}`);
      } else {
        console.log(`${file} already formatted`);
      }
    } else {
      process.stdout.write(formattedText);
    }
  });

// Batch command
program
  .command('batch')
  .description('Process all .el files in directory')
  .argument('<directory>', 'Directory to process')
  .option('-m, --mode <mode>', 'Formatting mode to use', 'smart')
  .option('-w, --write', 'Write changes to files instead of just checking')
  .option('-c, --check', 'Check if files need formatting (exit code 1 if any changes needed)')
  .action((directory, options) => {
    const elFiles = getElispFiles(directory);
    
    if (elFiles.length === 0) {
      console.log(`No .el files found in ${directory}`);
      return;
    }
    
    console.log(`Found ${elFiles.length} .el files in ${directory}`);
    
    let needsFormatting = [];
    let hasErrors = false;
    
    for (const file of elFiles) {
      const content = readFile(file);
      let result;
      
      // Choose the formatting mode
      switch (options.mode) {
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
          // Apply Elisp-specific rules (simplified version)
          if (result.success) {
            result.text = result.text
              .replace(/\((defun|defmacro|defvar|defcustom|defgroup|defface|lambda|let|let\*|when|unless|if|cond|case|progn|save-excursion|save-window-excursion|with-current-buffer)([^\s])/g, '($1 $2');
          }
          break;
        default:
          console.error(`Unknown mode: ${options.mode}`);
          process.exit(1);
      }
      
      const processed = processResult(result, file, options.mode);
      if (!processed) {
        hasErrors = true;
        continue;
      }
      
      if (content !== result.text) {
        needsFormatting.push(file);
        
        if (options.write) {
          writeFile(file, result.text);
          console.log(`✓ Formatted ${file}`);
        } else {
          console.log(`- ${file} needs formatting`);
        }
      } else {
        if (!options.check) {
          console.log(`✓ ${file} already formatted`);
        }
      }
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
    } else if (options.write) {
      console.log(`\nFormatted ${needsFormatting.length} files`);
    }
  });

program.parse();

