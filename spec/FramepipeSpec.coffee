testElem = null
theFrame = null
frame1 = null
frame2 = null
thePipe = null
pipe1 = null
pipe2 = null


injectIframe = (path) ->
  testElem.innerHTML = """
<iframe id="theframe" src="//differenthost.dev:8454/#{path}" allowtransparency="true" frameborder="0" scrolling="no" allowfullscreen mozallowfullscreen webkitallowfullscreen oallowfullscreen msallowfullscreen width="300" height="150"></iframe>
  """
  theFrame = document.getElementById('theframe')


injectTwoIframes = (path1, path2) ->
  testElem.innerHTML = """
<iframe id="frame1" src="//differenthost.dev:8454/#{path1}" allowtransparency="true" frameborder="0" scrolling="no" allowfullscreen mozallowfullscreen webkitallowfullscreen oallowfullscreen msallowfullscreen width="300" height="150"></iframe>
<iframe id="frame2" src="//differenthost.dev:8454/#{path2}" allowtransparency="true" frameborder="0" scrolling="no" allowfullscreen mozallowfullscreen webkitallowfullscreen oallowfullscreen msallowfullscreen width="300" height="150"></iframe>
  """
  frame1 = document.getElementById('frame1')
  frame2 = document.getElementById('frame2')


injectOnePipe = -> injectIframe('OnePipe.html')
injectTwoPipesSameType = -> injectIframe('TwoPipesSameType.html')
injectTwoPipesDifferentTypes = -> injectIframe('TwoPipesDifferentTypes.html')


describe 'FramePipe', ->
  beforeEach ->
    testElem = document.getElementById('test')
    testElem.innerHTML = ''
    FramePipe.reset()

  describe 'when the outer FramePipe script is initialized after the iframe', ->
    describe 'one pipe', ->
      beforeEach ->
        injectOnePipe()
        waits 100

      describe 'onFind', ->
        it 'runs once', ->
          thePipes = []
          FramePipe.onFind 'TestPipe', (pipe) -> thePipes.push(pipe)
          FramePipe.initialize()
          waitsFor -> thePipes.length is 1
          waits 10
          waitsFor ->
            try
              theFrame.contentWindow
            catch e
              false
          runs ->
            expect(thePipes.length).toBe(1)
            expect(thePipes[0].dstFrame).toBe(theFrame.contentWindow)
            expect(FramePipe.all().length).toBe(1)

        describe 'when called twice', ->
          it 'runs twice', ->
            thePipes = []
            FramePipe.onFind 'TestPipe', (pipe) -> thePipes.push(pipe)
            FramePipe.onFind 'TestPipe', (pipe) -> thePipes.push(pipe)
            FramePipe.initialize()
            waitsFor -> thePipes.length is 2
            waits 10
            waitsFor ->
              try
                theFrame.contentWindow
              catch e
                false
            runs ->
              expect(thePipes.length).toBe(2)
              expect(thePipes[0].dstFrame).toBe(theFrame.contentWindow)
              expect(thePipes[0]).toBe(thePipes[1])
              expect(FramePipe.all().length).toBe(1)

    describe 'two pipes, same type', ->
      beforeEach ->
        injectTwoPipesSameType()
        waits 100

      describe 'onFind', ->
        it 'runs twice', ->
          thePipes = []
          FramePipe.onFind 'TestPipe', (pipe) -> thePipes.push(pipe)
          FramePipe.initialize()
          waitsFor -> thePipes.length is 2
          waits 10
          waitsFor ->
            try
              theFrame.contentWindow
            catch e
              false
          runs ->
            expect(thePipes.length).toBe(2)
            expect(thePipes[0].dstFrame).toBe(theFrame.contentWindow)
            expect(thePipes[1].dstFrame).toBe(theFrame.contentWindow)
            expect(thePipes[0].uid).toNotBe(thePipes[1].uid)
            expect(FramePipe.all().length).toBe(2)

    describe 'two pipes, different types', ->
      beforeEach ->
        injectTwoPipesDifferentTypes()
        waits 100

      describe 'onFind', ->
        it 'runs once for each type', ->
          thePipes = []
          FramePipe.onFind 'TestPipe1', (pipe) -> thePipes.push(pipe)
          FramePipe.onFind 'TestPipe2', (pipe) -> thePipes.push(pipe)
          FramePipe.initialize()
          waitsFor -> thePipes.length is 2
          waits 10
          waitsFor ->
            try
              theFrame.contentWindow
            catch e
              false
          runs ->
            expect(thePipes.length).toBe(2)
            expect(thePipes[0].dstFrame).toBe(theFrame.contentWindow)
            expect(thePipes[1].dstFrame).toBe(theFrame.contentWindow)
            expect(thePipes[0].uid).toNotBe(thePipes[1].uid)
            expect(thePipes[0].pipeType).toBe('TestPipe1')
            expect(thePipes[1].pipeType).toBe('TestPipe2')
            expect(FramePipe.all().length).toBe(2)

    describe 'two iframes, one pipe each', ->
      beforeEach ->
        injectTwoIframes('OnePipe.html', 'OnePipe.html')
        waits 100

      describe 'onFind', ->
        it 'runs twice', ->
          thePipes = []
          FramePipe.onFind 'TestPipe', (pipe) -> thePipes.push(pipe)
          FramePipe.initialize()
          waitsFor -> thePipes.length is 2
          waits 10
          waitsFor ->
            try
              frame1.contentWindow and frame2.contentWindow
            catch e
              false
          runs ->
            expect(thePipes.length).toBe(2)
            expect(thePipes[0].dstFrame).toBe(frame1.contentWindow)
            expect(thePipes[1].dstFrame).toBe(frame2.contentWindow)
            expect(thePipes[0].uid).toNotBe(thePipes[1].uid)
            expect(FramePipe.all().length).toBe(2)

    describe 'two iframes, two pipes each, same types', ->
      beforeEach ->
        injectTwoIframes('TwoPipesSameType.html', 'TwoPipesSameType.html')
        waits 100

      describe 'onFind', ->
        it 'runs four times', ->
          thePipes = []
          FramePipe.onFind 'TestPipe', (pipe) -> thePipes.push(pipe)
          FramePipe.initialize()
          waitsFor -> thePipes.length is 4
          waits 10
          waitsFor ->
            try
              frame1.contentWindow and frame2.contentWindow
            catch e
              false
          runs ->
            expect(thePipes.length).toBe(4)
            expect(thePipes[0].dstFrame).toBe(frame1.contentWindow)
            expect(thePipes[1].dstFrame).toBe(frame1.contentWindow)
            expect(thePipes[2].dstFrame).toBe(frame2.contentWindow)
            expect(thePipes[3].dstFrame).toBe(frame2.contentWindow)
            expect(thePipes[0].uid).toNotBe(thePipes[1].uid)
            expect(thePipes[1].uid).toNotBe(thePipes[2].uid)
            expect(thePipes[2].uid).toNotBe(thePipes[3].uid)
            expect(FramePipe.all().length).toBe(4)

    describe 'two iframes, two pipes each, different types', ->
      beforeEach ->
        injectTwoIframes('TwoPipesDifferentTypes.html', 'TwoPipesDifferentTypes.html')
        waits 100

      describe 'onFind', ->
        it 'runs twice for each type', ->
          thePipes = []
          FramePipe.onFind 'TestPipe1', (pipe) -> thePipes.push(pipe)
          FramePipe.onFind 'TestPipe2', (pipe) -> thePipes.push(pipe)
          FramePipe.initialize()
          waitsFor -> thePipes.length is 4
          waits 10
          waitsFor ->
            try
              frame1.contentWindow and frame2.contentWindow
            catch e
              false
          runs ->
            expect(thePipes.length).toBe(4)
            expect(thePipes[0].dstFrame).toBe(frame1.contentWindow)
            expect(thePipes[1].dstFrame).toBe(frame1.contentWindow)
            expect(thePipes[2].dstFrame).toBe(frame2.contentWindow)
            expect(thePipes[3].dstFrame).toBe(frame2.contentWindow)
            expect(thePipes[0].uid).toNotBe(thePipes[1].uid)
            expect(thePipes[1].uid).toNotBe(thePipes[2].uid)
            expect(thePipes[2].uid).toNotBe(thePipes[3].uid)
            expect(thePipes[0].pipeType).toBe('TestPipe1')
            expect(thePipes[1].pipeType).toBe('TestPipe2')
            expect(thePipes[2].pipeType).toBe('TestPipe1')
            expect(thePipes[3].pipeType).toBe('TestPipe2')
            expect(FramePipe.all().length).toBe(4)

  describe 'when the outer FramePipe script is initialized before the iframe', ->
    describe 'one pipe', ->
      beforeEach -> FramePipe.initialize()

      describe 'onFind', ->
        it 'runs once', ->
          thePipes = []
          FramePipe.onFind 'TestPipe', (pipe) -> thePipes.push(pipe)
          injectOnePipe()
          waitsFor -> thePipes.length is 1
          waits 10
          waitsFor ->
            try
              theFrame.contentWindow
            catch e
              false
          runs ->
            expect(thePipes.length).toBe(1)
            expect(thePipes[0].dstFrame).toBe(theFrame.contentWindow)
            expect(FramePipe.all().length).toBe(1)

        describe 'when called twice', ->
          it 'runs twice', ->
            thePipes = []
            FramePipe.onFind 'TestPipe', (pipe) -> thePipes.push(pipe)
            FramePipe.onFind 'TestPipe', (pipe) -> thePipes.push(pipe)
            injectOnePipe()
            waitsFor -> thePipes.length is 2
            waits 10
            waitsFor ->
              try
                theFrame.contentWindow
              catch e
                false
            runs ->
              expect(thePipes.length).toBe(2)
              expect(thePipes[0].dstFrame).toBe(theFrame.contentWindow)
              expect(thePipes[0]).toBe(thePipes[1])
              expect(FramePipe.all().length).toBe(1)

    describe 'two pipes, same type', ->
      beforeEach -> FramePipe.initialize()

      describe 'onFind', ->
        it 'runs twice', ->
          thePipes = []
          FramePipe.onFind 'TestPipe', (pipe) -> thePipes.push(pipe)
          injectTwoPipesSameType()
          waitsFor -> thePipes.length is 2
          waits 10
          waitsFor ->
            try
              theFrame.contentWindow
            catch e
              false
          runs ->
            expect(thePipes.length).toBe(2)
            expect(thePipes[0].dstFrame).toBe(theFrame.contentWindow)
            expect(thePipes[1].dstFrame).toBe(theFrame.contentWindow)
            expect(thePipes[0].uid).toNotBe(thePipes[1].uid)
            expect(FramePipe.all().length).toBe(2)

    describe 'two pipes, different types', ->
      beforeEach -> FramePipe.initialize()

      describe 'onFind', ->
        it 'runs once for each type', ->
          thePipes = []
          FramePipe.onFind 'TestPipe1', (pipe) -> thePipes.push(pipe)
          FramePipe.onFind 'TestPipe2', (pipe) -> thePipes.push(pipe)
          injectTwoPipesDifferentTypes()
          waitsFor -> thePipes.length is 2
          waits 10
          waitsFor ->
            try
              theFrame.contentWindow
            catch e
              false
          runs ->
            expect(thePipes.length).toBe(2)
            expect(thePipes[0].dstFrame).toBe(theFrame.contentWindow)
            expect(thePipes[1].dstFrame).toBe(theFrame.contentWindow)
            expect(thePipes[0].uid).toNotBe(thePipes[1].uid)
            expect(thePipes[0].pipeType).toBe('TestPipe1')
            expect(thePipes[1].pipeType).toBe('TestPipe2')
            expect(FramePipe.all().length).toBe(2)

    describe 'two iframes, one pipe each', ->
      beforeEach -> FramePipe.initialize()

      describe 'onFind', ->
        it 'runs twice', ->
          thePipes = []
          FramePipe.onFind 'TestPipe', (pipe) -> thePipes.push(pipe)
          injectTwoIframes('OnePipe.html', 'OnePipe.html')
          waitsFor -> thePipes.length is 2
          waits 10
          waitsFor ->
            try
              frame1.contentWindow and frame2.contentWindow
            catch e
              false
          runs ->
            expect(thePipes.length).toBe(2)
            expect(thePipes[0].dstFrame).toBe(frame1.contentWindow)
            expect(thePipes[1].dstFrame).toBe(frame2.contentWindow)
            expect(thePipes[0].uid).toNotBe(thePipes[1].uid)
            expect(FramePipe.all().length).toBe(2)

    describe 'two iframes, two pipes each, same types', ->
      beforeEach -> FramePipe.initialize()

      describe 'onFind', ->
        it 'runs four times', ->
          thePipes = []
          FramePipe.onFind 'TestPipe', (pipe) -> thePipes.push(pipe)
          injectTwoIframes('TwoPipesSameType.html', 'TwoPipesSameType.html')
          waitsFor -> thePipes.length is 4
          waits 10
          waitsFor ->
            try
              frame1.contentWindow and frame2.contentWindow
            catch e
              false
          runs ->
            expect(thePipes.length).toBe(4)
            expect(thePipes[0].dstFrame).toBe(frame1.contentWindow)
            expect(thePipes[1].dstFrame).toBe(frame1.contentWindow)
            expect(thePipes[2].dstFrame).toBe(frame2.contentWindow)
            expect(thePipes[3].dstFrame).toBe(frame2.contentWindow)
            expect(thePipes[0].uid).toNotBe(thePipes[1].uid)
            expect(thePipes[1].uid).toNotBe(thePipes[2].uid)
            expect(thePipes[2].uid).toNotBe(thePipes[3].uid)
            expect(FramePipe.all().length).toBe(4)

    describe 'two iframes, two pipes each, different types', ->
      beforeEach -> FramePipe.initialize()

      describe 'onFind', ->
        it 'runs twice for each type', ->
          thePipes = []
          FramePipe.onFind 'TestPipe1', (pipe) -> thePipes.push(pipe)
          FramePipe.onFind 'TestPipe2', (pipe) -> thePipes.push(pipe)
          injectTwoIframes('TwoPipesDifferentTypes.html', 'TwoPipesDifferentTypes.html')
          waitsFor -> thePipes.length is 4
          waits 10
          waitsFor ->
            try
              frame1.contentWindow and frame2.contentWindow
            catch e
              false
          runs ->
            expect(thePipes.length).toBe(4)
            expect(thePipes[0].dstFrame).toBe(frame1.contentWindow)
            expect(thePipes[1].dstFrame).toBe(frame1.contentWindow)
            expect(thePipes[2].dstFrame).toBe(frame2.contentWindow)
            expect(thePipes[3].dstFrame).toBe(frame2.contentWindow)
            expect(thePipes[0].uid).toNotBe(thePipes[1].uid)
            expect(thePipes[1].uid).toNotBe(thePipes[2].uid)
            expect(thePipes[2].uid).toNotBe(thePipes[3].uid)
            expect(thePipes[0].pipeType).toBe('TestPipe1')
            expect(thePipes[1].pipeType).toBe('TestPipe2')
            expect(thePipes[2].pipeType).toBe('TestPipe1')
            expect(thePipes[3].pipeType).toBe('TestPipe2')
            expect(FramePipe.all().length).toBe(4)

  describe 'ping', ->
    describe 'one pipe', ->
      beforeEach ->
        FramePipe.initialize()
        injectOnePipe()
        waitsFor -> FramePipe.all().length > 0
        runs -> thePipe = FramePipe.all()[0]

      it 'responds with pong', ->
        expect(thePipe).toBeTruthy()
        thePipe.ping()
        theMsg = null
        thePipe.listen 'pongListener', (msg) -> theMsg = msg
        waitsFor -> theMsg
        runs -> expect(theMsg).toBe('__pong__')

    describe 'two pipes', ->
      beforeEach ->
        FramePipe.initialize()
        injectTwoPipesSameType()
        waitsFor -> FramePipe.all().length is 2
        runs -> [pipe1, pipe2] = FramePipe.all()

      it 'each responds with pong from different pipes', ->
        expect(pipe1).toBeTruthy()
        expect(pipe2).toBeTruthy()
        pipe1.ping()
        pipe2.ping()
        msg1 = null
        msg2 = null
        pipe1.listen 'pongListener', (msg, full) -> msg1 = full
        pipe2.listen 'pongListener', (msg, full) -> msg2 = full
        waitsFor -> msg1 and msg2
        runs ->
          expect(msg1.message).toBe('__pong__')
          expect(msg2.message).toBe('__pong__')
          expect(msg1.pipeUid).toNotBe(msg2.pipeUid)
