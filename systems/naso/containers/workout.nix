{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

let

  # Common variables for the containers
  commonEnvironment = pkgs.functions.container.fixEnvironment {

    # Time
    TIME_ZONE = config.mine.system.timezone;

    # Application
    WGER_INSTANCE = "https://wger.de";
    ALLOW_REGISTRATION = "False";
    ALLOW_GUEST_USERS = "False";
    ALLOW_UPLOAD_VIDEOS = "True";
    MIN_ACCOUNT_AGE_TO_TRUST = 0;

    # Synchronzing exercises
    SYNC_EXERCISES_ON_STARTUP = "True";
    DOWNLOAD_EXERCISE_IMAGES_ON_STARTUP = "True";
    SYNC_EXERCISES_CELERY = "True";
    SYNC_EXERCISE_IMAGES_CELERY = "True";
    SYNC_EXERCISE_VIDEOS_CELERY = "True";

    # Download Ingredirenta
    DOWNLOAD_INGREDIENTS_FROM = "WGER";

    # Celery
    USE_CELERY = "True";
    CELERY_BROKER = "redis://${names.wger.cache}:6379/2";
    CELERY_BACKEND = "redis://${names.wger.cache}:6379/2";

    # Database
    DJANGO_DB_ENGINE = "django.db.backends.postgresql";
    DJANGO_DB_DATABASE = names.wger.app;
    DJANGO_DB_HOST = names.wger.database;
    DJANGO_DB_PORT = 5432;
    DJANGO_PERFORM_MIGRATIONS = "True";

    # Cache
    DJANGO_CACHE_BACKEND = "django_redis.cache.RedisCache";
    DJANGO_CACHE_LOCATION = "redis://${names.wger.cache}:6379/1";
    DJANGO_CACHE_TIMEOUT = "1296000";  # In seconds - 60 * 60 * 24 * 15, 15 Days
    DJANGO_CACHE_CLIENT_CLASS = "django_redis.client.DefaultClient";

    # Brute force login attacks
    AXES_ENABLED = "True";
    AXES_FAILURE_LIMIT = 10;
    AXES_COOLOFF_TIME = 30;  # In minutes
    AXES_HANDLER = "axes.handlers.cache.AxesCacheHandler";
    AXES_LOCKOUT_PARAMETERS = "ip_address";
    AXES_IPWARE_PROXY_COUNT = 1;
    AXES_IPWARE_META_PRECEDENCE_ORDER = "HTTP_X_FORWARDED_FOR,REMOTE_ADDR";

    # Others
    DJANGO_DEBUG = "False";
    WGER_USE_GUNICORN = "True";
    EXERCISE_CACHE_TTL = 18000;  # In seconds - 5 * 60 * 60, 5 hours

    # JWT auth
    ACCESS_TOKEN_LIFETIME = 10;  # In minutes
    REFRESH_TOKEN_LIFETIME = 24;  # In minutes

    # Captcha
    USE_RECAPTCHA = "False";

  };

in {

  # Networking
  networks."${networks.front}".external = true;
  networks."${networks.workout}".name = networks.workout;

       ######
  ### # WGer # ###
       ######

  services."${names.wger.app}".service = let

    healthPort = 8000;

  in {

    # Image
    image = "wger/server:latest";

    # Environment
    environment = commonEnvironment;
    env_file = [ "/data/local/containers/workout/wger.env" ];

    # Depends
    depends_on = [ names.wger.database names.wger.cache ];

    # Volumes
    volumes = [
      "/data/local/containers/workout/static:/home/wger/static"
      "/data/local/containers/workout/media:/home/wger/media"
    ];

    # Healthcheck
    healthcheck = {
      # Test command
      test = [
        "CMD"
        "wget" "--no-verbose" "--tries=1" "--spider"
        "http://localhost:${builtins.toString healthPort}"
      ];
      # Timing
      interval = "10s";
      timeout = "5s";
      retries = 5;
    };

    # Networking
    expose = [ (builtins.toString healthPort) ];

    # Network
    networks = [ networks.workout ];

  };

       ########
  ### # Static # ###
       ########

  services."${names.wger.web}".service = {

    # Image
    image = "nginx:stable";

    # Depends on
    depends_on = [ names.wger.app ];

    # Volumes
    volumes = let

      # Nginx configuration file
      configNginx = builtins.toFile "nginx.conf" ''
        upstream wger {
            server ${names.wger.app}:8000;
        }

        server {

            listen 80;

            location / {
                proxy_pass http://wger;
                proxy_set_header Host $host;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
                proxy_set_header X-Forwarded-Host $host:$server_port;
                proxy_redirect off;
            }

            location /static/ {
                alias /wger/static/;
            }

            location /media/ {
                alias /wger/media/;
            }

            # Increase max body size to allow for video uploads
            client_max_body_size 100M;
        }
      '';

    in [
      "${configNginx}:/etc/nginx/conf.d/default.conf:ro"
      "/data/local/containers/workout/static:/wger/static:ro"
      "/data/local/containers/workout/media:/wger/media:ro"
    ];

    # Healthcheck
    healthcheck = {
      # Test command
      test = [
        "CMD"
        "service" "nginx" "status"
      ];
      # Timing
      interval = "10s";
      timeout = "5s";
      retries = 5;
      start_period = "300s";
    };

    # Networking
    networks = [ networks.front networks.workout ];

  };

       ##########
  ### # Database # ###
       ##########

  services."${names.wger.database}".service = {

    # Image
    image = "postgres:15-alpine";

    # Environment
    environment = {
      POSTGRES_DATABASE = names.wger.app;
    };
    env_file = [ "/data/local/containers/workout/database.env" ];

    # Volume
    volumes = [
      "/data/local/containers/workout/database:/var/lib/postgresql/data/"
    ];

    # Healthcheck
    healthcheck = {
      # Test command
      test = [
        "CMD"
        "pg_isready" "-U" "wger"
      ];
      # Timing
      interval = "10s";
      timeout = "5s";
      retries = 5;
      start_period = "30s";
    };

    # Networking
    networks = [ networks.workout ];

  };

       #######
  ### # Cache # ###
       #######

  services."${names.wger.cache}".service = {

    # Image
    image = "redis:latest";

    # Volumes
    volumes = [
      "/data/local/containers/workout/cache:/data"
    ];

    # Healthcheck
    healthcheck = {
      # Test command
      test = [
        "CMD"
        "redis-cli" "ping"
      ];
      # Timing
      interval = "10s";
      timeout = "5s";
      retries = 5;
      start_period = "30s";
    };

    # Networking
    networks = [ networks.workout ];

  };

       ########
  ### # Worker # ###
       ########

  services."${names.wger.celery.worker}".service = {

    # Image
    image = "wger/server:latest";

    # Command
    command = "/start-worker";

    # Environment
    environment = commonEnvironment;
    env_file = [ "/data/local/containers/workout/wger.env" ];

    # Volumes
    volumes = [
      "/data/local/containers/workout/media:/home/wger/media"
    ];

    # Healthcheck
    healthcheck = {
      # Test command
      test = [
        "CMD"
        "celery" "-A" "wger" "inspect" "ping"
      ];
      # Timing
      interval = "10s";
      timeout = "5s";
      retries = 5;
      start_period = "30s";
    };

    # Depends
    depends_on = [ names.wger.app ];

    # Networking
    networks = [ networks.workout ];

  };

       ########
  ### # Celery # ###
       ########

  services."${names.wger.celery.beat}".service = {

    # Image
    image = "wger/server:latest";

    # Command
    command = "/start-beat";

    # Environment
    environment = commonEnvironment;
    env_file = [ "/data/local/containers/workout/wger.env" ];

    # Volumes
    volumes = [
      "/data/local/containers/workout/beat:/home/wger/beat"
    ];

    # Depends
    depends_on = [ names.wger.celery.worker ];

    # Networking
    networks = [ networks.workout ];

  };

       ########
  ### # Flower # ###
       ########

  services."${names.wger.celery.flower}".service = let

    healthPort = 5555;

  in {

    # Image
    image = "wger/server:latest";

    # Command
    command = "/start-flower";

    # Environment
    environment = commonEnvironment;
    env_file = [ "/data/local/containers/workout/wger.env" ];

    # Volumes
    volumes = [
      "/data/local/containers/workout/beat:/home/wger/beat"
    ];

    # Depends
    depends_on = [ names.wger.celery.worker ];

    # Healthcheck
    healthcheck = {
      # Test command
      test = [
        "CMD"
        "wget" "--no-verbose" "--tries=1"
        "http://localhost:${builtins.toString healthPort}/healthcheck"
      ];
      # Timing
      interval = "10s";
      timeout = "5s";
      retries = 5;
    };

    # Health port
    expose = [ (builtins.toString healthPort) ];

    # Networking
    networks = [ networks.workout ];

  };

}