# Draft Response to PR #7 Comments

Hi @jeaye,

Thanks for the thorough review! You're absolutely right that this formula contains too many fragile workarounds. I'd like to propose moving the platform-specific logic upstream to jank itself, which will make the formula much simpler and more maintainable.

## The Core Problems

1. **Fragile string patching** - The `inreplace` calls will break if CMakeLists.txt formatting changes
2. **Platform logic in the wrong place** - `-lstdc++` exclusion should be in the build system, not a C++ source patch
3. **Nix environment conflicts** - Build-time Nix variables interfere with SDK resolution (this is a legitimate runtime concern)

## Proposed Upstream Fixes

I'd like to submit the following PRs to `jank-lang/jank`:

### PR 1: Platform-aware linker library configuration
**Problem:** macOS uses libc++ (via Clang), not libstdc++, so explicitly linking `-lstdc++` causes issues.

**Solution:** Use CMake's `configure_file()` to generate `processor.cpp` from a template:

```cmake
# In CMakeLists.txt
set(JANK_DEFAULT_LINKER_LIBS
  "-ljank-standalone" "-lm" "-lLLVM" "-lclang-cpp"
  "-lcrypto" "-lz" "-lzstd"
)

# Only link libstdc++ on non-Apple platforms
if(NOT APPLE)
  list(APPEND JANK_DEFAULT_LINKER_LIBS "-lstdc++")
endif()

# Generate processor.cpp with the platform-specific list
configure_file(
  src/cpp/jank/aot/processor.cpp.in
  ${CMAKE_BINARY_DIR}/src/cpp/jank/aot/processor.cpp
  @ONLY
)
```

**Benefits:**
- Platform logic lives in the build system (where it belongs)
- No runtime preprocessor checks
- Easier to extend (e.g., adding Windows support later)
- Homebrew formula doesn't need to patch C++ sources

### PR 2: macOS SDK path filtering in CMake
**Problem:** Absolute SDK paths (like `/Library/Developer/CommandLineTools/.../SDKs/...`) get baked into JIT flags, causing portability issues.

**Solution:** Filter SDK paths in CMakeLists.txt:

```cmake
# Platform-specific filtering of system include paths
if(APPLE)
  set(_filtered_dirs "")
  foreach(dir ${clang_system_include_dirs})
    if(NOT dir MATCHES "/SDKs/")
      list(APPEND _filtered_dirs "${dir}")
    endif()
  endforeach()
  set(clang_system_include_dirs "${_filtered_dirs}")
endif()
```

**Benefits:**
- JIT-compiled code uses `-isysroot` instead of absolute paths
- Binaries are portable across macOS versions
- Homebrew formula doesn't need to patch CMakeLists.txt

### PR 3: Document LLVM version requirements
**Question:** What LLVM versions does jank officially support?

The original formula used `llvm@21`, but my PR changed it to `llvm`. I've tested with:
- LLVM 19 (Homebrew default) ✅
- LLVM 21 (previous formula) ✅
- LLVM 22 (you mentioned `llvm@head`) ❓

**Proposal:** Add a CMake version check:
```cmake
find_package(LLVM 19...<NONE> REQUIRED)
```

Could you clarify:
1. What is the **minimum** supported LLVM version?
2. What is the **maximum** tested version?
3. Should the formula use `llvm`, `llvm@21`, or `llvm@head`?

## What Stays in the Formula

### Nix Environment Isolation (Legitimate Runtime Concern)

The wrapper script is **necessary** for users with Nix installed:

```ruby
# This stays in the formula
(bin/"jank").write <<~SH
  #!/usr/bin/env bash
  set -euo pipefail
  unset SDKROOT HOMEBREW_SDKROOT MACOSX_DEPLOYMENT_TARGET
  unset NIX_CFLAGS_COMPILE NIX_LDFLAGS NIX_APPLE_SDK_VERSION
  exec "#{libexec_bin/"jank"}" "$@"
SH
```

**Why:**
- Nix pollutes the environment with variables pointing to old SDKs (e.g., macOS 11.3)
- These variables interfere with jank's JIT compilation at **runtime** (not build time)
- Similar wrappers are used by other Homebrew formulas (e.g., `emacs-plus`)
- This is a Homebrew packaging concern, not a jank concern

### Context: Nix + macOS SDK Issues

Users running Nix on macOS encounter this issue (see `jank-lang/jank#560`):
```
NIX_CFLAGS_COMPILE="-isystem /nix/store/.../MacOSX11.3.sdk/usr/include/..."
```

This SDK is **older than** what jank was built with, causing header conflicts. The wrapper ensures jank uses the **system SDK** at runtime.

## Simplified Formula (After Upstream Changes)

Once the upstream PRs are merged, the formula becomes:

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
  depends_on "llvm@21"  # Or whatever you recommend
  depends_on "openssl"

  def install
    llvm = Formula["llvm@21"]
    ENV.prepend_path "PATH", llvm.opt_bin

    if OS.mac?
      ENV["SDKROOT"] = Utils.safe_popen_read("xcrun", "--sdk", "macosx", "--show-sdk-path").strip
    end

    cd "compiler+runtime"
    system "./bin/configure", "-GNinja", *std_cmake_args,
           "-DHOMEBREW_ALLOW_FETCHCONTENT=ON"
    system "./bin/compile"
    system "./bin/install"

    # Wrapper to isolate from Nix environment
    libexec_bin = libexec/"bin"
    libexec_bin.install bin/"jank"
    (bin/"jank").write <<~SH
      #!/usr/bin/env bash
      set -euo pipefail
      unset SDKROOT NIX_CFLAGS_COMPILE NIX_LDFLAGS NIX_APPLE_SDK_VERSION
      exec "#{libexec_bin/"jank"}" "$@"
    SH
    (bin/"jank").chmod 0755
    ln_s lib, libexec/"lib", force: true
  end

  test do
    assert_predicate bin/"jank", :exist?
    assert_match "jank can aot compile working binaries", pipe_output("#{bin/"jank"} check-health")
  end
end
```

**Result:** 180 lines → 60 lines (67% reduction)

## Timeline

1. **This week:** Submit upstream PRs to jank with the CMake improvements
2. **Wait for review:** Iterate based on your feedback
3. **After merge:** Update this Homebrew PR with the simplified formula
4. **Final review:** Should be straightforward since fragile patching is gone

## Questions for You

Before I start the upstream PRs:

1. Are you open to these CMake improvements in jank?
2. What LLVM versions should jank officially support?
3. Any other build system concerns I should address?
4. Would you prefer one large PR or separate PRs for each improvement?

---

**TL;DR:** I'll move the fragile patching logic upstream to jank's build system, leaving only the Nix isolation wrapper in the Homebrew formula. This benefits all jank users, not just Homebrew installations, and makes both projects more maintainable.

Looking forward to your thoughts!
