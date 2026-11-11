using Bogus;
using Microsoft.EntityFrameworkCore;
using QuickStart.Models;

namespace QuickStart.Data.Seeding;

// Generates the same data on every run, relative to the day the database is created.
public static class DatabaseSeeder
{
    // A selection of the Voyager Travel trips, with the same codes and titles.
    private static readonly (string Code, string Title, int DurationDays, int Capacity)[] Trips =
    [
        ("VT-JP-01", "Temples & Tea Ceremonies of Kyoto", 8, 16),
        ("VT-JP-02", "Tokyo to Kyoto by Bullet Train", 10, 16),
        ("VT-JP-04", "Osaka Street Food Safari", 5, 12),
        ("VT-IT-01", "Renaissance Florence & Tuscan Hills", 7, 16),
        ("VT-IT-03", "Amalfi Coast Path of the Gods", 7, 12),
        ("VT-IT-04", "Rome in Depth", 5, 16),
        ("VT-IT-05", "Dolomites Hut-to-Hut Trek", 9, 12),
        ("VT-PE-01", "Inca Trail to Machu Picchu", 10, 12),
        ("VT-PE-02", "Sacred Valley Markets & Weavers", 7, 16),
        ("VT-MA-01", "Marrakech & the Atlas Mountains", 7, 16),
    ];

    public static void Seed(DbContext context)
    {
        if (context.Set<Trip>().Any())
        {
            return;
        }

        context.AddRange(Generate(DateOnly.FromDateTime(DateTime.UtcNow)));
        context.SaveChanges();
    }

    private static List<Trip> Generate(DateOnly today)
    {
        var faker = new Faker("en") { Random = new Randomizer(20261111) };
        var trips = new List<Trip>();

        foreach (var (code, title, durationDays, capacity) in Trips)
        {
            var trip = new Trip { Code = code, Title = title, DurationDays = durationDays };
            var start = today.AddDays(-180 + faker.Random.Int(0, 40));

            while (start < today.AddDays(360))
            {
                var daysAway = start.DayNumber - today.DayNumber;
                trip.Departures.Add(new Departure
                {
                    StartDate = start,
                    Capacity = capacity,
                    Status = faker.Random.Bool(0.05f) ? DepartureStatus.Cancelled : daysAway switch
                    {
                        < 60 => faker.Random.Bool(0.3f) ? DepartureStatus.SoldOut : DepartureStatus.Confirmed,
                        < 150 => faker.Random.Bool(0.5f) ? DepartureStatus.Confirmed : DepartureStatus.Scheduled,
                        _ => DepartureStatus.Scheduled,
                    },
                });
                start = start.AddDays(faker.Random.Int(38, 52));
            }

            trips.Add(trip);
        }

        return trips;
    }
}
