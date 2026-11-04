/**
  Disables automatic watching of new repos and changes.
*/
{
  services.gitea.settings = {
    service = {
      AUTO_WATCH_NEW_REPOS = false;
      AUTO_WATCH_ON_CHANGES = false;
    };
  };
}
