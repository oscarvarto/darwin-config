{
  config,
  pkgs,
  agenix,
  secrets,
  user ? "oscarvarto",
  ...
}: let
  # user is passed as parameter or falls back to default
in {
  age.identityPaths = [
    "/Users/${user}/.ssh/id_ed25519"
    "/Users/${user}/.ssh/id_ed25519_agenix" # Dedicated agenix key
  ];

  # SSH Keys (Deploy-time secrets - perfect for agenix)
  # Uncomment these when you have the corresponding .age files in your secrets repo

  # age.secrets."github-ssh-key" = {
  #   symlink = true;
  #   path = "/Users/${user}/.ssh/id_github";
  #   file = "${secrets}/github-ssh-key.age";
  #   mode = "600";
  #   owner = "${user}";
  #   group = "staff";
  # };

  # age.secrets."github-signing-key" = {
  #   symlink = false;
  #   path = "/Users/${user}/.ssh/pgp_github.key";
  #   file = "${secrets}/github-signing-key.age";
  #   mode = "600";
  #   owner = "${user}";
  # };

  # API Keys & Tokens (System-level secrets)
  # Uncomment and create corresponding .age files as needed

  # age.secrets."openai-api-key" = {
  #   file = "${secrets}/openai-api-key.age";
  #   mode = "600";
  #   owner = "${user}";
  # };

  # age.secrets."anthropic-api-key" = {
  #   file = "${secrets}/anthropic-api-key.age";
  #   mode = "600";
  #   owner = "${user}";
  # };

  # Development Certificates and Keys
  # age.secrets."dev-certificate" = {
  #   file = "${secrets}/dev-certificate.age";
  #   path = "/Users/${user}/.config/certs/dev.pem";
  #   mode = "600";
  #   owner = "${user}";
  # };

  # Service Configuration Files
  # age.secrets."tailscale-auth-key" = {
  #   file = "${secrets}/tailscale-auth-key.age";
  #   mode = "600";
  #   owner = "${user}";
  # };

  # Database passwords for local development
  # age.secrets."postgres-password" = {
  #   file = "${secrets}/postgres-password.age";
  #   mode = "600";
  #   owner = "${user}";
  # };
}
