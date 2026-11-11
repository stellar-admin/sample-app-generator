# Voyager Travel generator

Generates the Voyager Travel app from scratch: the stock ASP.NET Core MVC template with Identity on SQLite, plus a domain model for a fictitious small-group tour operator, a seeded database and bundled images. The generator does the seeding, so the generated app contains no seeding code.

Use it to get a clean, realistic starting point whenever you need one, for example to rerun an experiment from the beginning or after changing the data model.

## Generate the app

```bash
./generate.sh                            # creates ../voyager-travel-sample
./generate.sh ../voyager-travel-sample-2 # or any other directory
./generate.sh --force                    # deletes and recreates an existing target
```

The script uses the .NET CLI for everything it can:

1. `dotnet new gitignore`, `sln` and `mvc --auth Individual` (SQLite is the template's default).
2. `dotnet new tool-manifest` and `dotnet tool install dotnet-ef`, matching the template's EF Core version.
3. Copies `overlay/` over the template: the domain model, `ApplicationUser`, `ApplicationDbContext`, `Program.cs` and the app's README.
4. Copies `assets/images/` to `wwwroot/images`.
5. `dotnet ef migrations add InitialCreate`.
6. Runs the seeder in `seeder/`, which builds against the generated app, applies its migration to `src/VoyagerTravel/app.db` and fills it with the seed data.

The target is not a Git repository; run `git init` yourself if you want to keep it. To get fresh data, generate the app again. See the generated README for the seeded accounts.

Requires a .NET 10 SDK and `perl`. The generated app has no `global.json`, so it builds with whichever .NET 10 SDK is installed.

## Change the data model

Edit the files under `overlay/src/VoyagerTravel` (entities in `Models/`, the context in `Data/`) and the seed data in `seeder/`, then generate again. Each generated app has a single `InitialCreate` migration, so there is never a migration history to maintain.

## Images

`assets/images/` is committed and copied into each generated app as-is. The tools that produce it live in `tools/images` (Node.js):

```bash
cd tools/images
npm install
node illustrations.mjs     # avatars and supplier logos (DiceBear, CC0)
node photos.mjs            # missing photos from Openverse (CC0 and public domain only)
node photos.mjs kyoto      # replace a destination's photos with the next search results
node photos.mjs hotels     # replace a whole pool (hotels, or an excursion kind such as cooking-class)
```

`photos.mjs` reads destinations and trips from `seeder/Catalog.cs`, records each pick and its licence in `assets/images/photos.json`, and writes `assets/images/CREDITS.md`. Rejected photos are remembered, so replacing one never brings it back. Openverse allows 200 anonymous searches a day; search results are cached in `tools/images/.cache`.
