variable "REPO" {
  default = "pgduckdb/pgduckdb"
}

variable "POSTGRES_VERSION" {
  default = "18"
}

target "shared" {
  platforms = [
    "linux/amd64"
  ]
}

target "postgres" {
  inherits = ["shared"]

  contexts = {
    postgres_base = "docker-image://postgres:${POSTGRES_VERSION}-trixie"
  }

  args = {
    POSTGRES_VERSION = "${POSTGRES_VERSION}"
  }

  tags = [
    "${REPO}:${POSTGRES_VERSION}-dev",
  ]
}

target "pg_duckdb" {
  inherits = ["postgres"]
}

target "pg_duckdb_18" {
  inherits = ["pg_duckdb"]

  args = {
    POSTGRES_VERSION = "18"
  }
}

target "default" {
  inherits = ["pg_duckdb_18"]
}
