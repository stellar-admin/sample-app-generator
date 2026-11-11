# Sample app generator

Generates sample apps from scratch: a stock ASP.NET Core template, a data model, a seeded SQLite database and its assets. The generator does the seeding, so the generated app contains no seeding code.

Use it to get a clean, realistic starting point whenever you need one, for example to rerun an experiment from the beginning or after changing a data model.

## Scenarios, hosts and datasets

A scenario combines a host and a dataset, and names the default target:

- **Hosts** (`hosts/*.env`) say which `dotnet new` template to use and with which arguments: `mvc` and `webapp` (Razor Pages), each with Identity (`-identity`) or without.
- **Datasets** (`datasets/<name>/`) hold a data model, its seeder and its assets, and are independent of each other.
- **Scenarios** (`scenarios/*.env`) pick one of each: `voyager-travel` (the full Voyager Travel back office on `mvc-identity`) and `quick-start` (the admin panel quick start's trips and departures on `mvc`).

## Generate an app

```bash
./generate.sh                                        # the voyager-travel scenario, in ../voyager-travel-sample
./generate.sh quick-start                            # the quick-start scenario, in ../quick-start-sample
./generate.sh voyager-travel ../voyager-travel-2     # a scenario in another directory
./generate.sh quick-start /tmp/qs --host webapp      # replace the scenario's host (or --dataset)
./generate.sh quick-start --force                    # delete and recreate an existing target
```

The script uses the .NET CLI for everything it can:

1. `dotnet new gitignore`, `sln` and the host's template with its arguments.
2. Checks that the dataset and the host agree on Identity, and that the dataset supports the template.
3. For a host without Identity, adds EF Core on SQLite the way the Identity templates set it up: the `Sqlite` and `Design` packages (the latest release for the app's .NET version), a `DefaultConnection` and `AddDbContext<ApplicationDbContext>` in `Program.cs`.
4. `dotnet new tool-manifest` and `dotnet tool install dotnet-ef`, matching the app's EF Core version.
5. Copies the dataset's `overlay/` over the target and its `assets/` into `wwwroot`, and runs its `customize.sh` if it has one.
6. `dotnet ef migrations add InitialCreate`.
7. Runs the dataset's `seeder/`, which builds against the generated app, applies its migration to `src/<Project>/app.db` and fills it with the seed data.

The target is not a Git repository; run `git init` yourself if you want to keep it. To get fresh data, generate the app again. See the generated README for what the app contains.

Requires a .NET SDK and `perl`. The generated app has no `global.json`, so it builds with the newest installed SDK and targets its .NET version.

## Add a dataset

Create `datasets/<name>/` with:

- `dataset.env`: `PROJECT` (the project and namespace name), `IDENTITY` (`true` when its context is an `IdentityDbContext`, so it needs a host with Identity, otherwise `false`), and optionally `TEMPLATES`, the templates it works with when it depends on one (for example by replacing `Program.cs`).
- `overlay/`: copied over the target. It holds at least the model and `src/<Project>/Data/ApplicationDbContext.cs` in the `<Project>.Data` namespace, the name the Identity templates use and the generator registers, and the app's `README.md`.
- `seeder/`: a console project that references the app through the `AppProject` and `AppTargetFramework` properties and takes the database file as its argument. See an existing dataset's seeder.
- `assets/` (optional): copied into `wwwroot`.
- `customize.sh` (optional): changes the overlay can't make, run with `TARGET`, `APP` and `PROJECT` set.

Then add a scenario in `scenarios/<name>.env` with its `HOST`, `DATASET` and `TARGET` (relative to this directory).

## Change a data model

Edit the files under the dataset's `overlay/src/<Project>` (entities in `Models/`, the context in `Data/`) and its seed data in `seeder/`, then generate again. Each generated app has a single `InitialCreate` migration, so there is never a migration history to maintain.

## Voyager Travel images

`datasets/voyager-travel/assets/images/` is committed and copied into each generated app as-is. The tools that produce it live in `datasets/voyager-travel/tools/images` (Node.js):

```bash
cd datasets/voyager-travel/tools/images
npm install
node illustrations.mjs     # avatars and supplier logos (DiceBear, CC0)
node photos.mjs            # missing photos from Openverse (CC0 and public domain only)
node photos.mjs kyoto      # replace a destination's photos with the next search results
node photos.mjs hotels     # replace a whole pool (hotels, or an excursion kind such as cooking-class)
```

`photos.mjs` reads destinations and trips from `seeder/Catalog.cs`, records each pick and its licence in `assets/images/photos.json`, and writes `assets/images/CREDITS.md`. Rejected photos are remembered, so replacing one never brings it back. Openverse allows 200 anonymous searches a day; search results are cached in `tools/images/.cache`.
