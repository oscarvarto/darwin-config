{ config, pkgs, lib, user, ... }:

{
  # Fully declarative dock using the latest from Nix Store
  local = {
    dock = {
      enable = true;
      username = user;
      entries = [
        { path = "/Applications/Obsidian.app/"; }
        { path = "/Applications/Zed Preview.app/"; }
        { path = "/Applications/Ghostty.app/"; }
        { path = "/Applications/WarpPreview.app/"; }
        { path = "/Applications/Safari.app/"; }
        { path = "/Applications/Firefox.app/"; }
        { path = "/Applications/Google Chrome.app/"; }
        { path = "/Applications/Microsoft Edge.app/"; }
        { path = "/Applications/Microsoft Teams.app/"; }
        { path = "/Applications/Microsoft Outlook.app/"; }
        { path = "/Applications/Mail.app/"; }
        { path = "/Applications/FaceTime.app/"; }
        { path = "/Applications/Discord.app/"; }
        { path = "/Applications/Preview.app/"; }
        { path = "/System/Applications/Music.app/"; }
        { path = "/System/Applications/Calendar.app/"; }
        { path = "/Applications/Xcode.app/"; }
        { path = "/System/Applications/System Settings.app/"; }
      ];
    };
  };
}
