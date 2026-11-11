using Microsoft.EntityFrameworkCore;
using QuickStart.Models;

namespace QuickStart.Data;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : DbContext(options)
{
    public DbSet<Departure> Departures => Set<Departure>();

    public DbSet<Trip> Trips => Set<Trip>();
}
