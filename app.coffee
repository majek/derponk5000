express = require('express')
sockjs  = require('sockjs')

app = express.createServer()

sjs = sockjs.createServer();
sjs.installHandlers(app, {prefix:'/sockjs'});

app.configure ->
    app.use(express.logger('dev'))
    app.use(express.static(__dirname + '/public'))

app.get '/', (req, res) ->
    res.sendfile(__dirname + '/public/index.html')



port = 8000;
console.log(' [*] Listening on port ' + port)
app.listen(port)




class Game
    constructor: (@width, @height) ->
        @ball = {x:2.0, y:2.0, vx:0.0, vy:1.0}

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
        @setball({x:@width/2, y:@height/2, vx:0.0, vy:1.0})


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


    movepaddle: (nr, dir) ->
        console.log(@paddle)
        p = @paddle[nr]
        @drawrect(p, 0)
        p.y += dir
        min = 1
        max = @height - @paddle_height - 1
        p.y = min if p.y < min
        p.y = max if p.y > max
        @drawrect(p, 1)

    setball: (ball) ->
        ballrect1 = {x:Math.floor(@ball.x), y:Math.floor(@ball.y), width:1, height:1}

        @ball = ball
        ballrect2 = {x:Math.floor(@ball.x), y:Math.floor(@ball.y), width:1, height:1}
        if ballrect1.x isnt ballrect2.x or ballrect1.y isnt ballrect2.y
            @drawrect(ballrect1, 0)
            @drawrect(ballrect2, 4)

game = new Game(40, 20)


class Connections
    constructor: ->
        @conns = {}
    add: (name, conn) ->
        conn.score = 0
        console.log("[+] %s", name)
        @conns[name] = conn
    del: (name, conn) ->
        console.log("[-] %s", name)
        delete @conns[name]

connections = new Connections()


tps = 20.0

game.ball.vy = 3.99
game.ball.vx = 1.99

update = ->
    ball = game.ball
    prev_x = Math.floor(ball.x)
    prev_y = Math.floor(ball.y)

    distx = ball.vx * (1/tps)
    disty = ball.vy * (1/tps)
    ball.x += distx
    ball.y += disty

    # ball.x = 0 if ball.x < 0
    # ball.y = 0 if ball.y < 0
    # ball.x = game.width  - 0.1 if ball.x > game.width
    # ball.y = game.height - 0.1 if ball.y > game.height

    x = Math.floor(ball.x)
    y = Math.floor(ball.y)

    c = game.matrix[y][x]
    #console.log(ball.y, ball.x, y,x ,c, ball.vx, ball.vy)

    dx = ball.x - x
    dy = ball.y - y

    switch c
        when 0
            true
        when 4
            true
        when 1
            bounce_x = 0
            bounce_y = 0
            deg = ball.vx > ball.vy
            if prev_x isnt x and prev_y is y
                bounce_x = 1
            if prev_x is x and prev_y isnt y
                bounce_y = 1
            if prev_x isnt x and prev_y isnt y
                console.log('bounce_whoo')
                bounce_x = 1
                bounce_y = 1

            if bounce_x
                console.log('bounce x', ball.x, dx)
                if prev_x > x
                    dx = -1*(1-dx)
                ball.x -= 2*dx
                ball.vx *= -1
                console.log('bounce x', ball.x, dx)
            if bounce_y
                console.log('bounce y', ball.y, dy)
                if prev_y > y
                    dy = -1*(1-dy)
                ball.y -= 2*dy
                ball.vy *= -1
                console.log('bounce y', ball.y, dy)
        when 2
            if game_state is 'game'
                game_state = 'right_won'
            game.setball({x:game.width/2, y:game.height/2, vx:0.0, vy:1.0})

        when 3
            if game_state is 'game'
                game_state = 'left_won'
            game.setball({x:game.width/2, y:game.height/2, vx:0.0, vy:1.0})
    #console.log(ball.y, ball.x, ball.vx, ball.vy)

    for key of connections.conns
        c = connections.conns[key]
        c.write(JSON.stringify({type:'ball', ball:ball}))



setInterval(update, 1000.0/tps)




sjs.on 'connection', (conn) ->
    conn.id = ('' + Math.random()).substr(2)
    conn.once 'data', (msg) ->
        name = msg
        if connections.conns[name]
            conn.write(JSON.stringify({type:'alert', msg:'another nick please'}))
            close = ->
                conn.close()
            setTimeout(close, 1000)
        else
            for key of connections.conns
                c = connections.conns[key]
                c.write(JSON.stringify({type:'presence_add', child:{id:conn.id, name:name}}))

            connections.add( name, conn )
            childs = ({name:k, id:connections.conns[k].id} for k of connections.conns)
            conn.write(JSON.stringify({type:'presence_bulk', childs:childs}))
            conn.write(JSON.stringify({type:'alert', msg:"waiting for your game"}))
            conn.on 'data', (msg) ->
                console.log(msg)
                p = null
                if conn is left
                    p = 0
                else if conn is right
                    p = 1
                else
                    return
                if msg is 'up'
                    v = -1
                else if msg is 'down'
                    v = 1
                else
                    return
                game.movepaddle(p, v)
                for key of connections.conns
                    c = connections.conns[key]
                    c.write(JSON.stringify({type:'paddle', data:[game.paddle[0].y, game.paddle[1].y]}))

            conn.on 'close', ->
                connections.del( name )
                for key of connections.conns
                    c = connections.conns[key]
                    c.write(JSON.stringify({type:'presence_del', child:{id:conn.id, name:name}}))


send_alert = (conn, msg) ->
    conn.write(JSON.stringify({type:'alert', msg:msg}))

broadcast_alert = (msg, a, b) ->
    for key of connections.conns
        c = connections.conns[key]
        if c is a or c is b
            continue
        send_alert(c, msg)

randint = (lim) ->
    return Math.floor(Math.random()*lim)


game_state = 'start'
left = right = null

do_game = ->
    switch game_state
        when 'start'
            keys = (k for k of connections.conns)
            if keys.length < 2
                broadcast_alert('Awaiting more players...')
                return
            a = b = randint(keys.length)
            while b is a
                b = randint(keys.length)
            left  = connections.conns[keys[a]]
            right = connections.conns[keys[b]]
            send_alert(left, "You're player LEFT!  3")
            send_alert(right, "You're player RIGHT!  3")
            broadcast_alert('Someone elses playing! 3', left, right)
            game.setball({x:game.width/2, y:game.height/2, vx:0.0, vy:0.0})
            game_state = 1
        when 1
            send_alert(left, "You're player LEFT!  2")
            send_alert(right, "You're player RIGHT!  2")
            broadcast_alert('Someone elses playing! 2', left, right)
            game_state = 2
        when 2
            send_alert(left, "You're player LEFT!  1")
            send_alert(right, "You're player RIGHT!  1")
            broadcast_alert('Someone elses playing! 1', left, right)
            game_state = 3
        when 3
            game.setball({x:game.width/2, y:game.height/2, vx:3.1, vy:4.1})
            send_alert(left, "Fight!")
            send_alert(right, "Fight!")
            broadcast_alert('Someone elses playing! yes!', left, right)
            game_state = 'game'
        when 'game'
            true
        when 'left_won'
            broadcast_alert('Player LEFT won!')
            left.score += 1
            game_state = 'next'
        when 'right_won'
            broadcast_alert('Player RIGHT won!')
            left.score += 1
            game_state = 'next'
        when 'next'
            game_state = 'next2'
        when 'next2'
            game_state = 'next3'
        when 'next3'
            game_state = 'start'



setInterval(do_game, 1000)