#!/usr/bin/env bash
# Builds a fresh app from a scenario: a host (the dotnet new template and its arguments) and a dataset
# (the data model, its seeder and its assets), with a seeded SQLite database.
#
#   ./generate.sh [scenario] [target] [--host name] [--dataset name] [--force]
#
# The scenario defaults to voyager-travel and names a host, a dataset and a default target; --host and
# --dataset replace the scenario's. An existing target is only replaced with --force.
set -euo pipefail

seed_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scenario=""
target=""
host=""
dataset=""
force=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) force=true ;;
    --host) host="${2:?--host needs a name}"; shift ;;
    --dataset) dataset="${2:?--dataset needs a name}"; shift ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *)
      if [[ -z "$scenario" ]]; then
        scenario="$1"
      elif [[ -z "$target" ]]; then
        target="$1"
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
  shift
done

# Reads a config file, or fails with the names that do exist.
load() {
  local kind="$1" name="$2" file="$3" list="$4"
  if [[ ! -f "$file" ]]; then
    echo "Unknown $kind '$name'. Available: $(ls "$list" | sed 's/\.env$//' | tr '\n' ' ')" >&2
    exit 1
  fi
  # shellcheck source=/dev/null
  source "$file"
}

scenario="${scenario:-voyager-travel}"
HOST="" DATASET="" TARGET=""
load scenario "$scenario" "$seed_dir/scenarios/$scenario.env" "$seed_dir/scenarios"
host="${host:-$HOST}"
dataset="${dataset:-$DATASET}"
target="${target:-$seed_dir/$TARGET}"

TEMPLATE="" TEMPLATE_ARGS=""
load host "$host" "$seed_dir/hosts/$host.env" "$seed_dir/hosts"

dataset_dir="$seed_dir/datasets/$dataset"
PROJECT="" IDENTITY=false TEMPLATES=""
load dataset "$dataset" "$dataset_dir/dataset.env" "$seed_dir/datasets"

if [[ -n "$TEMPLATES" && " $TEMPLATES " != *" $TEMPLATE "* ]]; then
  echo "The $dataset dataset works with the $TEMPLATES template, not $TEMPLATE (host $host)." >&2
  exit 1
fi

target="$(realpath -m "$target")"
project="$PROJECT"
app="$target/src/$project"

if [[ "$target" == "$seed_dir" || "$target" == "$seed_dir"/* ]]; then
  echo "The target must be outside $seed_dir." >&2
  exit 1
fi

if [[ -e "$target" ]]; then
  if [[ "$force" != true ]]; then
    echo "$target already exists. Pass --force to delete and recreate it." >&2
    exit 1
  fi

  echo "Deleting $target"
  rm -rf "$target"
fi

mkdir -p "$target"
cd "$target"

echo "Creating the solution ($host host, $dataset dataset)"
dotnet new gitignore > /dev/null
dotnet new sln --name "$project" > /dev/null
# shellcheck disable=SC2086
dotnet new "$TEMPLATE" $TEMPLATE_ARGS --name "$project" --output "src/$project" > /dev/null
dotnet sln add "src/$project" > /dev/null

csproj="$app/$project.csproj"
target_framework="$(sed -nE 's/.*<TargetFramework>([^<]+)<\/TargetFramework>.*/\1/p' "$csproj")"

# The dataset's ApplicationDbContext replaces the template's, so both must use Identity or neither.
host_identity=false
if grep -q 'Include="Microsoft.AspNetCore.Identity.EntityFrameworkCore"' "$csproj"; then
  host_identity=true
fi
if [[ "$IDENTITY" != "$host_identity" ]]; then
  if [[ "$IDENTITY" == true ]]; then
    echo "The $dataset dataset needs a host with Identity, which $host doesn't include." >&2
  else
    echo "The $dataset dataset has no Identity, so it needs a host without it, unlike $host." >&2
  fi
  rm -rf "$target"
  exit 1
fi

# Templates without Identity have no EF Core: add it the way the Identity templates set it up.
if ! grep -q 'Include="Microsoft.EntityFrameworkCore.Sqlite"' "$csproj"; then
  echo "Adding EF Core"
  major="$(sed -nE 's/^net([0-9]+)\..*/\1/p' <<< "$target_framework")"
  ef_version="$(dotnet package search Microsoft.EntityFrameworkCore.Sqlite --exact-match --format json \
    | sed -nE 's/.*"version": "([^"]+)".*/\1/p' | grep -E "^$major\.[0-9]+\.[0-9]+$" | sort -V | tail -n 1 || true)"
  if [[ -z "$ef_version" ]]; then
    echo "No stable EF Core $major release found on nuget.org." >&2
    exit 1
  fi

  dotnet add "$csproj" package Microsoft.EntityFrameworkCore.Sqlite --version "$ef_version" > /dev/null
  dotnet add "$csproj" package Microsoft.EntityFrameworkCore.Design --version "$ef_version" > /dev/null

  perl -0777 -i -pe 's/\A\{(\r?\n)/{$1  "ConnectionStrings": {$1    "DefaultConnection": "DataSource=app.db;Cache=Shared"$1  },$1/ or die "No opening brace\n"' "$app/appsettings.json"
  PROJECT="$project" perl -0777 -i -pe '
    my ($eol) = /(\r?\n)/;
    s/^(\/\/ Add services to the container\.\r?\n)/$1var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? throw new InvalidOperationException("Connection string \x27DefaultConnection\x27 not found.");${eol}builder.Services.AddDbContext<ApplicationDbContext>(options =>${eol}    options.UseSqlite(connectionString));${eol}/m or die "No \"// Add services to the container.\" line\n";
    $_ = "using Microsoft.EntityFrameworkCore;${eol}using $ENV{PROJECT}.Data;${eol}${eol}" . $_;
  ' "$app/Program.cs"
else
  ef_version="$(sed -nE 's/.*Include="Microsoft\.EntityFrameworkCore\.Sqlite" Version="([^"]+)".*/\1/p' "$csproj")"
fi

dotnet new tool-manifest > /dev/null
dotnet tool install dotnet-ef --version "$ef_version" > /dev/null

echo "Adding the $dataset dataset"
rm -rf "$app/Data/Migrations" "$app/app.db"
cp -R "$dataset_dir/overlay/." "$target/"
if [[ -d "$dataset_dir/assets" ]]; then
  cp -R "$dataset_dir/assets/." "$app/wwwroot/"
fi
printf '\n# SQLite database, created and seeded by the generator\n*.db\n*.db-shm\n*.db-wal\n' >> .gitignore

if [[ -f "$dataset_dir/customize.sh" ]]; then
  TARGET="$target" APP="$app" PROJECT="$project" bash "$dataset_dir/customize.sh"
fi

echo "Creating the initial migration"
dotnet ef migrations add InitialCreate --project "src/$project" --output-dir Data/Migrations | grep -iE "error|warn" || true

echo "Creating and seeding the database"
dotnet run --project "$dataset_dir/seeder" --property:AppProject="$csproj" --property:AppTargetFramework="$target_framework" -- "$app/app.db"

echo "Done: $target"
echo "Run it with: dotnet run --project $target/src/$project"
