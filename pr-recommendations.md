# Recommendations for Jank Homebrew PR #7

## Executive Summary

Your PR addresses real Nix+macOS SDK conflicts but uses fragile workarounds. The maintainer correctly identified that platform-specific logic should live in jank itself, not Homebrew formulas. Here's a roadmap to make your PR professional and upstream-friendly.

---

## Critical Issues & Solutions

### 1. **Fragile CMakeLists.txt String Patching** 🔴 HIGH PRIORITY

**Current Problem:**
```ruby
s.sub!(
  "separate_arguments(clang_system_include_dirs)\n\nset(clang_system_include_flags \"\")",
  <<~'CMAKE'.chomp
    # ... replacement code
  CMAKE
)
```

This breaks if upstream:
- Reorders code
- Changes whitespace
- Adds comments

**Recommended Solution:**
Create a **patch file** instead of inline string substitution:

```ruby
# In the formula:
def install
  # Apply patches
  if OS.mac?
    # Apply patches for macOS SDK path handling
    patch do
      url "https://raw.githubusercontent.com/oscarvarto/homebrew-jank/main/patches/macos-sdk-paths.patch"
      sha256 "abc123..."
    end
  end
  # ... rest of install
end
```

**Better Yet - Upstream Fix:**
Propose these CMake improvements to jank directly:

```cmake
# In CMakeLists.txt - add platform-aware path filtering
if(APPLE)
  # Filter out SDK paths that should come from -isysroot
  list(FILTER clang_system_include_dirs EXCLUDE REGEX "/SDKs/")

  # Skip system lib defaults
  foreach(lib ${jank_lib_link_dirs_prop})
    if(NOT lib IN_LIST "/lib;/usr/lib;")
      list(APPEND jank_lib_linker_flags_list -L${lib})
    endif()
  endforeach()
else()
  # Original Linux behavior
  foreach(lib ${jank_lib_link_dirs_prop})
    list(APPEND jank_lib_linker_flags_list -L${lib})
  endforeach()
endif()
```

---

### 2. **Platform-Specific Linker Flags in C++ Source** 🔴 HIGH PRIORITY

**Current Problem:**
The formula patches `processor.cpp` to conditionally exclude `-lstdc++` on macOS using C preprocessor directives.

**Recommended Solution:**
Fix this **in jank's CMake** instead:

```cmake
# In CMakeLists.txt (around where linker flags are configured)

# Default libraries that jank depends on
set(JANK_DEFAULT_LIBS
  "-ljank-standalone"
  "-lm"
  "-lLLVM"
  "-lclang-cpp"
  "-lcrypto"
  "-lz"
  "-lzstd"
)

# Platform-specific standard library linking
if(NOT APPLE)
  # Only link libstdc++ explicitly on non-Apple platforms
  # (macOS uses libc++ implicitly via Clang)
  list(APPEND JANK_DEFAULT_LIBS "-lstdc++")
endif()

# Generate the C++ array at configure time
set(DEFAULT_LIBS_INITIALIZER "")
foreach(lib ${JANK_DEFAULT_LIBS})
  set(DEFAULT_LIBS_INITIALIZER "${DEFAULT_LIBS_INITIALIZER}    \"${lib}\",\n")
endforeach()

configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/src/cpp/jank/aot/processor.cpp.in
  ${CMAKE_CURRENT_BINARY_DIR}/src/cpp/jank/aot/processor.cpp
  @ONLY
)
```

Then create `processor.cpp.in`:
```cpp
for(auto const &lib : {
@DEFAULT_LIBS_INITIALIZER@
})
{
    compiler_args.push_back(strdup(lib));
}
```

**Why This is Better:**
- No runtime preprocessor checks
- Platform logic lives in the build system (where it belongs)
- Easier to maintain and extend
- No fragile string matching in Homebrew formula

---

### 3. **LLVM Version Dependency** 🟡 MEDIUM PRIORITY

**Current Conflict:**
- PR changed: `llvm@21` → `llvm`
- Maintainer says: jank needs `llvm@head` (LLVM 22)
- Your formula uses: `Formula["llvm"]` (currently LLVM 19 in Homebrew)

**Recommended Approach:**

Check jank's actual LLVM requirements:
```bash
# In jank's CMakeLists.txt, look for:
find_package(LLVM <VERSION> REQUIRED)
```

Then align the formula:

**Option A - If jank supports LLVM 18-22:**
```ruby
depends_on "llvm" # Use whatever Homebrew provides
```

**Option B - If jank needs bleeding-edge LLVM:**
```ruby
depends_on "llvm" => :HEAD
```

**Option C - If jank needs specific LLVM 21:**
```ruby
depends_on "llvm@21"
```

**Action Required:**
1. Ask the maintainer (jeaye) what the **minimum** and **maximum** LLVM versions are
2. Update jank's CMakeLists.txt to enforce version constraints
3. Document this in the formula

---

### 4. **Nix Environment Variable Handling** 🟢 LOW PRIORITY (Already Good)

Your wrapper approach is actually **correct** for this use case:

```ruby
(bin/"jank").write <<~SH
  #!/usr/bin/env bash
  set -euo pipefail
  unset SDKROOT
  unset NIX_CFLAGS_COMPILE
  # ... etc
  exec "#{libexec_bin/"jank"}" "$@"
SH
```

**Why:**
- Nix pollution is a **runtime environment issue**, not a build issue
- Homebrew formulas commonly use wrappers to isolate from environment variables
- This pattern is used by other Homebrew formulas dealing with Nix

**Keep this as-is**, but consider adding a comment:
```ruby
# Isolate from Nix environment variables that interfere with JIT compilation.
# Nix's SDK paths can conflict with the SDK jank was built against.
```

---

## Proposed Action Plan

### Phase 1: Upstream Fixes (Submit to jank-lang/jank)
1. **Create PR #1:** Platform-aware linker flags in CMake
   - Move `-lstdc++` logic from C++ to CMake
   - Use `configure_file()` to generate processor.cpp

2. **Create PR #2:** macOS SDK path filtering
   - Add `if(APPLE)` blocks to filter SDK paths from system includes
   - Add logic to skip `/lib`, `/usr/lib` on macOS

3. **Create PR #3:** Document LLVM version requirements
   - Add `find_package(LLVM 21...<NONE> REQUIRED)` or similar
   - Update README with supported LLVM versions

### Phase 2: Simplified Homebrew Formula
Once upstream changes are merged:

```ruby
class JankGit < Formula
  desc "The native Clojure dialect hosted on LLVM"
  homepage "https://jank-lang.org"
  url "https://github.com/jank-lang/jank.git", branch: "main"
  version "0.1"
  license "MPL-2.0"

  depends_on "cmake" => :build
  depends_on "git-lfs" => :build
  depends_on "ninja" => :build
  depends_on "boost"
  depends_on "libzip"
  depends_on "llvm@21"  # Or whatever version is confirmed
  depends_on "openssl"

  def install
    llvm = Formula["llvm@21"]

    # Standard LLVM configuration
    ENV.prepend_path "PATH", llvm.opt_bin
    ENV["CC"] = llvm.opt_bin/"clang"
    ENV["CXX"] = llvm.opt_bin/"clang++"

    # macOS SDK configuration
    if OS.mac?
      ENV["SDKROOT"] = Utils.safe_popen_read("/usr/bin/xcrun", "--sdk", "macosx", "--show-sdk-path").strip
    end

    # Build configuration
    cd "compiler+runtime"
    system "./bin/configure",
           "-GNinja",
           *std_cmake_args,
           "-DHOMEBREW_ALLOW_FETCHCONTENT=ON",
           "-DCMAKE_CXX_COMPILER=#{llvm.opt_bin}/clang++",
           "-DCMAKE_C_COMPILER=#{llvm.opt_bin}/clang"

    system "./bin/compile"
    system "./bin/install"

    # Create wrapper to isolate from Nix environment
    libexec_bin = libexec/"bin"
    libexec_bin.install bin/"jank"
    (bin/"jank").write <<~SH
      #!/usr/bin/env bash
      set -euo pipefail
      # Isolate from Nix environment variables
      unset SDKROOT HOMEBREW_SDKROOT MACOSX_DEPLOYMENT_TARGET
      unset NIX_CFLAGS_COMPILE NIX_LDFLAGS NIX_APPLE_SDK_VERSION
      exec "#{libexec_bin/"jank"}" "$@"
    SH
    (bin/"jank").chmod 0755
    ln_s lib, libexec/"lib", force: true
  end

  test do
    assert_predicate bin/"jank", :exist?
    assert_predicate bin/"jank", :executable?
    assert_match "jank can aot compile working binaries",
                 pipe_output("#{bin/"jank"} check-health")
  end
end
```

**Size reduction:** 180 lines → ~60 lines (67% smaller!)

---

## How to Engage with the Maintainer

### Recommended Response to PR Comments:

```markdown
Hi @jeaye, thanks for the feedback! You're absolutely right that this formula has too many
fragile workarounds. I'd like to propose moving the platform-specific logic upstream to jank
itself. Here's my plan:

**1. Platform-specific linker flags:**
I'll create a PR to jank that uses CMake's `configure_file()` to generate the linker flags
in processor.cpp at build time, using `if(APPLE)` to exclude `-lstdc++` on macOS.

**2. SDK path filtering:**
I'll add macOS-specific logic to CMakeLists.txt to filter SDK paths from system includes,
since these should come from `-isysroot` rather than explicit `-I` flags.

**3. LLVM version:**
Could you clarify what LLVM versions jank supports? The code currently works with LLVM 19-21
in my testing, but I want to ensure we document this properly. Should we add a minimum version
check in CMakeLists.txt?

I'll keep the Nix environment isolation wrapper, as that's a legitimate runtime concern for
users with Nix installed.

Once these upstream changes are merged, I'll update this PR with a much simpler formula.
```

---

## Testing Strategy

### Before submitting upstream PRs:
```bash
# Test on macOS with Nix installed
cd /path/to/jank
mkdir build && cd build
cmake -GNinja -DCMAKE_BUILD_TYPE=Release ../compiler+runtime
ninja
./jank check-health

# Test on macOS without Nix (clean environment)
docker run --rm -it homebrew/brew:latest
brew install --HEAD oscarvarto/jank/jank-git

# Test on Linux
docker run --rm -it ubuntu:22.04
# Install dependencies and build
```

### Regression testing:
```bash
# Ensure the changes don't break existing functionality
./jank run examples/hello.jank
./jank compile examples/hello.jank
./jank check-health
```

---

## Long-term Vision

### Ideal State (6 months from now):
1. **jank repository** has platform-aware CMake configuration
2. **Homebrew formula** is <60 lines, mostly standard Homebrew patterns
3. **Documentation** clearly states LLVM requirements
4. **CI/CD** tests builds on macOS (with/without Nix) and Linux

### Benefits:
- Easier to maintain for both projects
- Less likely to break with upstream changes
- Easier for new contributors to understand
- Professional, production-ready build system

---

## Additional Resources

### Files to Modify in jank:
- `compiler+runtime/CMakeLists.txt` - Platform detection and flag generation
- `compiler+runtime/src/cpp/jank/aot/processor.cpp` → `.cpp.in` - Template for generated code
- `README.md` - Document LLVM version requirements
- `.github/workflows/ci.yml` - Add Homebrew build testing

### Homebrew Best Practices:
- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae)
- [Taps](https://docs.brew.sh/Taps)

---

## Questions to Ask the Maintainer

1. What is the **minimum supported LLVM version** for jank?
2. What is the **maximum tested LLVM version**?
3. Would you accept PRs to make the build system more platform-aware?
4. Is there a preferred approach for handling platform-specific linker flags?
5. Are there any plans to support `llvm@head` (LLVM 22) formally?

---

## Conclusion

Your current PR solves real problems but uses fragile approaches. By moving platform logic
upstream to jank's build system, you'll create a more maintainable solution that benefits
all jank users, not just Homebrew installations. This is the professional approach that will
get your PR merged and establish you as a thoughtful contributor to the project.

**Next Steps:**
1. Respond to the maintainer with your proposed plan
2. Create upstream PRs to jank with the CMake improvements
3. Wait for feedback and iterate
4. Update the Homebrew formula once upstream changes are merged
5. Your simplified PR will sail through review!
