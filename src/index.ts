import { handleRequest as postHandler } from './Handler.gen'
import { handleRequest as optionHandler } from './OptionHandler.gen'

addEventListener('fetch', (event) => {
  const request = event.request
  event.respondWith(
    (request.method === 'OPTIONS' ? optionHandler : postHandler)(request),
  )
})
