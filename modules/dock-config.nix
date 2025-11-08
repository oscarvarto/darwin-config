{user, ...}: {
  # Fully declarative dock using the latest from Nix Store
  local = {
    dock = {
      enable = true;
      username = user;
      entries = [
        {path = "/Applications/Obsidian.app/";}
        {path = "/Applications/Zed Preview.app/";}
        {path = "/Applications/Ghostty.app/";}
        {path = "/Applications/kitty.app/";}
        {path = "/Applications/ChatGPT Atlas.app/";}
        {path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/";}
        {path = "/Applications/Fastmail.app/";}
        {path = "/Applications/FaceTime.app/";}
        {path = "/Applications/Discord.app/";}
        {path = "/Applications/Preview.app/";}
        {path = "/Applications/TIDAL.app/";}
        {path = "/System/Applications/Calendar.app/";}
        {path = "/Applications/Xcode.app/";}
        {path = "/System/Applications/System Settings.app/";}
      ];
    };
  };
}
