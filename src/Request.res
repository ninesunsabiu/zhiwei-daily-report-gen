@genType.import(("./shims/Webworker.shim", "ReRequest"))
type t 

@send external toJson: t => Js.Promise.t<Js.Json.t> = "json";