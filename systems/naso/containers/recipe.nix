{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

let

  # Connection information
  connection = pkgs.functions.container.fixEnvironment {
    POSTGRES_HOST = names.tandoor.database;
    POSTGRES_DB = "djangodb";
    POSTGRES_PORT = 5432;
    POSTGRES_USER = "djangouser";
  };

in {

  # Networking
  networks."${networks.front.name}".external = true;
  networks."${networks.recipe.name}".name = networks.recipe.name;

       #########
  ### # Tandoor # ###
       #########

  services."${names.tandoor.app}".service = {

    # Image
    image = "vabene1111/recipes:latest";

    # Name
    container_name = names.tandoor.app;

    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      # Do not debug
      DEBUG = 0;
      # Database info
      DB_ENGINE = "django.db.backends.postgresql";
    } //
    connection;

    env_file = [ "/data/local/containers/recipe/tandoor.env" ];

    # Depends
    depends_on = [ names.tandoor.database ];

    # Volumes
    volumes = [
      "/data/local/containers/recipe/media:/opt/recipes/mediafiles"
    ];

    # Networking
    networks = [ networks.recipe.name networks.front.name ];

  };

       #########
  ### # Tandoor # ###
       #########

  services."${names.tandoor.database}".service = {

    # Image
    image = "postgres:16-alpine";

    # Name
    container_name = names.tandoor.database;

    # Environment
    environment = connection;
    env_file = [ "/data/local/containers/recipe/tandoor.env" ];

    # Volume
    volumes = [
      "/data/local/containers/recipe/database:/var/lib/postgresql/data"
    ];

    # Networking
    networks = [ networks.recipe.name networks.front.name ];

  };

}