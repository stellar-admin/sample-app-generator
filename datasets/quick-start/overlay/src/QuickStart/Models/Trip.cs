using System.ComponentModel.DataAnnotations;

namespace QuickStart.Models;

public class Trip
{
    public int Id { get; set; }

    public required string Code { get; set; }

    public required string Title { get; set; }

    [Display(Name = "Duration (days)")]
    public int DurationDays { get; set; }

    public List<Departure> Departures { get; set; } = [];
}
