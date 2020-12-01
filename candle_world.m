let
    ソース = 
        Csv.Document(
            Web.Contents("https://covid19.who.int/WHO-COVID-19-global-data.csv"),
            [
                Delimiter=",", 
                Columns=8, 
                Encoding=65001, 
                QuoteStyle=QuoteStyle.None
            ]
        ),
    昇格されたヘッダー数 = 
        Table.PromoteHeaders(
            ソース, 
            [PromoteAllScalars=true]
        ),
    変更された型 = 
        Table.TransformColumnTypes(
            昇格されたヘッダー数,
                {
                    {"Date_reported", type date}, 
                    {"Country_code", type text}, 
                    {"Country", type text}, 
                    {"WHO_region", type text}, 
                    {"New_cases", Int64.Type}, 
                    {"Cumulative_cases", Int64.Type}, 
                    {"New_deaths", Int64.Type}, 
                    {"Cumulative_deaths", Int64.Type}
                }
            ),
    追加されたWeekOfYear = 
        Table.AddColumn(
            変更された型, 
            "WeekOfYear", 
            each Date.Year([Date_reported]) * 100 + Date.WeekOfYear([Date_reported])
        ),
    追加されたWeekOfDay = 
        Table.AddColumn(
            追加されたWeekOfYear, 
            "WeekOfDay", 
            each Date.DayOfWeek([Date_reported])
        ),
    // もっとも古い日付と、もっとも新しい日付を取得
    OldestDay = List.Min(追加されたWeekOfDay[Date_reported]),
    LatestDay = List.Max(追加されたWeekOfDay[Date_reported]),
    //
    追加されたOpenNewCases = 
        Table.AddColumn(
            追加されたWeekOfDay, 
            "Open New Cases", 
            each if [Date_reported] = OldestDay or [WeekOfDay] = 0 then [New_cases] else 0
        ),
    追加されたOpenNewDeaths = 
        Table.AddColumn(
            追加されたOpenNewCases, 
            "Open New Deaths", 
            each if [Date_reported] = OldestDay or [WeekOfDay] = 0 then [New_deaths] else 0
        ),
    追加されたCloseNewCases = 
        Table.AddColumn(
            追加されたOpenNewDeaths, 
            "Close New Cases", 
            each if [Date_reported] = LatestDay or [WeekOfDay] = 6 then [New_cases] else 0
        ),
    追加されたCloseNewDeaths = 
        Table.AddColumn(
            追加されたCloseNewCases, 
            "Close New Deaths", 
            each if [Date_reported] = LatestDay or [WeekOfDay] = 6 then [New_deaths] else 0
        ),
    日付でグループ化された行 = 
        Table.Group(
            追加されたCloseNewDeaths, 
            {
                "Date_reported", 
                "WeekOfYear"
            }, 
            {
                {
                    "New_cases", 
                    each List.Sum([New_cases]), 
                    type nullable number
                }, 
                {
                    "New_deaths", 
                    each List.Sum([New_deaths]), 
                    type nullable number
                }, 
                {
                    "Open New Cases", 
                    each List.Sum([Open New Cases]), 
                    type number
                }, 
                {
                    "Open New Deaths", 
                    each List.Sum([Open New Deaths]), 
                    type number
                }, 
                {
                    "Close New Cases", 
                    each List.Sum([Close New Cases]), 
                    type number
                }, 
                {
                    "Close New Deaths", 
                    each List.Sum([Close New Deaths]), 
                    type number
                }
            }
        ),
    グループ化された行 = 
        Table.Group(
            日付でグループ化された行,
            {
                "WeekOfYear"
            }, 
            {
                {
                    "Open Date", 
                    each List.Min([Date_reported]), 
                    type nullable date
                },
                {
                    "Open New Cases", 
                    each List.Sum([Open New Cases]), 
                    type number
                }, 
                {
                    "Open New Deaths", 
                    each List.Sum([Open New Deaths]), 
                    type number
                }, 
                {
                    "Close New Cases", 
                    each List.Sum([Close New Cases]), 
                    type number
                }, 
                {
                    "Close New Deaths", 
                    each List.Sum([Close New Deaths]), 
                    type number
                },
                {
                    "Heigh New Cases", 
                    each List.Max([New_cases]), 
                    type nullable number
                }, 
                {
                    "Heigh New Deaths", 
                    each List.Max([New_deaths]), 
                    type nullable number
                }, 
                {
                    "Low New Cases", 
                    each List.Min([New_cases]), 
                    type nullable number
                }, 
                {
                    "Low New Deaths", 
                    each List.Min([New_deaths]), 
                    type nullable number
                } 
            }
        ),
    並べ替えられた行 = 
        Table.Sort(
            グループ化された行,
            {
                {
                    "Open Date", 
                    Order.Ascending
                }
            }
        )
in
    並べ替えられた行