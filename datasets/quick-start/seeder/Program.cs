using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using QuickStart.Data;
using QuickStart.Data.Seeding;

// Creates the database file with the app's migrations and fills it with the seed data.
if (args.Length != 1)
{
    Console.Error.WriteLine("Usage: QuickStart.Seeder <database file>");
    return 1;
}

var connectionString = new SqliteConnectionStringBuilder { DataSource = Path.GetFullPath(args[0]) }.ToString();
var options = new DbContextOptionsBuilder<ApplicationDbContext>().UseSqlite(connectionString).Options;

using (var context = new ApplicationDbContext(options))
{
    context.Database.Migrate();
    DatabaseSeeder.Seed(context);
}

// Closes the pooled connection, which checkpoints the write-ahead log into the database file.
SqliteConnection.ClearAllPools();
return 0;
