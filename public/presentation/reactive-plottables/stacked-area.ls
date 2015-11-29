{concat-map, map, filter, unique, sort, find, reverse, id, zip-with, group-by, obj-to-pairs, take, drop, Obj, reverse, each, sort-by, empty} = require \prelude-ls
{fill-intervals, trend-line, rextend} = require \./../plottables/_utils.ls
fill-intervals-f = fill-intervals
{to-stacked-area} = (require \./../../transformation/context.ls)!

module.exports = ({{Plottable, xplot}:Reactive, d3}) -> new Reactive.Plottable do 
    (result, {stack, iden, effects, margin, key, values, x, y, x-scale, y-scale, y-axis, x-axis, color, fill-intervals, tooltip}:options, {meta, effects:{is-highlighted, is-selected}}) -> #TODO: helper functions from somwhere else

        result = to-stacked-area stack.key.f, stack.x.f, stack.y, result

        all-values = result |> concat-map (-> (values it) |> concat-map x) |> unique |> sort

        if fill-intervals is not false
            all-values := all-values |> map (-> [it, 0]) |> (-> fill-intervals-f it, if fill-intervals is true then 0 else fill-intervals) |> map (.0)
        
        

        result := result |> map (d) ->
            _iden = iden d
            oiden = [_iden] |> group-by id |> obj-to-pairs |> (.0)
            {
                key: key d
                values: all-values 
                    |> map (v) -> 
                        value = (values d) |> find (-> (x it) == v)
                        selected = (is-selected stack.key.iden, _iden) 
                        x: v
                        y: value |> (-> if false == selected then 0 else if !!it then (y it) else (fill-intervals))
                        value: value
                        _x: v
                raw: d
                meta: meta[oiden] ? {}
                iden: oiden
            }


        stack = d3.layout.stack!
            .values (.values)
            .x (.x)
            .y (.y)

        layers = stack result

        {
            result
            layers
        }
    ({change, toggle, fx, dfx, is-highlighted}:change_, meta, view, {result, layers}, {stack, iden, effects, margin, key, values, x, y, x-scale, y-scale, y-axis, x-axis, color, fill-intervals, tooltip}:options, continuation) !->

        t0 = Date.now!

        width = view.client-width - margin.left - margin.right
        height = view.client-height - margin.top - margin.bottom

        

        x-scale := x-scale.copy!
            .range [0, width]
            .domain (d3.extent (concat-map (.values), result), (.x))
        y-scale := y-scale.copy!
            .range [height, 0]
            .domain [0, (d3.max (concat-map (.values), layers), (-> it.y + it.y0))]


        area = d3.svg.area!
            .x x-scale . (.x)
            .y0 y-scale . (.y0)
            .y1 y-scale . (-> it.y + it.y0)
            .interpolate options.interpolation


        line = d3.svg.area!
            .x x-scale . (.x)
            .y0 y-scale . (.y0)
            .y1 y-scale . (-> it.y + it.y0)
            .interpolate options.interpolation


        bisect-date = d3.bisector (.x) .left


        t1 = Date.now!

        x-axis = d3.svg.axis!
            ..scale x-scale
            ..orient options.x-axis.orient
            ..tickSize (options.x-axis.tickSize height)
            ..tick-format options.x-axis.format
            
        if \Number == typeof! options.x-axis.ticks
            x-axis.ticks options.x-axis.ticks
        else do ->
            x = options.x-axis.ticks.apply x-axis, [width]
            return if !!x.ticks and !!x.tickFormat # the ticks value is set by @
            x-axis.ticks x

        y-axis = d3.svg.axis!
            ..scale y-scale
            ..orient 'left'
            ..tickFormat options.y-axis.format


        x-to-time = (time) ->
            i = bisect-date layers[0].values, time.value-of!
            v = layers[0].values[i]

            vs = [i - 1 to i + 1] 
                |> map (i) -> layers[0].values[i]
                |> filter (-> !!it)
            
            console.log ">>>", i, layers[0].values[i]
            #new Date layers[0].values[i].value.2.started
            new Date layers[0].values[i]._x
            #new Date vs.1.value.2.started
            

        move-x-axis-vline = (x) ->

            # return if empty vs
            
            # x = match vs.length
            # | 1 => vs[0].x
            # | 2 => (vs[0].x + vs[1].x) / 2
            # | 3 => (vs[0].x + vs[1].x) / 2

            
            x0 = x-scale  x
            
            svg.select \#vline .attr \d, "M#{x0},0 L#{x0},#{height}"
            vline = svg.select \#vline .node!
            svg.select-all 'path.layer' .each (d) ->
                

                intersection = Intersection.intersectShapes (new Path @), (new Path vline)
                
                y0 = intersection.points ? [] |> sort-by (.y) |> (.0?.y ? 0)
            
                circle = svg.select "\#circle-#{d.key}" 
                    ..attr \transform, "translate(#{x0}, #{y0})" #.attr \cy, y0 .attr \cx, x0
                    ..data {x: x0, y: y0}    

            


        dview = d3.select view
        svg = dview.select-all 'svg.stacked-area' .data [result]
            ..enter!
                ..append \svg .attr \class, \stacked-area
                    ..append \g .attr \class, \main
                        # ..append 'rect' .attr \class, \interactive .attr \style, 'fill: none; pointer-events: all'
                        #     ..attr 'width', width
                        #     ..attr 'height', height
                        #     ..on 'mousemove', ->
                        #         x0 = x-scale.invert (d3.mouse @).0
                        #         console.log \x0, x0
                        ..append \g .attr \class, \chart
                        ..append 'g'
                            ..attr 'class', 'x-axis axis'
                        ..append 'g'
                            ..attr 'class', 'y-axis axis'
                        ..append 'g'
                            ..attr 'class', 'focus'
                    ..on 'mousemove', ->
                        mouse-x = (d3.mouse @).0 - margin.left
                        time = x-scale.invert mouse-x
                        #console.log \fx, 'highlight', stack.x.iden, (typeof! time), time, (x-to-time time).0.x
                        fx 'highlight', stack.x.iden, (x-to-time time).toJSON!
                        # [iden, x] = move-x-axis-vline time
                        # console.log \x, x
                        # fx 'highlight', iden, x

            ..attr \width, width + margin.left + margin.right
            ..attr \height, height + margin.top + margin.bottom

            ..select 'g.main'
                ..attr \transform, "translate(" + margin.left + "," + margin.top + ")"
                ..select 'g.chart'
                    ..select-all \#vline .data [1]
                        ..enter!
                            ..append \path, .attr \id, 'vline' .attr \d, "M0,0 L0,#{height}" .attr \stroke, \red
                        # ..each (d) ->
                        #     [x]? = do -> meta[stack.x.iden] |> obj-to-pairs |> find (-> true == it.1.highlight) 
                        #     return if !x
                        #     x = new Date x
                        #     console.log "vline >>", x, x.value-of!
                        #     i = bisect-date layers[0].values, x.value-of!
                        #     console.log "vline >>", x, i
                    ..select-all \.layer .data layers
                        ..enter!
                            ..append \path .attr \class, \layer
                                ..on \mouseover, -> fx 'highlight', stack.key.iden, it.iden
                                ..on \mouseout, -> dfx 'highlight', stack.key.iden, it.iden
                        ..interrupt!.transition!.duration 1000
                            ..attr \d, -> area it.values
                        ..style \fill, -> 
                            c = color it.key
                            if (is-highlighted stack.key.iden, it.key) then effects.highlight.color else c
                            #if meta[stack.key.iden]?[it.key]?.highlight then effects.highlight.color else c
                            #if it.meta.highlight then effects.highlight.color else c
                ..select 'g.focus'
                    ..select-all 'circle' .data layers
                        ..enter!
                            ..append 'circle'
                                ..attr 'id', -> "circle-#{it.key}"
                                ..on \mouseover, (d) ->

                                    mouse-x = (d3.mouse @).0 - margin.left
                                    time = x-scale.invert mouse-x
                                    return if !d.values
                                    i = bisect-date d.values, time.value-of!
                                    v = d.values[i]
                                    console.log \v, v, d.key

                                ..on \mouseout, ->
                        ..attr 'cx', 0
                        ..attr 'cy', 0
                        ..attr 'r', 10

            ..select \.x-axis
                ..attr 'transform', "translate(0, #{height})"
                ..transition! .call x-axis
            ..select \.y-axis
                ..transition!.duration 1000 .call y-axis

        do ->
                x = do -> meta[stack.x.iden]?['highlight']
                return if !x
                #x = parse-int x
                console.log ">>>> ", \move-x-axis-vline, (typeof! x), x
                x = new Date x
                move-x-axis-vline (x-to-time x)

        console.log "time", (Date.now! - t1)

        #console.log \d3-render, Date.now! - t1, \compute t1 - t0


    {
        x: (.0)
        y: (.1)
        key: (.key)
        values: (.values)
        x-scale: d3.time.scale!
        y-scale: d3.scale.linear!
        fill-intervals: false
        color: d3.scale.category20!
        effects:
            highlight:
                color: 'yellow'
        x-axis: 
            format: (timestamp) -> (d3.time.format \%x) new Date timestamp
            orient: 'bottom'
            tickSize: (height) -> 10
            # ticks :: Number -> Number `or` Tick
            # context :: Tick
            # example: ticks: -> @.ticks d3.time.month, 3
            ticks: (width) -> 5 
            label: null
            distance: 0
        y-axis:
            format: d3.format ','

        interpolation: 'linear'

        stack: 
            key: 
                f: (.key)
                iden: 'key'
            x:
                f: (.x)
                iden: 'x'
            y:
                f: (.y)
                iden: 'y'

        margin: {top: 20, right:20, bottom: 50, left: 50}
    }