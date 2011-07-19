# The SerialEventQueue Class
# --------------------------

# The SerialEventQueue class represents a queue of events destined for
# the server, each requiring a response.
#
# Elements are consumed from the head of the queue one at a time, and
# consumption is paused until a response is received and the event's
# callback is dispatched.
class SerialEventQueue

  # **constructor**: Construct a new SerialEventQueue given an event @destination
  constructor: (@destination_url) ->
    @messages = []

  # **put**: put a message and its callback on the "tail" of the
  # queue.
  put: (message, callback) ->
    @messages.unshift [message, callback]

  # **pollInterval**: Time in ms to wait between checking the head of
  # the queue.
  pollInterval: 100

  # **poll** polls the internal array for enqueued elements.  If
  # there are any, the "head" element is popped and its message
  # component is sent to @destination_url via POST.  The response is
  # passed to the event's callback, and periodic consumption resumes.
  poll: () =>
    if _.isEmpty(@messages)
      console.log("poll: outbound message queue empty")
      _.delay(@poll, @pollInterval)
    else
      console.log("poll: pending message, sending...")
      [message, callback] = @messages.pop()
      $.post @destination_url, {'event': message}, (response) =>
        callback(response)
        _.defer(@poll)
    return this


seq = new SerialEventQueue('/events').poll()

@responses = []

for i in [1..10]
  seq.put i, (resp) => @responses.push resp.state

seq.put "done", (resp) =>
  expectedOrder = (String(i) for i in [1..10])
  console.log expectedOrder
  console.log @responses
  if _.isEqual expectedOrder, @responses
    console.log "SUCCESS: The events were handled in the correct order"
  else
    console.log "FAILURE: The events were not handled in the correct order"