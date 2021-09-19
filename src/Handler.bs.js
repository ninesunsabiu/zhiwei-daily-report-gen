// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Jzon from "../node_modules/rescript-jzon/src/Jzon.bs.js";
import * as Js_json from "../node_modules/rescript/lib/es6/js_json.js";
import * as Belt_Option from "../node_modules/rescript/lib/es6/belt_Option.js";
import * as Belt_Result from "../node_modules/rescript/lib/es6/belt_Result.js";
import * as Caml_option from "../node_modules/rescript/lib/es6/caml_option.js";

var workFieldValueEntity = Jzon.object2((function (param) {
        return [
                param.id,
                param.name
              ];
      }), (function (param) {
        return {
                TAG: /* Ok */0,
                _0: {
                  id: param[0],
                  name: param[1]
                }
              };
      }), Jzon.field("id", Jzon.string), Jzon.field("name", Jzon.string));

var workFieldValueArray = Jzon.array(workFieldValueEntity);

var workFieldValue = Jzon.custom((function (value) {
        switch (value.TAG | 0) {
          case /* ValueNumber */0 :
              return Jzon.encodeWith(value._0, Jzon.$$int);
          case /* ValueStr */1 :
              return Jzon.encodeWith(value._0, Jzon.string);
          case /* ValueArray */2 :
              return Jzon.encodeWith(value._0, workFieldValueArray);
          
        }
      }), (function (jsonValue) {
        var match = Js_json.classify(jsonValue);
        if (typeof match === "number") {
          return {
                  TAG: /* Ok */0,
                  _0: {
                    TAG: /* ValueStr */1,
                    _0: ""
                  }
                };
        }
        switch (match.TAG | 0) {
          case /* JSONString */0 :
              return Belt_Result.map(Jzon.decodeWith(jsonValue, Jzon.string), (function (it) {
                            return {
                                    TAG: /* ValueStr */1,
                                    _0: it
                                  };
                          }));
          case /* JSONNumber */1 :
              return Belt_Result.map(Jzon.decodeWith(jsonValue, Jzon.$$int), (function (it) {
                            return {
                                    TAG: /* ValueNumber */0,
                                    _0: it
                                  };
                          }));
          case /* JSONArray */3 :
              return Belt_Result.map(Jzon.decodeWith(jsonValue, workFieldValueArray), (function (it) {
                            return {
                                    TAG: /* ValueArray */2,
                                    _0: it
                                  };
                          }));
          default:
            return {
                    TAG: /* Ok */0,
                    _0: {
                      TAG: /* ValueStr */1,
                      _0: ""
                    }
                  };
        }
      }));

var workField = Jzon.object2((function (param) {
        return [
                param.flag,
                param.value
              ];
      }), (function (param) {
        return {
                TAG: /* Ok */0,
                _0: {
                  flag: param[0],
                  value: param[1]
                }
              };
      }), Jzon.field("flag", Jzon.string), Jzon.$$default(Jzon.field("value", workFieldValue), {
          TAG: /* ValueStr */1,
          _0: "__unkonwn"
        }));

var doneWork = Jzon.object1((function (param) {
        return param.fields;
      }), (function (fields) {
        return {
                TAG: /* Ok */0,
                _0: {
                  fields: fields
                }
              };
      }), Jzon.field("fields", Jzon.array(workField)));

var body = Jzon.custom((function (tuple) {
        return [
                Jzon.encodeWith(tuple[0], Jzon.array(doneWork)),
                Jzon.encodeWith(tuple[1], Jzon.array(Jzon.string))
              ];
      }), (function (jsonValue) {
        var array = Js_json.classify(jsonValue);
        if (typeof array !== "number" && array.TAG === /* JSONArray */3) {
          var array$1 = array._0;
          var getDecodeResult = function (codec, json) {
            var ret = Jzon.decodeWith(json, codec);
            if (ret.TAG === /* Ok */0) {
              return ret._0;
            } else {
              return [];
            }
          };
          if (array$1.length !== 2) {
            return {
                    TAG: /* Error */1,
                    _0: {
                      NAME: "UnexpectedJsonValue",
                      VAL: [
                        [{
                            TAG: /* Field */0,
                            _0: "body"
                          }],
                        ""
                      ]
                    }
                  };
          }
          var doneWorkArray = array$1[0];
          var predicateArray = array$1[1];
          return {
                  TAG: /* Ok */0,
                  _0: [
                    getDecodeResult(Jzon.array(doneWork), doneWorkArray),
                    getDecodeResult(Jzon.array(Jzon.string), predicateArray)
                  ]
                };
        }
        return {
                TAG: /* Error */1,
                _0: {
                  NAME: "UnexpectedJsonValue",
                  VAL: [
                    [{
                        TAG: /* Field */0,
                        _0: "body"
                      }],
                    ""
                  ]
                }
              };
      }));

function handleRequest(req) {
  var dealDoneWork = function (doneWorks) {
    return doneWorks.map(function (doneWork) {
                var findValueByFlag = function (flagKey) {
                  return Belt_Option.getWithDefault(Belt_Option.map(Caml_option.undefined_to_opt(doneWork.fields.find(function (param) {
                                          return param.flag === flagKey;
                                        })), (function (param) {
                                    var value = param.value;
                                    switch (value.TAG | 0) {
                                      case /* ValueNumber */0 :
                                          return String(value._0);
                                      case /* ValueStr */1 :
                                          return value._0;
                                      case /* ValueArray */2 :
                                          var a = value._0;
                                          if (a.length !== 1) {
                                            return "";
                                          } else {
                                            return a[0].name;
                                          }
                                      
                                    }
                                  })), "");
                };
                var code = findValueByFlag("sourceField4");
                var name = findValueByFlag("771ac1a5-fca5-4af2-b744-27b16e989b18ANY-TRAIT-ID");
                var scope = findValueByFlag("78e0707c875f40a790a1387c8e64e54c");
                return {
                        code: code,
                        name: name,
                        scope: scope
                      };
              });
  };
  return req.json().then(function (body$1) {
                  return Jzon.decodeWith(body$1, body);
                }).then(function (val) {
                if (val.TAG === /* Ok */0) {
                  return Belt_Option.getWithDefault(JSON.stringify(dealDoneWork(val._0[0])), "test");
                } else {
                  return Jzon.DecodingError.toString(val._0);
                }
              }).then(function (message) {
              return new Response(message);
            });
}

export {
  handleRequest ,
  
}
/* workFieldValueEntity Not a pure module */
