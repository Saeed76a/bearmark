#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
  set -o xtrace
fi

help() {
  echo "Usage: ./cli.sh <action>"
  echo "Actions:"
  echo "  -h, --help: Display this help message"
  echo ""
  echo "  lint: Run clippy"
  echo ""
  echo "  setup: Setup the project development environment"
  echo "  teardown: Teardown the project development environment"
  echo "  db-console: Open the database console"
  echo "  serve: Run the api server"
  echo "  test: Run tests"
  echo "  coverage: Run tests with coverage"
  echo ""
  echo "  install-deps: Install all dependencies"
  echo "  install-diesel: Install diesel_cli"
  echo "  install-tarpaulin: Install tarpaulin"
}

cleanup_profraw_files() {
  find . -type f -name "*.profraw" -delete
}

cd "$(dirname "$0")"/../

main() {
  action=${1-}

  # shift if length of arguments is greater than 0
  [[ $# -gt 0 ]] && shift 1

  case $action in
  "" | "-h" | "--help")
    help
    exit
    ;;
  "lint")
    echo ">>> Running clippy"
    cargo clippy --all-features "$@"
    cleanup_profraw_files
    ;;
  "setup")
    if [[ -z "${CI-}" ]]; then
      echo ">>> Setting up the project development environment"
      docker compose up -d --wait

      echo "DATABASE_URL=postgres://postgres:example@${POSTGRES_HOST-localhost}:${POSTGRES_PORT-5432}/${POSTGRES_DB-bearmark}" >.env
      echo ">>> Setting up database"
      ./scripts/bin/diesel migration run
    else
      echo ">>> Skip setting up the project development environment"

      echo "DATABASE_URL=postgres://postgres:example@${POSTGRES_HOST-db}:${POSTGRES_PORT-5432}/${POSTGRES_DB-bearmark}" >.env
      echo ">>> Setting up database"
      diesel migration run
    fi
    echo ">>> Done"
    ;;
  "teardown")
    echo ">>> Tearing down the project development environment"
    docker compose down
    echo ">>> Done"
    ;;
  "db-console")
    docker compose exec db psql -Upostgres ${POSTGRES_DB-bearmark}
    ;;
  "serve")
    echo ">>> Running the api server"
    cargo run --bin serve
    ;;
  "test")
    echo ">>> Running tests"
    cargo test -- --show-output --test-threads 1 "$@"
    cleanup_profraw_files
    ;;
  "coverage")
    echo ">>> Running tests with coverage"
    if [[ -z "${CI-}" ]]; then
      ./scripts/bin/cargo-tarpaulin --out html --skip-clean -- --show-output --test-threads 1 "$@"
    else
      cargo tarpaulin --out html --skip-clean -- --show-output --test-threads 1 "$@"
    fi
    echo "open file ./tarpaulin-report.html to see coverage report"
    cleanup_profraw_files
    ;;
  "coverage-xml")
    echo ">>> Running tests with coverage"
    cargo tarpaulin --out xml --skip-clean -- --show-output --test-threads 1 "$@"
    cleanup_profraw_files
    ;;
  "install-deps")
    $0 install-diesel
    $0 install-tarpaulin
    ;;
  "install-diesel")
    echo ">>> Installing diesel_cli"
    cargo install diesel_cli --no-default-features --features postgres --root ./scripts
    ;;
  "install-tarpaulin")
    echo ">>> Installing tarpaulin"
    cargo install cargo-tarpaulin --root ./scripts
    ;;
  *)
    echo "Error: Unknown action '$action'"
    help
    exit
    ;;
  esac
}

main "$@"
