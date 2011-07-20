# Simple log and debug handlers.

window.log = (msg) ->
  console.log msg if @console

window.debug = (msg) ->
  log "[debug] " + msg


# The OutboundEventQueue Class
# ----------------------------

# The OutboundEventQueue class represents a queue of events destined
# for the server, each requiring a response before subsequent events
# are processed.
#
# To create a new queue, and put messages on it:
#
# q = new OutboundEventQueue('/events').start()
# q.put 'test', (response) -> console.log response
#
# Events, added with .put, are consumed from the head of the queue one
# at a time, and consumption is paused until a response is received
# and the event's callback is dispatched.
class OutboundEventQueue

  # **constructor**: Construct a new OutboundEventQueue given an event.
  #
  # @destination_url is a URL to POST events to, as
  # JSON objects in the 'event' parameter.
  #
  # @interval optional; time in ms to wait between checking the
  # head of the queue.
  constructor: (@destination_url, @interval = 1000) ->
    @messages = []

  # **put**: Adds message to outbound message queue, and POSTs it to
  # the server.  The server's response is passed to callback.
  put: (message, callback) ->
    @messages.unshift [message, callback]

  # **start** polls the internal array for enqueued elements.  If
  # there are any, the "head" element is popped and its message
  # component is sent to @destination_url via POST.  The response is
  # passed to the event's callback, and periodic consumption resumes.
  start: () =>
    if _.isEmpty @messages
      debug "OutboundEventQueue: empty, delaying"
      _.delay @start, @interval
    else
      debug "OutboundEventQueue: not empty, processing"
      [message, callback] = @messages.pop()
      $.ajax {
        type: 'POST',
        url: @destination_url,
        data: { 'message' : message },
        success: (response) =>
          callback(response)
          debug "OutboundEventQueue: event processed, deferring"
          _.defer @start
        }
    return this

  # **stop**: Stops the queue from processing events.  The queue
  # cannot be restarted.
  stop: () ->
    @start = () ->
      log "OutboundEventQueue: stopped."

    @put = () ->
      throw "OutboundEventQueue: .put invalid; the queue is stopped."

# The PeriodicMessager Class
# ----------------------------

# Given an OutboundEventQueue and a message, adds the message to the
# queue every @interval milliseconds.
#
# To create a new queue and messager, and send a heartbeat message periodically to the server:
#
# q = new OutboundEventQueue('/events', 1000).start()
# heartbeat = new PeriodicMessager(q, 'heartbeat', () -> console.log "heartbeat returned", 2000).start()
#
# Messages may take as long as @interval + the underlying event
# queue's poll interval to actually process.
#
# Once stopped, PeriodicMessagers cannot be restarted.
class PeriodicMessager

  # **constructor**: Takes a destination queue, message, callback, and interval.
  constructor: (@queue, @message, @callback, @interval) ->

  # **start**: Begin periodically putting @message on @queue, and
  # continue to do so every @interval milliseconds until .stop is
  # called.
  start: () =>
    @queue.put @message, @callback
    _.delay @start, @interval
    return this

  # **stop**: Stops the messager from generating events.  The messager
  # cannot be restarted.
  stop: () ->
    @start = () ->
      log "PeriodicMessager: stopped."





# The actual Shout2 Application
# ----------------------------

$ () ->

  # Given a state (resp), assures the UI is up to date.
  updateState = (resp) ->
    $('#shouts').empty()
    $.template "shoutTemplate", "<li><h2>${shout}</h2></li>"
    $.tmpl("shoutTemplate", resp.shouts).appendTo "#shouts"

  # Wire up an outbound event queue and periodic updater
  q = new OutboundEventQueue('/events', 1000)
  updater = new PeriodicMessager(q, {'cmd': 'update'}, updateState, 3000)

  # Given a shout, put the appropriate command and a callback on the
  # queue
  sendShout = (shout) ->
    q.put {'cmd': 'shout', 'text': shout}, (resp) ->
      $('#msg').val('')
      updateState

  # Wire form submit to shout submission
  $('#shoutform').submit (e) ->
    sendShout $('#msg').val()
    e.preventDefault()

  # Start the queue and updater processes
  q.start()
  updater.start()