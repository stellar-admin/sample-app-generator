using System.ComponentModel.DataAnnotations;

namespace QuickStart.Models;

public class Departure
{
    public int Id { get; set; }

    public int TripId { get; set; }

    public Trip Trip { get; set; } = null!;

    [Display(Name = "Start date")]
    public DateOnly StartDate { get; set; }

    public int Capacity { get; set; }

    public DepartureStatus Status { get; set; } = DepartureStatus.Scheduled;
}
