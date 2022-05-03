type t

module SearchParams = {
  type t

  @send @return(nullable)
  external getParam: (t, ~key: string) => option<string> = "get"
}

@get
external getSearchParams: t => SearchParams.t = "searchParams"

@new
external make: string => t = "URL"
