{ config, pkgs, ... }:

let
  home-manager = fetchTarball
    "https://github.com/rycee/home-manager/archive/a3dd580adc46628dd0c970037b6c87cff1251af5.tar.gz";
  secrets = import ./secrets.nix;
in {
  imports = [
    ./hardware-configuration.nix
    "${home-manager}/nixos"
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi = { canTouchEfiVariables = true; };
  };

  networking.useDHCP = false;
  networking.interfaces.wlp2s0.useDHCP = true;

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  time.timeZone = "America/Toronto";

  environment.systemPackages = with pkgs; [
    tilix
    wget
    vim
    (vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine = true;
    })
  ];

  virtualisation.docker.enable = true;
  virtualisation.anbox.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "qt";
  };

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-media-driver
    ];
  };

  services.xserver = {
    enable = true;
    layout = "us";

    libinput = {
      enable = true;
      clickMethod = "clickfinger";
      tapping = false;
      disableWhileTyping = true;
    };

    xkbModel = "chromebook";
    xkbOptions = "caps:escape";

    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = false;
    desktopManager.plasma5.enable = true;
  };

  users.mutableUsers = false;

  users.users.juliosueiras = {
    isNormalUser = true;
    uid = 1000;
    hashedPassword = secrets.user_password;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
  };

  networking.wireless = {
    enable = true;
    networks = { "TP-Link_E4E8_5G" = { pskRaw = secrets.home_wifi_password; }; };
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "20.03";

  boot.kernelPatches = [{
    name = "C202-keyboard";
    patch = null;
    extraConfig = ''
      PINCTRL_CHERRYVIEW y
      SERIO y
      SERIO_I8042 y
    '';
  }];

  nixpkgs.config = { allowUnfree = true; };
  hardware.enableAllFirmware = true;

  home-manager.users.juliosueiras = {
    home.file.".gnupg/gpg-agent.conf".text = ''
      pinentry-program ${pkgs.pinentry.qt}/bin/pinentry-qt
    '';
  };
}

