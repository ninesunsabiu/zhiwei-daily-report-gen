
@genType.import(("./shims/Webworker.shim", "RescriptResponse"))
type response 

@genType.import(("./shims/Webworker.shim", "ReRequest"))
type request

@genType
let handleRequest: request => Js.Promise.t<response>