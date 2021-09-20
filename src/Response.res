@genType.import(("./shims/Webworker.shim", "ReResponse"))
type t 

// @genType.import(("./shims/Webworker.shim", "ReHeadersInit"))
type headers = Js.Dict.t<string>
type status = option<int> 
type statusText = option<string> 

// @genType.import(("./shims/Webworker.shim", "ReResponseInit"))
type responseInit = { headers, status, statusText }

@new
external make: (~body: string=?, ~init: responseInit=?, unit) => t = "Response";