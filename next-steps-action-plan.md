# Action Plan: Making Your Jank Homebrew PR Professional

## Overview

Your PR solves real problems but uses fragile workarounds. Here's a step-by-step plan to transform it into a professional, maintainable solution that will get merged.

---

## Week 1: Communication & Planning

### Day 1-2: Respond to Maintainer

**Task:** Post response on PR #7

**What to do:**
1. Open https://github.com/jank-lang/homebrew-jank/pull/7
2. Use the draft from `pr-response-draft.md` (customize as needed)
3. Key points to emphasize:
   - You agree the current approach is fragile
   - You propose moving logic upstream to jank
   - You'll submit upstream PRs first
   - You ask for LLVM version clarification

**Expected outcome:** Maintainer engagement and agreement on approach

---

### Day 3-4: Test Current Implementation

**Verify your formula works in multiple environments:**

```bash
# Environment 1: macOS with Nix (your setup)
cd ~/darwin-config
nb  # Build your Nix config
jank check-health

# Environment 2: Fresh Homebrew install (Docker)
docker run --rm -it homebrew/brew:latest
brew tap oscarvarto/jank
brew install --build-from-source jank-git
jank check-health

# Environment 3: macOS without Nix (VM or clean machine)
# If you don't have access, ask a friend or use GitHub Actions
brew install --build-from-source oscarvarto/jank/jank-git
jank check-health
```

**Document results:**
- Does it work in all environments?
- Any warnings or errors?
- Performance differences?

---

## Week 2: Upstream Contributions

### Day 5-7: Prepare Jank Repository

**Fork and clone jank:**
```bash
cd ~/projects
gh repo fork jank-lang/jank --clone
cd jank

# Create feature branches
git checkout -b feature/cmake-platform-aware-linker-libs
git checkout main
git checkout -b feature/cmake-macos-sdk-filtering
git checkout main
git checkout -b feature/document-llvm-requirements
```

**Test current jank build:**
```bash
cd compiler+runtime
./bin/configure -GNinja -DHOMEBREW_ALLOW_FETCHCONTENT=ON
./bin/compile
./bin/install
./jank check-health
```

---

### Day 8-10: Create Upstream PR #1 - Platform-Aware Linker Libs

**Goal:** Remove need for `processor.cpp` patching in Homebrew formula

**Changes to make:**

1. **Create `processor.cpp.in` template:**
```bash
cd ~/projects/jank/compiler+runtime
cp src/cpp/jank/aot/processor.cpp src/cpp/jank/aot/processor.cpp.in
```

2. **Edit `processor.cpp.in`:**
```cpp
// Find the section around line 235:
for(auto const &lib : { "-ljank-standalone",
  /* Default libraries that jank depends on. */
  "-lm",
  "-lstdc++",  // <-- This line causes issues on macOS
  "-lLLVM",
  // ... etc
})

// Replace with:
for(auto const &lib : {
@JANK_DEFAULT_LINKER_LIBS_INITIALIZER@
})
```

3. **Edit `CMakeLists.txt`:**
```cmake
# Add after line 50 (early in the file):

# Platform-aware default linker libraries
set(JANK_DEFAULT_LINKER_LIBS
  "-ljank-standalone"
  "-lm"
  "-lLLVM"
  "-lclang-cpp"
  "-lcrypto"
  "-lz"
  "-lzstd"
)

# Only link libstdc++ on non-Apple platforms (macOS uses libc++ implicitly)
if(NOT APPLE)
  list(APPEND JANK_DEFAULT_LINKER_LIBS "-lstdc++")
endif()

# Generate C++ array initializer
set(JANK_DEFAULT_LINKER_LIBS_INITIALIZER "")
foreach(lib ${JANK_DEFAULT_LINKER_LIBS})
  string(APPEND JANK_DEFAULT_LINKER_LIBS_INITIALIZER "    \"${lib}\",\n")
endforeach()

# Configure processor.cpp from template
configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/src/cpp/jank/aot/processor.cpp.in"
  "${CMAKE_CURRENT_BINARY_DIR}/src/cpp/jank/aot/processor.cpp"
  @ONLY
)
```

4. **Update source list in `CMakeLists.txt`:**
```cmake
# Find the add_executable(jank ...) call
# Change:
#   ${CMAKE_CURRENT_SOURCE_DIR}/src/cpp/jank/aot/processor.cpp
# To:
#   ${CMAKE_CURRENT_BINARY_DIR}/src/cpp/jank/aot/processor.cpp
```

5. **Test the changes:**
```bash
cd ~/projects/jank/compiler+runtime
rm -rf build
mkdir build && cd build
cmake -GNinja -DHOMEBREW_ALLOW_FETCHCONTENT=ON ..
ninja
./jank check-health

# Verify generated file
cat src/cpp/jank/aot/processor.cpp | grep -A5 "for(auto const &lib"
# Should NOT contain "-lstdc++" on macOS
```

6. **Commit and create PR:**
```bash
git checkout feature/cmake-platform-aware-linker-libs
git add -A
git commit -m "Use CMake configure_file() for platform-specific linker libs

- Move platform-specific linker library logic from C++ to CMake
- Create processor.cpp.in template configured at build time
- Exclude -lstdc++ on macOS (uses libc++ implicitly via Clang)
- Makes adding new platforms easier (e.g., Windows, FreeBSD)

This removes the need for downstream package managers (like Homebrew)
to patch processor.cpp source code."

git push -u origin feature/cmake-platform-aware-linker-libs
gh pr create --title "Use CMake for platform-specific linker libraries" \
  --body "Moves platform-specific linker library configuration from C++ source to CMake build system. See commit message for details."
```

---

### Day 11-13: Create Upstream PR #2 - macOS SDK Path Filtering

**Goal:** Remove need for CMakeLists.txt patching in Homebrew formula

**Changes to make:**

1. **Edit `CMakeLists.txt`** (around line 150):
```cmake
# Find this section:
separate_arguments(clang_system_include_dirs)

set(clang_system_include_flags "")

# Add platform-specific filtering BETWEEN those lines:
separate_arguments(clang_system_include_dirs)

# Platform-specific filtering of system include paths
if(APPLE)
  # On macOS, filter out SDK paths that should come from -isysroot
  # This prevents baking absolute CommandLineTools/Xcode SDK paths into JIT flags
  set(_filtered_dirs "")
  foreach(dir ${clang_system_include_dirs})
    if(NOT dir MATCHES "/SDKs/")
      list(APPEND _filtered_dirs "${dir}")
    endif()
  endforeach()
  set(clang_system_include_dirs "${_filtered_dirs}")
endif()

set(clang_system_include_flags "")
```

2. **Add library path filtering** (around line 220):
```cmake
# Find this section:
foreach(lib ${jank_lib_link_dirs_prop})
  list(APPEND jank_lib_linker_flags_list -L${lib})
endforeach()

# Replace with:
foreach(lib ${jank_lib_link_dirs_prop})
  # Platform-specific library path filtering
  if(APPLE)
    # Skip system defaults on macOS; they're found via SDK automatically
    if(lib STREQUAL "/lib" OR lib STREQUAL "/usr/lib" OR lib STREQUAL "")
      continue()
    endif()
  endif()

  list(APPEND jank_lib_linker_flags_list "-L${lib}")
endforeach()

# Add SDK-specific linker flags on macOS
if(APPLE AND DEFINED ENV{SDKROOT})
  list(APPEND jank_lib_linker_flags_list "-isysroot" "$ENV{SDKROOT}")
  list(APPEND jank_lib_linker_flags_list "-L$ENV{SDKROOT}/usr/lib")
endif()
```

3. **Test the changes:**
```bash
cd ~/projects/jank/compiler+runtime
rm -rf build
mkdir build && cd build

# Set SDK explicitly
export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)

cmake -GNinja -DHOMEBREW_ALLOW_FETCHCONTENT=ON ..
ninja

# Check generated flags don't contain absolute SDK paths
cat CMakeFiles/jank.dir/flags.make | grep -i sdk
# Should see -isysroot, NOT absolute paths like /Library/Developer/CommandLineTools/...

./jank check-health
```

4. **Commit and create PR:**
```bash
git checkout feature/cmake-macos-sdk-filtering
git add CMakeLists.txt
git commit -m "Filter SDK paths from system includes on macOS

- Prevent absolute SDK paths from being baked into JIT compiler flags
- Use -isysroot instead of explicit -I flags for SDK headers
- Skip /lib and /usr/lib on macOS (found via SDK automatically)
- Makes JIT-compiled binaries portable across macOS versions

This removes the need for downstream package managers to patch
CMakeLists.txt with fragile string substitutions."

git push -u origin feature/cmake-macos-sdk-filtering
gh pr create --title "Filter macOS SDK paths from JIT compiler flags" \
  --body "Prevents absolute SDK paths from being embedded in JIT flags. See commit message for details."
```

---

### Day 14: Create Upstream PR #3 - Document LLVM Requirements

**Goal:** Clarify LLVM version requirements

**Wait for maintainer response first!** Ask in your PR #7 comment:
> "What LLVM versions does jank officially support? Should I add a CMake version check?"

**Once you get guidance, update accordingly:**

```cmake
# Example if maintainer says "LLVM 19+"
find_package(LLVM 19...<NONE> REQUIRED CONFIG)

# Or if "LLVM 21 only"
find_package(LLVM 21 REQUIRED CONFIG)
```

---

## Week 3: Update Homebrew Formula

### Day 15-17: Wait for Upstream PR Reviews

**Monitor your PRs:**
- Respond to feedback promptly
- Make requested changes
- Be patient - open source reviews take time

**What to do while waiting:**
- Test your PRs on different macOS versions if possible
- Help review other jank PRs (build goodwill)
- Read jank's documentation and contribute improvements

---

### Day 18-19: Update Homebrew Formula (After Merges)

**Once upstream PRs are merged:**

1. **Update your formula:**
```ruby
# In oscarvarto/homebrew-jank/Formula/jank-git.rb
# Use the simplified version from formula-comparison.md

class JankGit < Formula
  desc "The native Clojure dialect hosted on LLVM"
  homepage "https://jank-lang.org"
  url "https://github.com/jank-lang/jank.git", branch: "main"
  version "0.1"
  license "MPL-2.0"

  # ... (see formula-comparison.md for full simplified version)
end
```

2. **Test the updated formula:**
```bash
cd ~/darwin-config

# Update flake input to point to your updated formula
# Then rebuild
nb

jank check-health
```

3. **Update PR #7:**
```bash
cd ~/path/to/homebrew-jank
git checkout main
git pull upstream main  # Sync with upstream
git checkout your-pr-branch
git rebase main

# Make changes
vim Formula/jank-git.rb  # Simplified version

git add Formula/jank-git.rb
git commit -m "Simplify formula after upstream platform improvements

Upstream PRs merged:
- jank-lang/jank#XXX: Platform-aware linker libs
- jank-lang/jank#YYY: macOS SDK path filtering

This formula now only handles:
1. LLVM configuration (standard Homebrew pattern)
2. Nix environment isolation (legitimate runtime concern)
3. SDK setup (basic macOS build requirement)

Removed:
- CMakeLists.txt patching (now in upstream)
- processor.cpp patching (now in upstream)
- Complex environment flag manipulation (now in upstream)

Result: 180 lines → 60 lines (67% reduction)"

git push --force-with-lease
```

---

### Day 20-21: Final Testing & Documentation

**Test matrix:**

| Environment | Test Command | Expected Result |
|-------------|-------------|-----------------|
| macOS + Nix | `jank check-health` | ✅ Pass |
| macOS no Nix | `jank check-health` | ✅ Pass |
| Docker Homebrew | `brew install jank-git && jank check-health` | ✅ Pass |
| Nix pollution | `NIX_CFLAGS_COMPILE=/old jank run hello.jank` | ✅ Pass (wrapper clears) |

**Update documentation:**
```bash
# In your PR description, add:
## Testing Performed

- ✅ macOS 14.x with Nix installed
- ✅ macOS 14.x without Nix
- ✅ Docker homebrew/brew:latest
- ✅ Verified wrapper clears Nix variables
- ✅ All tests pass

## Upstream Contributions

This PR is based on upstream improvements:
- [Platform-aware linker libs](https://github.com/jank-lang/jank/pull/XXX)
- [macOS SDK filtering](https://github.com/jank-lang/jank/pull/YYY)

## Formula Changes

- Removed fragile source patching
- Simplified to standard Homebrew patterns
- Reduced from 180 lines to 60 lines
- Only handles packaging concerns (Nix isolation, LLVM setup)
```

---

## Week 4: PR Review & Merge

### Day 22-28: Respond to Review Feedback

**Monitor PR #7:**
- Respond to comments within 24 hours
- Make requested changes promptly
- Ask for clarification if needed
- Be professional and gracious

**What to expect:**
- Maintainer may request additional tests
- May need to adjust LLVM version
- May need to tweak wrapper script
- Should be much smoother than original review!

---

## Success Criteria

### ✅ Upstream PRs merged
- [ ] Platform-aware linker libs PR merged
- [ ] macOS SDK filtering PR merged
- [ ] LLVM requirements documented

### ✅ Homebrew PR approved
- [ ] Formula simplified (< 70 lines)
- [ ] No source patching
- [ ] Tests pass
- [ ] Maintainer approves

### ✅ Your darwin-config works
- [ ] `jank check-health` passes
- [ ] No Nix environment conflicts
- [ ] Can compile jank programs

---

## Troubleshooting

### If upstream PRs are rejected:

**Option A:** Use patch files instead
```ruby
# In formula
patch do
  url "https://raw.githubusercontent.com/oscarvarto/homebrew-jank/main/patches/macos-sdk.patch"
  sha256 "..."
end
```

**Option B:** Fork jank and use your fork
```ruby
url "https://github.com/oscarvarto/jank.git", branch: "macos-improvements"
```

**Option C:** Keep current approach with improvements
- Use patch files instead of `inreplace`
- Add extensive comments explaining why patches are needed
- Document expected breakage scenarios

### If maintainer wants different approach:

**Be flexible:**
- Ask for their preferred solution
- Iterate based on feedback
- Remember: their project, their rules

---

## Resources Created for You

1. **pr-recommendations.md** - Comprehensive analysis and recommendations
2. **pr-response-draft.md** - Template for responding to maintainer
3. **formula-comparison.md** - Before/after comparison
4. **upstream-cmake-improvements.patch** - Example CMake changes
5. **upstream-processor-improvement.patch** - Example processor.cpp changes
6. **next-steps-action-plan.md** - This file!

---

## Timeline Summary

| Week | Focus | Deliverable |
|------|-------|-------------|
| 1 | Communication & Planning | Maintainer agreement |
| 2 | Upstream Contributions | 2-3 PRs to jank |
| 3 | Formula Updates | Simplified Homebrew formula |
| 4 | Review & Merge | PR #7 merged! |

**Total time:** 4 weeks (with some parallelization possible)

---

## Final Thoughts

You've done the hard work of identifying and solving real problems. Now you're taking it to the next level by contributing improvements upstream. This is **exactly** how open source should work:

1. ✅ Identify problem (Nix + macOS SDK conflicts)
2. ✅ Create working solution (your current formula)
3. ✅ Recognize fragility (maintainer feedback)
4. → **Move logic upstream** (in progress)
5. → **Simplify downstream** (next step)
6. → **Everyone benefits** (final result)

This approach will:
- Get your PR merged
- Improve jank for all users
- Establish you as a thoughtful contributor
- Make the ecosystem more maintainable

Good luck, and feel free to ask questions as you work through this!
