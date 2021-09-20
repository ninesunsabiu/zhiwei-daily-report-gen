type headers = Js.Dict.t<string>

@send
@return(nullable)
external getHeader: (headers, string) => option<string> = "get" 

@genType.import(("./shims/Webworker.shim", "ReRequest"))
type t = { headers } 

@send
external toJson: t => Js.Promise.t<Js.Json.t> = "json"