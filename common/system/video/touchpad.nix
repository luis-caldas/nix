{ ... }:
{

  # Enable libinput
  services.xserver.libinput = {
    enable = true;
    naturalScrolling = false;
    disableWhileTyping = true;
    accelSpeed = "0.5";
  };

}
