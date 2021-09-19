import { handleRequest } from './Handler.gen'

addEventListener('fetch', (event) => {
  event.respondWith(handleRequest(event.request))
})
