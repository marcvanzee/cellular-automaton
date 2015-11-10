; Cellular Automaton - flow control in a decentralized network              28/05/2010
; by Marc van Zee / F093385
; M.vanZee@students.uu.nl
;
; Artifial Intelligence / University of Utrecht
;
; for a description, please see the information tab
;
; the code is very long, but i tried to make it even longer by using a lot of comments.
; i hope it helps.

; colors of the patches:
; [BLACK]   = background, nothing
; [86-89]   = moving particles
;   [86]    = up
;   [87]    = left
;   [88]    = down
;   [89]    = right
; [YELLOW]  = road that particles travel on
; [BROWN]   = wall protecting the roads
; [RED]     = crossing, intersection of roads
; [WHITE]   = crossing with a particle on it
; [MAGENTA] = obstacle
; [PINK]    = patch or connected patch has been hit by an obstacle

patches-own [
  greens4    greens                                          ; colors of the neighbors
  browns4    browns                                          ; {color}4 = [neighbors4]
  blacks4    blacks                                          ; {color}  = [neighbors]
  reds
  magentas4
  pinks4
  
  from                                                       ; <road/crossing var> boolean-list of incoming particles: [up right down left]
  extend?                                                    ; <wall var>          extend? = true => two particles collide
  
  wait-for                                                   ; <crossing var>      current delay of outgoing particles
  wait-value                                                 ; <crossing var>      value to reset to when a particle enters
]

to setup
  ca
  ask patches [ set wait-value (50 - population-density) ]                 ; initialize all patches with the default wait-time
end

to setup-random
  setup
  
  let x min-pxcor
  let y min-pxcor
  
  while [x < max-pxcor and y < max-pycor] [
    set x (x + random 5 + 4)
    set y (y + random 5 + 4)
    
    create-road x y one-of ["horizontal" "vertical" ] 
  ]
end

to go-once
  go
end

to go
  add-first-particle                                         ; check if we add a particle when the roads are empty
  plot-all
  
  ask patches [ collect-neighbors ]                          ; first collect all the states of the cells and put them in the variables
  
   ask patches [                                    ;<-------;-- update patches. this order makes sure all patches are synchronized.
    ifelse pcolor = black [ update-background ] [            ;-- see the Brains Brain simulation for more explanation.  
    ifelse pcolor = brown [ update-walls ] [   
    ifelse pcolor = green [ update-road ] [
      
    ifelse pcolor > 85                              ;<-------;-- pcolor [86-89] represent the colors for the particles. every color maps
       and pcolor < 90    [ update-particles ] [             ;-- to the direction that it moves in:
                                                             ;-- 86 = up, 87 = left, 88 = down, 89 = right
    ifelse pcolor = red   [ update-crossings ] [
                                                         
    ifelse pcolor = white [ set pcolor red ] [      ;<-------;-- when a particle is on a crossing, it will turn white. so when the particle
                                                             ;-- is on the crossing, the crossing has to turn red again the next tick.
    if pcolor = pink [
      ifelse reds = 0     [ set pcolor black ]               ; when a particle is pink, it has been indirectly in contact with an obstacle and
                          [ set pcolor brown ]               ; has to destroy itself. except when it is at a crossing, then it has to close the wall
   
    ] ] ] ] ] ] ] ] ;<--- ugly, no else-if in netlogo?
  tick
end

to collect-neighbors                                         ; collection of states. every kind of patch needs its own referents
  if pcolor = black and
     count neighbors with [pcolor != black] > 0 [
    set greens     count neighbors  with [pcolor = green]
    set browns4    count neighbors4 with [pcolor = brown]
    set greens4    count neighbors4 with [pcolor = green]
  ]
    
  if pcolor = green [
    set greens     count neighbors  with [pcolor = green]
    set browns4    count neighbors4 with [pcolor = brown]
    set pinks4     count neighbors4 with [pcolor = pink]
    set magentas4  count neighbors4 with [pcolor = magenta]  
  ]
    
  if pcolor = brown [
    set browns     count neighbors  with [pcolor = brown]
    set greens4    count neighbors4 with [pcolor = green]
    set pinks4     count neighbors4 with [pcolor = pink]
    set blacks     count neighbors  with [pcolor = black]
    set reds       count neighbors  with [pcolor = red]

    check-for-collision                                       ; check if any particles have collided next to the wall
  ]
    
  if pcolor = red or pcolor = pink [ 
    set reds count neighbors  with [pcolor = red] 
  ]
    
  if pcolor = red [ 
    set magentas4 count neighbors4 with [pcolor = magenta] 
  ]
    
  if (pcolor > 85 and pcolor < 90) [
    set magentas4 count neighbors4 with [pcolor = magenta]
    set pinks4     count neighbors4 with [pcolor = pink]
  ]
  
  if (pcolor = green or pcolor = red) [ 
    check-incoming-particles                                  ; see if a road or a crossing needs to receive a particle next tick
  ]
end
  
to check-for-collision                               ;<-------;-- extend the road if two particles cross in the same direction
  ifelse (count neighbors4 with [pcolor = 86] = 1             ;-- only one particle (86 or 87) will get a road right next to it
               and count neighbors with [pcolor = 88] = 1)    ;-- this is to make sure the road will not be created double.
      or (count neighbors4 with [pcolor = 87] = 1
               and count neighbors with [pcolor = 89] = 1) [  
          set extend? true ] [ set extend? false ]
end
  
to check-incoming-particles
  ifelse count neighbors4 with [(pcolor > 85 and pcolor < 90)  
         or pcolor = white] > 0 [                             ; create a boolean list with the incoming particles
    set from list-particles-here
  ] [ set from [false false false false] ]                    ; no incoming particles => false list
end

to update-background                                          ; road building rules for the background
  ifelse greens4 = 1                                          ; i have not commented on all the rules of the patches, because i
      or greens4 = 2 [                                        ; believe they are rather trivial. most of the rules are there to
    ifelse browns4 != 3 [                                     ; make the roads connect nicely and to process the collision.
      set pcolor green 
    ] [ 
      set pcolor brown 
    ]
  ] [ 
    if (browns4 = 1 or browns4 = 2)
       and (greens  = 1 or greens  = 2) [
    set pcolor brown ] 
  ]
  if browns4 = 2 and greens4 = 2 [ set pcolor brown ]
end

to update-road
  if greens > 4 [ set pcolor brown ]
  if pinks4 > 0 [ set pcolor pink ]
  if magentas4 > 0 and greens4 > 1 [ set pcolor pink ]
                     
  if particle-here [                                          ; become particle or a crossing when necessary
    ifelse on-crossing [
      become-crossing
    ] [
      become-particle
    ]
  ]
end

to update-walls
  if (browns = 4 or browns = 5)
     and greens4 = 2 [ set pcolor green ]
  
  if extend? = true 
     and reds = 0 
     and blacks > 1  [ set pcolor green ]
     
  if pinks4 > 0 
     and reds = 0 
     and greens4 = 0 [ set pcolor black ]
end

to update-particles
  ifelse magentas4 > 0 [
    set pcolor pink
  ] [
    ifelse pinks4 > 0 [ 
      set pcolor pink 
    ] [ 
      set pcolor green                                       ; particles become green (the road) again, which makes them move
    ] 
  ]
end

to update-crossings                                          ; crossings are the heart of the dynamic behavior
  if reds > 0      [ set pcolor green ]                      ; see 'information' tab for an explanation
  if magentas4 > 0 [ set pcolor pink]
      
  ifelse wait-for = 0 [
    ifelse particle-here [
      become-crossing-with-particle
    ] [
      decrease-wait-value
    ]
  ] [ 
    if wait-for > 0 [ 
      set wait-for (wait-for - 1)
      ifelse particle-here [ 
        set wait-value (wait-value + (50 - population-density))            ; sensitivity value can be changed by use
      ] [
        decrease-wait-value
      ] 
    ] 
  ]
end

; ##########################################
; ########### GUI PROCEDURES ###############
; ##########################################

to draw                                                      ; draw a piece of a road. the algorithm will finish it automatically
  if mouse-down? [
    create-road mouse-xcor mouse-ycor draw-direction
  ]
end

to add-particle                                              ; add a particle one a free place, if available
  let free_patches patches with 
      [pcolor = green and [pcolor = green] of one-of neighbors4]
  
  ifelse any? free_patches [
    ask one-of free_patches [
      if [pcolor = green] of patch-at  0 -1 [ set pcolor one-of [86 88] ]
      if [pcolor = green] of patch-at -1  0 [ set pcolor one-of [87 89] ]
    ]
  ] [
    print "ERROR: no road available to add particle!"
  ]
end

to draw-obstacle                                             ; draw a square obstacle with a radius specified by the user
  if mouse-down? [ 
    ask patch mouse-xcor mouse-ycor [ set pcolor magenta ] 
    let o-size (obstacle-size / 2)
    let i -1 * o-size
    
    while [i < o-size] [
      let j -1 * o-size
      while [j < o-size] [
        ask patch (mouse-xcor + i) (mouse-ycor + j) [ set pcolor magenta ] 
        set j (j + 1)
      ]
      set i (i + 1)
    ]
  ]
end

to add-first-particle                                        ; keep adding new particles if the simulation dies out,
  if add-particle-when-empty = true and                      ; only if the user has chosen for it of course.
     count patches with [pcolor > 85 and pcolor < 90] = 0 and 
     count patches with [pcolor = green] > 0 [ add-particle ]
end

to plot-all                                                  ; plot three graphs:
  set-current-plot-pen "particles"                           ; [1] number of particles
  plot count patches with [pcolor > 85 and pcolor < 90]
  
  set-current-plot-pen "crossings"                           ; [2] number of crossings
  plot count patches with [pcolor = red]
  
  set-current-plot-pen "average-waiting-time"                ; [3] avarage wait-value of the crossings
  ifelse count patches with [pcolor = red] > 0 [
    plot (sum [wait-value] of patches with [pcolor = red]) / 
              count patches with [pcolor = red]
  ] [ plot 0 ]
end

to save 
  let file user-new-file

  if ( file != false ) [
    file-open file
    
    ask patches [
      file-write pxcor
      file-write pycor
      file-write pcolor
    ]
    file-close
  ]
end

to load
  let file user-file

  if ( file != false ) [
    let patch-data []
    file-open file

    while [ not file-at-end? ]
      [ set patch-data sentence patch-data (list (list file-read file-read file-read)) ]

    user-message "File loading complete!"
    file-close
    
    process-file patch-data
  ]
end

to preset [num]
  let file word "presets/preset" num
  
  ifelse ( file-exists? file ) [
    let patch-data []
    file-open file

    while [ not file-at-end? ] [
      set patch-data sentence patch-data (list (list file-read file-read file-read))
    ]

    user-message "File loading complete!"
    file-close
    
    process-file patch-data
  ] [ 
    user-message "There is no File IO Patch Data.txt file in current directory!" 
  ]
end
    

; ##########################################
; ########### SHORT PROCEDURES #############
; ##########################################                 ; procedures to make the code more readable

to process-file [file-list]
  setup
  ifelse ( is-list? file-list ) [ 
    foreach file-list [ ask patch first ? item 1 ? [ set pcolor last ? ] ] 
  ] [ 
    user-message "File doesnt contains any data!" 
  ]
end

to-report on-crossing 
  report (browns4 < 2 and magentas4 = 0)
end

to-report particle-here
  report from != [false false false false]
end

to-report list-particles-here
  report (list [pcolor = 89 or pcolor = white] of patch-at -1  0 
               [pcolor = 88 or pcolor = white] of patch-at  0  1
               [pcolor = 87 or pcolor = white] of patch-at  1  0
               [pcolor = 86 or pcolor = white] of patch-at  0 -1)
end

to create-road [x y direction]
  ask patch x y [ set pcolor green ]
  ifelse direction = "horizontal" [
    ask patch x (y + 1) [ set pcolor brown ]
    ask patch x (y - 1) [ set pcolor brown ]
  ] [
    ask patch (x + 1) y [ set pcolor brown ]
    ask patch (x - 1) y [ set pcolor brown ]
  ]
end

to become-crossing
  set pcolor red set wait-for wait-value
end

to become-particle
  if item 0 from = true [ set pcolor 89 ] 
  if item 1 from = true [ set pcolor 88 ] 
  if item 2 from = true [ set pcolor 87 ] 
  if item 3 from = true [ set pcolor 86 ] 
end

to become-crossing-with-particle
  set wait-for wait-value
  set wait-value (wait-value + (50 - population-density))
  set pcolor white
end

to decrease-wait-value
  if (wait-value > 10) [ 
    set wait-value (wait-value - 1) 
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
219
10
834
396
60
35
5.0
1
10
1
1
1
0
1
1
1
-60
60
-35
35
0
0
1
ticks

BUTTON
12
14
127
47
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
11
219
130
252
draw road
draw
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
12
57
111
90
clear world
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
134
14
204
47
NIL
go-once
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

CHOOSER
11
258
206
303
draw-direction
draw-direction
"horizontal" "vertical"
0

BUTTON
12
124
131
157
add new particle
add-particle
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
219
396
834
429
population-density
population-density
0
50
20
1
1
NIL
HORIZONTAL

BUTTON
11
326
135
359
NIL
draw-obstacle
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
11
363
205
396
obstacle-size
obstacle-size
0
10
5
1
1
NIL
HORIZONTAL

PLOT
10
441
836
695
statistics
NIL
NIL
0.0
10.0
0.0
10.0
true
true
PENS
"particles" 1.0 0 -13345367 true
"crossings" 1.0 0 -2674135 true
"average-waiting-time" 1.0 0 -955883 true

SWITCH
12
160
207
193
add-particle-when-empty
add-particle-when-empty
0
1
-1000

BUTTON
117
57
205
90
random setup
setup-random\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
851
131
953
164
advanced
preset 2
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
850
93
953
126
basic
preset 1
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
851
169
953
202
periodic
preset 3
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
851
260
953
293
obstacle 2
preset 5
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
851
222
953
255
obstacle 1
preset 6
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

TEXTBOX
991
230
1052
248
density 40
11
0.0
1

TEXTBOX
989
270
1051
288
density 40
11
0.0
1

TEXTBOX
990
100
1053
118
density 30
11
0.0
1

TEXTBOX
992
141
1055
159
density 20
11
0.0
1

TEXTBOX
874
17
1024
39
file input/output
18
0.0
1

TEXTBOX
877
65
927
83
presets
12
0.0
1

TEXTBOX
969
50
1119
80
      suggested\npopulation density
12
0.0
1

TEXTBOX
1007
178
1037
196
any
11
0.0
1

BUTTON
850
318
953
351
save
save
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
850
362
953
395
load other
load
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

@#$#@#$#@
WHAT IS IT?
-----------
A cellular automata that models adaptive transport. White particles are transported over a green road, which is protected by brown walls. When the particles collide, they will die and a new road is created, perpendicular to the original one. This results in a cross-section. When a different particle reaches this crossing, it will become the flow controller of that crossing.

Flow controllers have a red colour and decide whether particles are allowed to go through. This process is adaptive, which leads to a global state where the number of particles will pulse around a fixed number. The value of this number is in direct relation with the amount of particles that the flow controllers lets through. 

This process is visualized in the graph at the bottom of the simulation.

As the simulation continues, the amount of crossings will increase (red line).
The amount of particles (blue line) will have a pulsing, (very rough) sinus-like behavior. This is the same for the avarage waiting time (orange line). The average waiting time stands for the avarage time that the flow controllers will wait before they will let through any particles. These two values depend on eachother recursively:

Imagine there are many particles. This means that the avarage waiting time of the flow controllers will increase, since they want to stabilize this amount. Because of this, a lot of particles will die (the flow controllers will not let the particles through). This leads to less particles, which will allow the flow controllers to decrease their waiting time. This will again result in more particles (the flow controller will let through the particles), and the circle is round.

The system can also respond to obstacles. Roads that lead to obstacles will be destroyed, which means that in time, only roads around the obstacle will survive.

HOW IT WORKS
------------
The simulation consists of the following patches:
- Particles (white)
- Roads (green)
- Flow controllers (red)
- Walls (brown)
- Obstacles (magenta)

Because this is a cellular automata, every patch can only change itself, but it is able to see its neighbors. Based on the states of his neighbors it is able to make a decision for its own next state.

--- Particles
Particles will have a different tint, based on their direction. 
When a particle reaches an obstacle it will turn pink, else it will simply turn green again.

--- Roads
A road patch will look for incoming patches, and for pink colours. If it detects a pink color, it will delete itself. When it is also near a crossing and it detects a pink color, it will become a wall. In this way, roads are only deleted until the crossing.

--- Flow controllers
Flow controllers have a default wait value (DWV) and a current waiting value (CWV). The CWV will decrease over time, until it is zero. Every time a particle enters, the crossing will check if the CWV is zero. If it is zero, the crossing will allow the particle to move in every direction on the crossing, the DWV will be decreased and the CWV will be set to the DWV. If the CWV is not zero, the particle will be deleted and the DWV is increased.

This means that the DWV is adjusted to the amount of incoming particles. Every time a particle enters and the CWV is not zero, the DWV will be increased. Therefore, the next time the crossing will have a longer waiting time.

--- Walls
The wall patch exists purely for practical purposes. It is an extra protection to make sure that the roads collide properly.

--- Obstacles
Obstacles can only be added by the user. they have no properties except that they are magenta coloured and very evil.


HOW TO USE IT
-------------
The GUI consists of roughly four categories:

1. Controlling the simulation
Go/go once: start the simulation, forever or for one tick
Clear world: make the world completely black
Random setup: this will create a random amount of roads, in random places. note that it will not add particles. It might take a while to the simulation to start. There will be several roads but no flow controllers yet. This means that all flow controllers have to be created with a particle first. Therefore it is suggested to enable 'add-particle-when-empty' and wait for a while.

2. Manipulating the simulation
Add new particle: add a particle in at a random place in the simulation. Only possible when there is a road.
(ON/OFF) Add particle when empty: often (especially at the beginning of the simulation), all the particles will have died. This can be because they all have collided, or have become flow controllers. ith this option, whenever there are zero particles, a new particle will be added automatically and thus the simulation will never stop.

Draw road: the user can click on the simulation and add a roadpiece, this road will be automatically extended.
Draw direction: the direction of the road.

Draw obstacle: lets the user draw an obstacle in the simulation.

3. File input/output
Five presets have been made, and a population density is suggested for each preset.
- Basic: the start of a simulation
- Advanced: a simulation that has been running for quite a while.
- Periodic: a repeating pattern, also clearly visible in the graph!
- Obstacle 1: example of an obstacle that has just been placed in a simulation.
- Obstacle 2: an obstacle in the shape of an M, which is of course crazy funny.

Also, the user has the possiblity to save/load custom presets.

4. Graph
The output graph, see above for an explanation.


THINGS TO NOTICE
----------------
- I have used different dimensions for the world. it also runs perfectly on the asked sizes (100x60), but a little more slow. I believe that the simulation comes more to its right in the current size. I discussed this with Alexander and he told me that it was not problem as long as i mentioned it. Please notice that the presets will not run on other dimensions.
- The particles can only move in straight lines, so they cannot make curves.
- Sometimes, regions will be filled with brown and green (especially when starting with a random setup) but this does not affect the simulation. Its simply a result of the interactions.
- In rare occassions, an obstacle will lead to total chaos. This is because obstacles are evil and sometimes take-over the simulation.


THINGS TO TRY
-------------
- Start the periodic preset and let it run for a while. Notice the graph.
Then add a particle (which will be placed randomly) and see how it affects the simulation. Isn't it remarkable that such a little addition can turn perfect harmony into total chaos?

- Create a new simulation and let it run until there is a good flow. Then try to lower the population density as much as possible without letting it die. At this point, the most interesting patterns emerge.

- Observe the graph for a while when you make changes. It is very interesting to see how the avarage-waiting-time and the amount of particles respond to eachother.

- Notice that every state is totally reproducable! As long as the user doesn't add anything, everything is deterministic.

EXTENDING THE MODEL
-------------------
It would be nice of the simulation would also run smooth on the dimension 100x60, but i haven't been able to optimize it any further.


RELATED MODELS
--------------
Brains Brain
File Input/Output
WireWorld


CREDITS AND REFERENCES
----------------------
Marc van Zee - F093385
M.vanZee@students.uu.nl

Artificial Intelligence
Univerity of Utrecht
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
