{
  hostName = "clematis";
  domain = "clemat.is";

  authentik = {
    subDomain = "auth";
    httpPort = 9080;
    httpsPort = 9433;
  };

  chiefonboarding = {
    subDomain = "onboarding";
    httpPort = 8888;
  };

  gitea = {
    subDomain = "git";
    httpPort = 3200;
  };

  metrics = {
    subDomain = "dash";
    prometheus.httpPort = 3100;
    docker.httpPort = 9323;
    cAdvisor.httpPort = 7080;
    caddy.httpPort = 2019;
    grafana.httpPort = 3000;
  };

  outline = {
    subDomain = "docs";
    httpPort = 3003;
  };

  plane = {
    subDomain = "projects";
    httpPort = 10080;
  };
}
