using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace paas_demo.Models
{
    public class WebAppViewModel
    {
        public int Population { get; set; }
        public float AgeGreaterThan65 { get; set; }
        public float Black { get; set; }
        public float Latino { get; set; }
        public float White { get; set; }
        public float HighSchool { get; set; }
        public float Bachelors { get; set; }
        public float MedianHouseholdIncome { get; set; }
        public float BelowPovertylevel { get; set; }
        public float PopulationPSM { get; set; }

    }
}