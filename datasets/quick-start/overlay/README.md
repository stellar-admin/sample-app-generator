# Quick start

The starting point of the StellarAdmin admin panel quick start: an ASP.NET Core MVC app with Entity Framework Core on SQLite, and a travel company's trips and their departures.

## Run

```bash
dotnet run --project src/QuickStart
```

The database, `src/QuickStart/app.db`, comes seeded. Seeded dates are relative to the day it was created.

After adding a migration, apply it with `dotnet ef database update --project src/QuickStart`. Restore the local `dotnet-ef` tool with `dotnet tool restore` first.

## Data model

The model lives in `src/QuickStart/Models` and the `ApplicationDbContext` in `src/QuickStart/Data`.

- **Trips:** a code, a title and a duration in days.
- **Departures:** a trip's start date, capacity and status (scheduled, confirmed, sold out or cancelled).
