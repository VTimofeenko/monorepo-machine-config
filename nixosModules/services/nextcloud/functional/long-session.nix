{
  services.nextcloud.settings = rec {
    session_lifetime = 30 * 24 * 60 * 60;
    remember_login_cookie_lifetime = 2 * session_lifetime;
  };

}
