class FramePipe
  constructor: (@pipeType, @dstFrame = self, @uid) ->
    @_listeners = {}
    @uid or= FramePipe.uniqId('pipe_')
    FramePipe.knownPipes[@uid] = this
    @post '__hello__'


  post: (raw, callback) ->
    FramePipe.post(@dstFrame, @pipeType, @uid, raw, callback)


  ping: -> @post('__ping__')


  # TODO: This listenerName stuff is convenient for listen/unlisten, but seems
  # clunky. Would be better to just pass a function.
  listen: (listenerName, fn) ->
    @_listeners[listenerName] = fn


  unlisten: (listenerName) ->
    delete @_listeners[listenerName]


  _flushListeners: (msg) ->
    for listenerName, fn of @_listeners
      result = fn(msg.message, msg)
      # TODO: Callback with result of listener if msg.messageUid is set.


  log: (args...) ->
    FramePipe.log @uid, args...


  @all: ->
    (pipe for pipeUid, pipe of @knownPipes)


  @each: (fn) ->
    fn(pipe) for pipeUid, pipe of @knownPipes


  @_onFindQueue = {}
  @onFind: (pipeType, fn) ->
    # Push this function onto a queue so it can be run as soon as a new pipe
    # is found. (That call is handled in the dispatcher.)
    @_onFindQueue[pipeType] = @_onFindQueue[pipeType] or []
    @_onFindQueue[pipeType].push(fn)

    # For any pipes we already know about, run the function immediately.
    @each (pipe) -> fn(pipe) if pipe.pipeType is pipeType


  @_flushFindQueue: (pipeType, pipe) ->
    if @_onFindQueue[pipeType]
      fn(pipe) for fn in @_onFindQueue[pipeType]


  @knownFrames: {}
  @knownPipes: {}
  @listen: ->
    return if @_dispatcher

    @_dispatcher = (event) =>
      str = event.data
      frame = event.source
      if @isValidMessage(str)
        deserialized = @deserializeMessage(str)

        if deserialized.message is '__hello__'
          # If a frame we've never heard of is declaring itself, note its uid
          # and frame, then have all our local frames sync up with it.
          if !@knownFrames[deserialized.frameUid]
            @knownFrames[deserialized.frameUid] = frame

          # If a pipe we've never heard of is declaring itself, make a new
          # FramePipe object for it and save it.
          if deserialized.pipeUid and !@knownPipes[deserialized.pipeUid]
            pipe = new FramePipe(deserialized.pipeType, frame, deserialized.pipeUid)
            @_flushFindQueue(deserialized.pipeType, pipe)
        else if deserialized.message is '__discover__'
          @each (pipe) -> pipe.post '__hello__'
        else if pipe = @knownPipes[deserialized.pipeUid]
          if deserialized.message is '__ping__'
            pipe.post '__pong__'
          else
            pipe._flushListeners(deserialized)
        else
          @log "Unknown pipe #{deserialized.pipeUid}", deserialized

    if window.addEventListener
      window.addEventListener 'message', @_dispatcher
    else
      window.attachEvent 'onmessage', @_dispatcher


  # We only ever call this in a testing environment, when we need to fully
  # reload the library.
  @stopListening: ->
    return unless @_dispatcher

    if window.removeEventListener
      window.removeEventListener 'message', @_dispatcher
    else
      window.detachEvent 'onmessage', @_dispatcher

    @_dispatcher = null


  # Post a 'discover' message to all candidate frames that might have a
  # FramePipe. If one of those frames is already initialized, it will have all
  # its local frames post 'hello'.
  #
  # TODO: Allow automatic scoping of frames somehow. Query selector? Domain
  # of iframes? Also, determine if scoping is really necessary. If it's not,
  # then that's the ideal solution.
  @discover: (frames = window.frames) ->
    @post(frame, null, null, '__discover__') for frame in frames
    return


  @post: (frame, pipeType, pipeUid, raw, callback) ->
    messageUid = if callback then @uniqId('msg_') else null
    signed = @signMessage(raw, pipeType, pipeUid, messageUid)
    serialized = @serializeMessage(signed)
    frame.postMessage serialized, '*'
    @bindCallback(signed.messageUid, callback) if callback
    return


  # So both ends of a pipe know they're communicating with the same version of
  # the library.
  @version: 'FramePipe1'


  @signMessage: (raw, pipeType, pipeUid, messageUid) ->
    {
      version: @version
      frameUid: @frameUid
      pipeType: pipeType
      pipeUid: pipeUid
      messageUid: messageUid
      message: raw
    }


  # TODO: Only serialize/deserialize to a string when we need to. Also,
  # determine if that's the best strategy, considering e.g. the Facebook SDK's
  # loud warnings about non-string values being used with postMessage.
  #
  # TODO: Serialize msg.message as JSON if an object literal is passed in.
  #
  # Serialized message format looks like:
  #
  #     version:pipeType:frameUid:pipeUid:messageUid
  #     messageBody
  @serializeMessage: (msg) ->
    [
      msg.version
      msg.pipeType
      msg.frameUid
      msg.pipeUid
      msg.messageUid
    ].join(':') + "\n" + msg.message


  # TODO: We might want multiple versions of this method: one that checks if
  # it's a valid "global" message (that's what this actually does), and one
  # that checks if it's a valid message to a specific pipe, which this does not
  # do.
  @isValidMessage: (str) ->
    sig = @deserializeSignature(str)
    sig.version is @version and sig.frameUid


  # This needs to function on any value of str, so if str doesn't match the
  # expected serialized message format, it should return falsy values for
  # everything.
  @deserializeSignature: (str) ->
    endOfFirstLineIndex = str.indexOf?("\n") or -1
    firstLine = str.substring(0, endOfFirstLineIndex)
    [version, pipeType, frameUid, pipeUid, messageUid] = str.split(':')
    {
      version: version
      pipeType: pipeType
      frameUid: frameUid
      pipeUid: pipeUid
      messageUid: messageUid
    }


  # Here we can assume str is a valid signed and serialized message. The
  # message body is just everything after the first line (which has the
  # signature).
  @deserializeMessage: (str) ->
    result = @deserializeSignature(str)
    endOfFirstLineIndex = str.indexOf("\n")
    msg = str.substring(endOfFirstLineIndex + 1, str.length)
    result.message = msg
    result


  # TODO: Finish integrating this with callbacks.
  @_callbacks: {}
  @bindCallback: (messageUid, callback) ->
    wrapped = ->
      try
        callback()
      catch e
        if typeof e is 'string'
          console?.log e
        else
          console?.log e.message
          console?.log e.stack
      delete @_callbacks[messageUid]

    @_callbacks[messageUid] = wrapped


  @uniqId: (prefix = '') ->
    prefix + (
      for i in [0...4]
        (Math.random() * Math.pow(36, 5) << 0).toString(36)
    ).join('')


  @initialize: ->
    FramePipe.frameUid = FramePipe.uniqId('frame_')
    FramePipe.discover()
    FramePipe.listen()


  @reset: ->
    @stopListening()
    @_callbacks = {}
    @_onFindQueue = {}
    @knownPipes = {}
    @knownFrames = {}


  @isInitialized: -> !!FramePipe.frameUid


  @log: (args...) ->
    console?.log location.pathname, args...


window.framePipeOptions or= {}


if !FramePipe.isInitialized() and framePipeOptions.autoInitialize isnt false
  FramePipe.initialize()
