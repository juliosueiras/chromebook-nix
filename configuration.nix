{ config, pkgs, ... }:

let
  anboxConfig = import ./packages/anbox-extra/default.nix;
  home-manager = fetchTarball
    "https://github.com/rycee/home-manager/archive/a3dd580adc46628dd0c970037b6c87cff1251af5.tar.gz";
  secrets = import ./secrets.nix;
in {
  imports = [ ./hardware-configuration.nix "${home-manager}/nixos" ];

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
    discord
    wget
    vim
    (vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine = true;
    })
  ];

  boot.binfmt = {
    registrations = {
      arm_exe = {
        interpreter = "/system/lib/arm/houdini";
        magicOrExtension =
          "\\x7f\\x45\\x4c\\x46\\x01\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x02\\x00\\x28";
        preserveArgvZero = true;
      };

      arm_dyn = {
        interpreter = "/system/lib/arm/houdini";
        magicOrExtension =
          "\\x7f\\x45\\x4c\\x46\\x01\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x03\\x00\\x28";
        preserveArgvZero = true;
      };

      arm64_exe = {
        interpreter = "/system/lib64/arm64/houdini64";
        magicOrExtension =
          "\\x7f\\x45\\x4c\\x46\\x02\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x02\\x00\\xb7";
        preserveArgvZero = true;
      };

      arm64_dyn = {
        interpreter = "/system/lib64/arm64/houdini64";
        magicOrExtension =
          "\\x7f\\x45\\x4c\\x46\\x02\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x03\\x00\\xb7";
        preserveArgvZero = true;
      };
    };
  };

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
    networks = {
      "TP-Link_E4E8_5G" = { pskRaw = secrets.home_wifi_password; };
      "Touchdown Coworking" = { pskRaw = secrets.tc_wifi_password; };
    };
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

  systemd.services.anbox-container-manager.preStart = pkgs.lib.mkAfter ''
    cp -r ${anboxConfig}/overlays/* /var/lib/anbox/rootfs-overlay/
    chown -R 100000:100000 /var/lib/anbox/rootfs-overlay/system/lib/arm
    chown -R 100000:100000 /var/lib/anbox/rootfs-overlay/system/lib64/arm64

    cd /var/lib/anbox/rootfs-overlay/system/priv-app
    chown -R 100000:100000 Phonesky GoogleServicesFramework GoogleLoginService PrebuiltGmsCore
  '';
}

