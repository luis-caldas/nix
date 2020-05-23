{ ... }:
{

  # Enable libinput
  services.xserver.libinput = {
    enable = true;
    naturalScrolling = true;
    disableWhileTyping = true;
    accelSpeed = "0.5";
  };

}
