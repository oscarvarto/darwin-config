# Mill Build Support for Clojure in Doom Emacs

This documentation explains how to enhance your Doom Emacs configuration to support Clojure projects using the Mill build tool. While Mill lacks native Clojure support, this implementation provides a custom module that extends Mill's capabilities to handle Clojure code.

## Overview

This integration provides:

1. A custom **ClojureModule** trait for Mill that extends JavaModule
2. Enhanced Doom Emacs configuration for Mill+Clojure support
3. CIDER integration for Mill-based Clojure projects
4. Automatic JDK selection that respects your existing setup

## Files Included

- `mill-clojure-module.sc` - The custom ClojureModule trait for Mill
- `mill-clojure-config.el` - Emacs Lisp configuration for Mill+Clojure integration
- `mill-lsp-java-config.el` - Enhanced LSP Java configuration for Mill+Clojure projects
- `MILL-CLOJURE-README.md` - This documentation file

## Installation

### 1. Set Up the Mill ClojureModule

Copy the `mill-clojure-module.sc` file to your project or to a common location where it can be imported in your Mill build files.

### 2. Update Your Doom Emacs Configuration

There are two ways to integrate the Mill Clojure support into your Doom Emacs configuration:

#### Option 1: Use the provided files directly

1. Add the following to your `config.el`:

```elisp
;; Load Mill Clojure support
(load! "mill-clojure-config")
(load! "mill-lsp-java-config")
```

#### Option 2: Integrate into your existing configuration files

1. Copy the relevant parts from `mill-clojure-config.el` into your existing `my-clojure-config.el`
2. Copy the relevant parts from `mill-lsp-java-config.el` into your existing `my-lsp-java-config.el`

## Project Structure

A typical Mill Clojure project structure:

```
my-project/
├── build.mill            # Mill build file with ClojureModule
├── module/
│   ├── src/
│   │   ├── java/         # Java sources (optional)
│   │   └── clojure/      # Clojure sources
│   │       └── myapp/
│   │           ├── core.clj
│   │           └── utils.clj
│   └── test/
│       ├── java/         # Java tests (optional)
│       └── clojure/      # Clojure tests
│           └── myapp/
│               └── core_test.clj
└── .mill-version         # (Optional) Specify Mill version
```

## Example build.mill File

```scala
// Import the ClojureModule trait
import $file.mill_clojure_module
import mill_clojure_module._

// Define your project module
object myapp extends ClojureModule {
  // Override the default Clojure version if needed
  override def clojureVersion = "1.11.1"
  
  // Add your project-specific dependencies
  override def ivyDeps = super.ivyDeps() ++ Agg(
    ivy"org.clojure:core.async:1.6.673",
    ivy"nrepl:nrepl:1.0.0",         // For CIDER integration
    ivy"cider:cider-nrepl:0.28.7",  // For CIDER integration
    ivy"compojure:compojure:1.7.0"  // Example web framework
  )
  
  // Override source directories if using a non-standard layout
  // override def clojureSourceDirectories = T.sources(millSourcePath / "src" / "clj")
  
  // Define test module
  object test extends ClojureTests with TestModule.Junit5 {
    // Additional test dependencies
    def ivyDeps = super.ivyDeps() ++ Agg(
      ivy"io.github.cognitect-labs:test-runner:0.5.1"
    )
  }
}

// Add this trait for ClojureTests support
trait ClojureTests extends TestModule {
  // Test-specific settings
}
```

## Usage in Doom Emacs

### Key Bindings

The integration adds these key bindings:

- `SPC m r` - Run a Clojure REPL using Mill
- `SPC m t` - Run Clojure tests using Mill
- `SPC m m` - Run a Clojure main namespace using Mill
- `SPC m c` - Connect CIDER to a Mill-based nREPL server
- `SPC c M` - Same as `SPC m c` (under the CIDER prefix)
- `C-c C-b` - Compile the current JVM project (enhanced to detect Clojure+Mill projects)

### CIDER Integration

When in a Mill Clojure project:

1. Use `SPC m c` to start an nREPL server using Mill and connect CIDER to it
2. Standard CIDER commands like `cider-jack-in` are automatically redirected to use Mill

### JDK Integration

This implementation integrates with your existing JDK configuration system:

1. JDK selection follows your priority order (direnv, .java-version, build detection)
2. The correct JDK is automatically used for Mill build commands and CIDER connections

## Troubleshooting

### nREPL Connection Issues

- Make sure your `build.mill` file includes the necessary nREPL dependencies:
  ```scala
  override def ivyDeps = super.ivyDeps() ++ Agg(
    ivy"nrepl:nrepl:1.0.0",
    ivy"cider:cider-nrepl:0.28.7"
  )
  ```

- Check the nREPL port in the `*mill-clojure-nrepl*` buffer
- Verify that port 7888 is not already in use by another process

### Compilation Problems

- For AOT compilation issues, check the module implementation in `mill-clojure-module.sc`
- For projects with both Java and Clojure code, ensure proper namespace declarations

### Custom Directory Structure

If your project uses a non-standard directory structure:

```scala
// In your build.mill file
override def clojureSourceDirectories = T.sources(
  millSourcePath / "src" / "clj", 
  millSourcePath / "src" / "cljc"
)
```

## Extending the Implementation

You can extend this implementation in several ways:

1. Enhance the `ClojureModule` trait with additional tasks
2. Add support for ClojureScript via a similar approach
3. Improve the AOT compilation support for better performance
4. Add REPL-driven development tools specific to Mill

## Further Reading

- [Mill Build Tool Documentation](https://mill-build.com/mill/Intro_to_Mill.html)
- [Clojure Documentation](https://clojure.org/guides/getting_started)
- [CIDER Documentation](https://docs.cider.mx)
