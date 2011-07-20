# put n. message/events on the queue.  verify they are processed in the correct order.
queueTest = (n) ->
  q = new OutboundEventQueue('/events').start()
  @responses = []

  # put 10 events whose callback appends to @responses in the queue
  for i in [1..n]
    q.put i, (resp) => @responses.push resp.state

  q.put "done", (resp) =>

    expected = (String(i) for i in [1..n])

    if _.isEqual @responses, expected
      log "SUCCESS: The events were handled in the correct order"
    else
      log "FAILURE: The events were not handled in the correct order"

    console.log "expected: " + expected
    console.log "@responses: " + @responses

    q.stop()

queueTest 10

# test that we can periodically update
intervalTest = () ->
  q = new OutboundEventQueue('/events', 1000).start()
  heartbeat = new PeriodicMessager(q, ['heartbeat', () -> debug "heartbeat returned"], 2000).start()
  #heartbeat.stop()

intervalTest()