let
    ソース = 
        Csv.Document(
            Web.Contents("https://covid19.who.int/WHO-COVID-19-global-data.csv"),
            [Delimiter=",", 
            Columns=8, 
            Encoding=65001, 
            QuoteStyle=QuoteStyle.None]
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
        並べ替えられた行 = 
            Table.Sort(
                変更された型,
                {
                    {"Date_reported", Order.Ascending}
                }
            )
in
    並べ替えられた行