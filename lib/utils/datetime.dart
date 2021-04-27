DateTime _now = new DateTime.now();
DateTime getNow() => new DateTime.now();
DateTime startOfToday() => DateTime(_now.year, _now.month, _now.day, 0, 0);
DateTime endOfToday() => DateTime(_now.year, _now.month, _now.day, 23, 59, 59);
DateTime startOfDayAgo(int ago) =>
    DateTime(_now.year, _now.month, _now.day, 0, 0)
        .subtract(Duration(days: ago));
DateTime endOfDayAgo(int ago) =>
    DateTime(_now.year, _now.month, _now.day, 23, 59, 59)
        .subtract(Duration(days: ago));
