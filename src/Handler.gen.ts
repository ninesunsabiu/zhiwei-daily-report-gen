/* TypeScript file generated from Handler.resi by genType. */
/* eslint-disable import/first */

// @ts-ignore: Implicit any on import
import * as HandlerBS__Es6Import from './Handler.bs'
const HandlerBS: any = HandlerBS__Es6Import

import type { ReRequest as $$request } from './shims/Webworker.shim'

import type { RescriptResponse as $$response } from './shims/Webworker.shim'

// tslint:disable-next-line:interface-over-type-literal
export type response = $$response

// tslint:disable-next-line:interface-over-type-literal
export type request = $$request

export const handleRequest: (_1: request) => Promise<response> =
  HandlerBS.handleRequest
