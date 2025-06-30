{
  lib,
  routes,
  config,
  ...
}:
{
  services.prometheus = {
    enable = true;
    port = routes.metrics.prometheus.httpPort;
    extraFlags = [ "--web.enable-remote-write-receiver" ];
  };

  virtualisation.docker.daemon.settings = {
    metrics-addr = "localhost:${toString routes.metrics.docker.httpPort}";
  };

  services.cadvisor = {
    enable = true;
    port = routes.metrics.cAdvisor.httpPort;
  };

  services.caddy.globalConfig = lib.mkAfter ''
    admin localhost:${toString routes.metrics.caddy.httpPort}

    metrics {
        per_host
    }
  '';

  services.alloy.enable = true;
  environment.etc."alloy/config.alloy".text = ''
    prometheus.exporter.unix "default" {
    }

    prometheus.scrape "unix" {
      targets = prometheus.exporter.unix.default.targets
      scrape_interval = "15s"
      forward_to = [prometheus.remote_write.default.receiver]
    }

    prometheus.scrape "docker" {
      targets = [{__address__ = "localhost:${toString routes.metrics.docker.httpPort}"}]
      scrape_interval = "15s"
      forward_to = [prometheus.remote_write.default.receiver]
    }

    prometheus.scrape "cadvisor" {
      targets = [{__address__ = "localhost:${toString routes.metrics.cAdvisor.httpPort}"}]
      scrape_interval = "15s"
      forward_to = [prometheus.remote_write.default.receiver]
    }

    prometheus.scrape "caddy" {
      targets = [{__address__ = "localhost:${toString routes.metrics.caddy.httpPort}"}]
      forward_to = [prometheus.remote_write.default.receiver]
    }

    prometheus.remote_write "default" {
      endpoint {
        url = "http://localhost:${toString routes.metrics.prometheus.httpPort}/api/v1/write"
      }
    }
  '';

  sops.secrets.grafanaClientSecret = {
    mode = "0600";
    owner = "${config.users.users.grafana.name}";
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = routes.metrics.grafana.httpPort;
        domain = "${routes.metrics.subDomain}.${routes.domain}";
        root_url = "https://${routes.metrics.subDomain}.${routes.domain}";
      };

      auth = {
        signout_redirect_url = "https://${routes.authentik.subDomain}.${routes.domain}/application/o/grafana/end-session/";
        oauth_auto_login = true;
        disable_login_form = true;
      };
      "auth.generic_oauth" = {
        name = "authentik";
        enabled = true;
        client_id = "AlH37DQbUJxTHq712RsIBJStU1qU2qsmq0lN16X5";
        client_secret = "$__file{${config.sops.secrets.grafanaClientSecret.path}}";
        scopes = "openid email profile";
        auth_url = "https://${routes.authentik.subDomain}.${routes.domain}/application/o/authorize/";
        token_url = "https://${routes.authentik.subDomain}.${routes.domain}/application/o/token/";
        api_url = "https://${routes.authentik.subDomain}.${routes.domain}/application/o/userinfo/";
        role_attribute_path = "contains(groups, 'grafana Admins') && 'Admin' || 'Viewer'";
      };
    };
    provision.datasources.settings = {
      datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:${toString routes.metrics.prometheus.httpPort}";
        }
      ];
    };
  };

  services.caddy = {
    virtualHosts."${routes.metrics.subDomain}.${routes.domain}".extraConfig = ''
      reverse_proxy http://localhost:${toString routes.metrics.grafana.httpPort}
    '';
  };
}
