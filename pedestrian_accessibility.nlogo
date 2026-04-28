globals [
  total-blocked-events
  ticks-elapsed
]

breed [general-pedestrians general-pedestrian]
breed [wheelchair-users wheelchair-user]
breed [elderly-pedestrians elderly-pedestrian]

patches-own [
  patch-type  ;; "walkable" "obstacle" "kerb" "ramp"
]

turtles-own [
  speed
  travel-time
  blocked-count
  reached-goal
]

;; ─────────────────────────────────────────────
;;  SETUP
;; ─────────────────────────────────────────────
to setup
  clear-all
  set total-blocked-events 0

  ;; 1. All patches start as walkable
  ask patches [
    set patch-type "walkable"
    set pcolor white
  ]

  ;; 2. Place ONE kerb column at x = 10 (clear of spawn edge)
  ask patches with [ pxcor = 10 ] [
    set patch-type "kerb"
    set pcolor blue
  ]

  ;; 3. Distribute ramps evenly along the kerb column
  let kerb-patches patches with [ patch-type = "kerb" ]
  let step max list 1 (count kerb-patches / max list 1 ramp-count)
  let idx 0
  ask kerb-patches [
    if idx mod round(step) = 0 [
      set patch-type "ramp"
      set pcolor green
    ]
    set idx idx + 1
  ]

  ;; 4. Scatter obstacles – never on kerb/ramp, never in spawn corridor (x < 3)
  ask patches with [
    patch-type = "walkable" and
    pxcor > 3 and
    pxcor != 10
  ] [
    if random-float 1.0 < obstacle-density [
      set patch-type "obstacle"
      set pcolor grey
    ]
  ]

  ;; 5. Create agents in a clear spawn corridor (x = 0 to 2)
  create-general-pedestrians num-general [
    set color blue
    set shape "person"
    set speed 1.2
    set travel-time 0
    set blocked-count 0
    set reached-goal false
    place-in-spawn-corridor
  ]

  create-wheelchair-users num-wheelchair [
    set color red
    set shape "person"
    set speed 0.5
    set travel-time 0
    set blocked-count 0
    set reached-goal false
    place-in-spawn-corridor
  ]

  create-elderly-pedestrians num-elderly [
    set color yellow
    set shape "person"
    set speed 0.8
    set travel-time 0
    set blocked-count 0
    set reached-goal false
    place-in-spawn-corridor
  ]

  reset-ticks
end

to place-in-spawn-corridor
  let attempts 0
  let placed false
  while [ not placed and attempts < 200 ] [
    let tx random 3                          ;; x = 0, 1, or 2
    let ty (random (max-pycor - min-pycor + 1)) + min-pycor
    let target-patch patch tx ty
    if [patch-type] of target-patch = "walkable" and
       not any? turtles-on target-patch [
      setxy tx ty
      set heading 90                         ;; face right (east)
      set placed true
    ]
    set attempts attempts + 1
  ]
end

;; ─────────────────────────────────────────────
;;  GO
;; ─────────────────────────────────────────────
to go
  if not any? turtles with [ not reached-goal ] [ stop ]
  if ticks > 2000 [ stop ]

  ask general-pedestrians with [ not reached-goal ] [ move-general ]
  ask wheelchair-users    with [ not reached-goal ] [ move-wheelchair ]
  ask elderly-pedestrians with [ not reached-goal ] [ move-elderly ]

  ask turtles with [ not reached-goal ] [
    set travel-time travel-time + 1
    if pxcor >= max-pxcor - 1 [
      set reached-goal true
      set color grey      ;; fade out to show completion
    ]
  ]

  tick
end

;; ─────────────────────────────────────────────
;;  MOVEMENT PROCEDURES
;; ─────────────────────────────────────────────
to move-general
  ;; Try to move east; if blocked rotate slightly and retry
  let moved false
  let tries 0
  while [ not moved and tries < 8 ] [
    let ahead-patch patch-ahead 1
    if ahead-patch != nobody [
      if [patch-type] of ahead-patch != "obstacle" [
        forward speed
        set moved true
      ]
    ]
    if not moved [
      rt 45
      set tries tries + 1
    ]
  ]
  ;; Drift back toward eastward heading
  set heading heading + (90 - heading) * 0.3
end

to move-wheelchair
  let ahead-patch patch-ahead 1

  ;; Check for kerb ahead
  if ahead-patch != nobody and [patch-type] of ahead-patch = "kerb" [
    ;; Look for nearest ramp within search radius
    let nearby-ramp min-one-of patches with [ patch-type = "ramp" ] [ distance myself ]
    ifelse nearby-ramp != nobody and distance nearby-ramp <= ramp-search-radius [
      ;; Route toward ramp
      face nearby-ramp
      if [patch-type] of patch-ahead 1 != "obstacle" [
        forward speed * 0.6
      ]
    ] [
      ;; No accessible ramp – blocked event
      set blocked-count blocked-count + 1
      set total-blocked-events total-blocked-events + 1
      ;; Try to navigate around by going north or south
      ifelse random 2 = 0 [ set heading 0 ] [ set heading 180 ]
      if [patch-type] of patch-ahead 1 = "walkable" [
        forward speed * 0.4
      ]
    ]
    stop
  ]

  ;; Normal movement – avoid obstacles
  let moved false
  let tries 0
  while [ not moved and tries < 8 ] [
    let ap patch-ahead 1
    if ap != nobody [
      if [patch-type] of ap != "obstacle" and [patch-type] of ap != "kerb" [
        forward speed
        set moved true
      ]
    ]
    if not moved [
      rt 45
      set tries tries + 1
    ]
  ]
  set heading heading + (90 - heading) * 0.2
end

to move-elderly
  let crowd-size count other turtles in-radius 2
  let effective-speed ifelse-value (crowd-size > 4) [ speed * 0.5 ] [ speed ]

  ;; Slight kerb penalty (not fully blocked)
  let ahead-patch patch-ahead 1
  if ahead-patch != nobody and [patch-type] of ahead-patch = "kerb" [
    set effective-speed effective-speed * 0.4
  ]

  let moved false
  let tries 0
  while [ not moved and tries < 8 ] [
    let ap patch-ahead 1
    if ap != nobody [
      if [patch-type] of ap != "obstacle" [
        forward effective-speed
        set moved true
      ]
    ]
    if not moved [
      rt 45
      set tries tries + 1
    ]
  ]
  set heading heading + (90 - heading) * 0.3
end

;; ─────────────────────────────────────────────
;;  REPORTERS  (used by plots)
;; ─────────────────────────────────────────────
to-report mean-travel-time-general
  let active general-pedestrians with [ travel-time > 0 ]
  ifelse any? active [ report mean [travel-time] of active ] [ report 0 ]
end

to-report mean-travel-time-wheelchair
  let active wheelchair-users with [ travel-time > 0 ]
  ifelse any? active [ report mean [travel-time] of active ] [ report 0 ]
end

to-report mean-travel-time-elderly
  let active elderly-pedestrians with [ travel-time > 0 ]
  ifelse any? active [ report mean [travel-time] of active ] [ report 0 ]
end

to-report accessibility-gap
  report mean-travel-time-wheelchair - mean-travel-time-general
end

to-report pct-wheelchair-blocked
  let total count wheelchair-users
  ifelse total > 0 [
    report (count wheelchair-users with [ blocked-count > 0 ] / total) * 100
  ] [ report 0 ]
end

@#$#@#$#@
GRAPHICS-WINDOW
220
10
658
449
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

SLIDER
10
50
205
83
obstacle-density
obstacle-density
0
0.4
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
10
90
205
123
ramp-count
ramp-count
0
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
10
130
205
163
ramp-search-radius
ramp-search-radius
1
15
8.0
1
1
patches
HORIZONTAL

SLIDER
10
170
205
203
num-general
num-general
1
30
15.0
1
1
NIL
HORIZONTAL

SLIDER
10
210
205
243
num-wheelchair
num-wheelchair
1
20
8.0
1
1
NIL
HORIZONTAL

SLIDER
10
250
205
283
num-elderly
num-elderly
1
20
8.0
1
1
NIL
HORIZONTAL

BUTTON
10
10
100
43
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
110
10
205
43
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
670
10
980
200
Mean Travel Time by Agent Type
Ticks
Travel Time
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"General" 1.0 0 -13345367 true "" "plot mean-travel-time-general"
"Wheelchair" 1.0 0 -2674135 true "" "plot mean-travel-time-wheelchair"
"Elderly" 1.0 0 -1184463 true "" "plot mean-travel-time-elderly"

PLOT
670
210
980
400
Blockage Events (Cumulative)
Ticks
Events
0.0
100.0
0.0
10.0
true
false
"" ""
PENS
"Blocked" 1.0 0 -2674135 true "" "plot total-blocked-events"

MONITOR
670
410
820
455
Accessibility Gap (ticks)
accessibility-gap
1
1
11

MONITOR
830
410
980
455
% Wheelchair Blocked
pct-wheelchair-blocked
1
1
11

MONITOR
10
295
205
340
Total Blocked Events
total-blocked-events
0
1
11

MONITOR
10
345
205
390
Ticks Elapsed
ticks
0
1
11

TEXTBOX
10
400
205
460
Legend:\nWhite = footpath  Grey = obstacle\nBlue = kerb  Green = ramp\nBlue agents = general  Red = wheelchair\nYellow = elderly  Grey (faded) = arrived
10
0.0
1

@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
