{user, ...}: {
  # Fully declarative dock using the latest from Nix Store
  local = {
    dock = {
      enable = true;
      username = user;
      entries = [
        {path = "/Applications/Emacs.app/";}
        {path = "/Applications/Obsidian.app/";}
        {path = "/Applications/Ghostty.app/";}
        {path = "/Applications/Dia.app/";}
        {path = "/Applications/Fastmail.app/";}
        {path = "/Applications/Preview.app/";}
        {path = "/Applications/Spotify.app/";}
        {path = "/System/Applications/Calendar.app/";}
        {path = "/System/Applications/System Settings.app/";}
      ];
    };
  };
}
