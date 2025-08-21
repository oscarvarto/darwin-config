# Xcode Beta Configuration Summary

This document summarizes the changes made to configure your darwin-config to use **Xcode 26.0 beta** instead of the regular Xcode version.

## ✅ Changes Made

### 1. Shell Environment Configuration

#### **Zsh Configuration** (`modules/shell-config.nix`)
- Added `export DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer"`
- Ensures zsh sessions use Xcode beta toolchain

#### **Fish Configuration** (`modules/home-manager.nix`)
- Added `set -gx DEVELOPER_DIR "/Applications/Xcode-beta.app/Contents/Developer"`
- Ensures fish sessions use Xcode beta toolchain

#### **Nushell Configuration** (`modules/nushell/env.nu`)
- Added `$env.DEVELOPER_DIR = "/Applications/Xcode-beta.app/Contents/Developer"`
- Ensures nushell sessions use Xcode beta toolchain

### 2. System-Level Configuration

#### **LaunchD Service** (`system.nix`)
- Added `launchd.user.agents.setDeveloperDirVar` service
- Sets `DEVELOPER_DIR` system-wide for GUI applications
- Works with SIP (System Integrity Protection) enabled

#### **Home Manager Session Variables** (`modules/home-manager.nix`)
- Added `DEVELOPER_DIR` to `sessionVariables`
- Ensures GUI applications launched from dock/finder use beta toolchain

### 3. Package Management

#### **Homebrew Configuration** (`modules/brews.nix`)
- Commented out regular "XCode" from `masApps`
- No longer installs regular Xcode via Mac App Store

### 4. Management Scripts

#### **Xcode Switching Scripts** (via stow)
- `use-xcode-beta`: Script to switch `xcode-select` to beta version
- `use-xcode-release`: Script to switch back to regular Xcode if needed
- Located in `~/.local/share/bin/` after stow deployment

## 🔧 Current System Status

### **Active Configuration**
- **xcode-select**: Points to `/Applications/Xcode-beta.app/Contents/Developer`
- **Xcode Version**: Xcode 26.0 (Build 17A5305f)
- **Swift Version**: Apple Swift version 6.2 (swiftlang-6.2.0.19.9)
- **Clang Version**: Apple clang version 17.0.0 (clang-1700.3.19.1)
- **Target Platform**: arm64-apple-darwin25.0.0 (macOS 26 Tahoe)

### **Toolchain Verification**
```bash
# System clang now uses Xcode beta
/usr/bin/clang --version
# InstalledDir: /Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin

# Swift uses beta SDK
/usr/bin/swift --version
# Target: arm64-apple-macosx26.0
```

### **Environment Variables** (Available in new shell sessions)
- `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`
- Applied to all shells: zsh, fish, nushell
- Applied to GUI applications via launchd

## 🚀 Usage

### **Switching Between Xcode Versions**
```bash
# Switch to Xcode beta (current default)
use-xcode-beta

# Switch back to regular Xcode if needed
use-xcode-release
```

### **Verification Commands**
```bash
# Check current xcode-select setting
xcode-select -p

# Check Xcode version
xcodebuild -version

# Check if using beta toolchain
/usr/bin/clang --version | grep "InstalledDir"

# Check Swift version and target
/usr/bin/swift --version
```

### **Rebuilding Configuration**
```bash
# Build configuration
nb

# Build and switch to new configuration
ns
```

## 📁 Files Modified

- `modules/shell-config.nix` - Added zsh DEVELOPER_DIR
- `modules/home-manager.nix` - Added fish DEVELOPER_DIR and sessionVariables
- `modules/nushell/env.nu` - Added nushell DEVELOPER_DIR
- `system.nix` - Added launchd service for system-wide DEVELOPER_DIR
- `modules/brews.nix` - Commented out regular Xcode from masApps
- `stow/aux-scripts/.local/share/bin/use-xcode-beta` - New switching script
- `stow/aux-scripts/.local/share/bin/use-xcode-release` - New switching script

## 🎯 Benefits

1. **Consistent Toolchain**: All development tools use Xcode 26.0 beta
2. **Multi-Shell Support**: Works with zsh, fish, and nushell
3. **GUI Integration**: IDE and GUI apps use beta toolchain
4. **Easy Switching**: Scripts to toggle between beta and release
5. **SIP Compatible**: Uses user-level launchd agents
6. **Declarative**: All configuration managed through Nix

## ⚠️ Notes

- **New Shell Sessions**: Environment variables apply to new terminal sessions
- **GUI Apps**: May need restart to pick up new DEVELOPER_DIR
- **Xcode Regular**: Still installed but not used by default
- **Build Tools**: All command-line tools (clang, swift, etc.) use beta versions
- **SDK Target**: Now targeting macOS 26 Tahoe beta

---

**Migration Date**: August 21, 2025  
**Xcode Version**: 26.0 beta (Build 17A5305f)  
**macOS Version**: macOS 26 Tahoe beta 7
