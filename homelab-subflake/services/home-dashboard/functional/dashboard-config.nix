/**
  General presentation config for the home-dashboard: title, color,
*/
{ ... }:
{
  services.homepage-dashboard = {
    settings = {
      title = "Welcome home";
      color = "slate";
    };

    widgets = [
      {
        search = {
          provider = "duckduckgo";
          target = "_blank";
        };
      }
    ];
  };
}
