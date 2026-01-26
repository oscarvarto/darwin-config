{user, ...}: {
  # Fully declarative dock using the latest from Nix Store
  local = {
    dock = {
      enable = true;
      username = user;
      entries = [
        {path = "/Applications/Obsidian.app/";}
        {path = "/Applications/Ghostty.app/";}
        {path = "/Applications/Zed Preview.app/";}
        {path = "/Applications/Google Chrome.app/";}
        # {path = "/Applications/ChatGPT Atlas.app/";}
        # {path = "/Applications/Comet.app/";}
        # {path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/";}
        {path = "/Applications/Fastmail.app/";}
        {path = "/Applications/FaceTime.app/";}
        {path = "/Applications/Discord.app/";}
        {path = "/Applications/Preview.app/";}
        {path = "/Applications/Spotify.app/";}
        {path = "/System/Applications/Calendar.app/";}
        {path = "/Applications/Xcode.app/";}
        {path = "/System/Applications/System Settings.app/";}
      ];
    };
  };
}
