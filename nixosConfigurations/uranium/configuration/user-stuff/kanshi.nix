{
  services.kanshi = {
    enable = true;

    settings = [
      {
        profile.name = "laptop-only";
        profile.outputs = [
          {
            criteria = "eDP-1";
            mode = "2256x1504@59.99900";
            scale = 1.00;
          }
        ];
      }
      {
        profile.name = "side-monitor-on";
        profile.outputs = [
          {
            criteria = "eDP-1";
            mode = "2256x1504@59.99900";
            position = "1920,0";
            scale = 1.00;
          }
          {
            criteria = "Invalid Vendor Codename - RTK HG556J02 0x20250226";
            mode = "1920x1080@60.00000";
            position = "0,0";
            scale = 1.00;
          }
        ];
      }
    ];
  };
}
