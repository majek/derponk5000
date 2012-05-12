class Game
    constructor: (@width, @height) ->
        @ball = {x:2.0, y:2.0, vx:0.0, vy:0.0}

        @boxsize = 10
        @paddle_height = 4
        @paddle = [{x:1, y:2, width:1, height: @paddle_height},
                   {x:@width-2, y:2, width:1, height: @paddle_height}]

        @top    = {x:0, y:0, width:@width, height:1};
        @bottom = {x:0, y:@height-1, width:@width, height:1};
        @left   = {x:0, y:1, width:1, height:@height-2};
        @right  = {x:@width-1, y:1, width:1, height:@height-2};

        @matrix = ((0 for j in [0...@width]) for i in [0...@height])
        @redraw = []

        @drawrect(@top, 1)
        @drawrect(@bottom, 1)
        @drawrect(@left, 2)
        @drawrect(@right, 3)

        @drawrect(@paddle[0], 1)
        @drawrect(@paddle[1], 1)
        @setball({x:@width/2, y:@height/2, vx:0.0, vy:0.0})



    drawrect: (r, type) ->
        for row in [r.y...(r.y+r.height)]
            for col in [r.x...(r.x+r.width)]
                if @matrix[row][col] isnt type
                    @redraw.push({x:col, y:row, type:type})
                    @matrix[row][col] = type

    print: ->
        console.log "matrix:"
        for row in [0..@height]
            console.log(JSON.stringify(@matrix[row]))
        console.log "redraw:"
        console.log(JSON.stringify(@redraw))

    updatedraw: (context) ->
        colors = {0: '#fdfdfd', 1:'#333333', 2:'#0000ff', 3:'#0000ff', 4:'#00ff00'}
        while @redraw.length > 0
            r = @redraw.shift()
            if colors[r.type]
                context.fillStyle = colors[r.type]
                context.fillRect(r.x * @boxsize, r.y * @boxsize, @boxsize, @boxsize)


    movepaddle: (nr, dir) ->
        p = @paddle[nr]
        @drawrect(p, 0)
        p.y += dir
        min = 1
        max = @height - @paddle_height - 1
        p.y = min if p.y < min
        p.y = max if p.y > max
        @drawrect(p, 1)

    setpaddle: (d) ->
        @drawrect(@paddle[0], 0)
        @drawrect(@paddle[1], 0)
        @paddle[0].y = 1
        @paddle[1].y = 1
        @movepaddle(1, 1)
        @movepaddle(0, d[0]-1)
        @movepaddle(1, d[1]-1)


    setball: (ball) ->
        ballrect1 = {x:Math.floor(@ball.x), y:Math.floor(@ball.y), width:1, height:1}

        #console.log(@ball, ball)
        @ball = ball
        ballrect2 = {x:Math.floor(@ball.x), y:Math.floor(@ball.y), width:1, height:1}
        if ballrect1.x isnt ballrect2.x or ballrect1.y isnt ballrect2.y
            @drawrect(ballrect1, 0)
            @drawrect(ballrect2, 4)



game = new Game(40, 20)

run = ->
    canvas = document.getElementById('canvas');
    ctx = canvas.getContext('2d');
    # c_width = 55.0;
    # ppm = canvas.width/c_width;
    # c_height = canvas.height/ppm;
    # ctx.setTransform(ppm, 0, 0, -ppm, 0, canvas.height);

    draw = ->
        game.updatedraw(ctx)
        setTimeout(draw, 1000/30)
    draw()



    onkeypress = (event) ->
        #console.log(event.which)
        switch event.which
            when 113 # Q
                game.movepaddle(0, -1)
            when 97 # A
                game.movepaddle(0, 1)
            when 112 # P
                game.movepaddle(1, -1)
            when 108 # L
                game.movepaddle(1, 1)


    $(document).keypress(onkeypress)

    onkeydown = (event) ->
        switch event.keyCode
            when 38 # up
                sjs.send('up')
                #game.movepaddle(0, -1)
            when 40 # down
                sjs.send('down')
                #game.movepaddle(0, 1)
        #console.log event.keyCode
    $(document).keydown(onkeydown)

$(run)




sjs = null

presence_run = ->
    presence = $('#presence')
    sjs = new SockJS('/sockjs')
    sjs.onopen = ->
        presence.empty()
        sjs.send(Math.random())
    sjs.onclose = ->
        presence.empty()
        presence.append('<li>disconnected</li>')
    sjs.onmessage = (m) ->
        msg = JSON.parse(m.data)
        switch msg.type
            when 'presence_bulk'
                for child in msg.childs
                    presence.append('<li id="p'+child.id+'">' + child.name + '</li>')
            when 'presence_add'
                presence.append('<li id="p'+msg.child.id+'">' + msg.child.name + '</li>')
            when 'presence_del'
                $('#p' + msg.child.id).remove()
            when 'ball'
                #console.log(m.data)
                game.setball(msg.ball)
            when 'alert'
                $('#alertbox').text(msg.msg)
            when 'paddle'
                console.log('paddle', msg.data)
                game.setpaddle(msg.data)
            else
                console.log(m.data)


$(presence_run)
