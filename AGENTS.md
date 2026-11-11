# Voyager Travel generator

This repository generates sample apps from scenarios (a host and a dataset); read `README.md` first. Each generated app (by default `../voyager-travel-sample` and `../quick-start-sample`) is a separate repository with its own history.

- Generated apps must stay plain ASP.NET Core apps from a standard `dotnet new` template, with EF Core on SQLite and a seeded database. Do not add admin screens, UI libraries or references to any particular admin framework, here or in the generated apps.
- Prefer the .NET CLI in `generate.sh`; use a dataset's overlay only for files the CLI cannot produce, and its `customize.sh` only for changes the overlay cannot make.
- Datasets are self-contained: never share code, seed data or assets between them.
- Seeding happens in the generator: the seed code and its packages live in the dataset's `seeder/` and never go into the generated app.
- Seed data must be deterministic: draw all randomness from the seeder's fixed-seed Bogus fakers and anchor dates on the seeding day.
- Keep `datasets/voyager-travel/seeder/Catalog.cs` the single source for Voyager Travel's destinations and trips; its `tools/images/photos.mjs` parses it.
- Only bundle CC0 or public-domain photos, converted to WebP by `photos.mjs`.
- `./generate.sh --force` deletes the target. Never run it against a target that may contain someone's work without asking.
