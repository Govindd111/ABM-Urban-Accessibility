globals [
  total-blocked-events
  kerb-x
]

breed [general-pedestrians general-pedestrian]
breed [wheelchair-users wheelchair-user]
breed [elderly-pedestrians elderly-pedestrian]

patches-own [
  patch-type
]

turtles-own [
  speed
  travel-time
  blocked-count
  reached-goal
]

to setup
  clear-all
  random-seed 40
  set total-blocked-events 0
  set kerb-x min-pxcor + 35

  ask patches [
    set patch-type "walkable"
    set pcolor white
  ]

  ask patches with [ pxcor = kerb-x ] [
    set patch-type "kerb"
    set pcolor blue
  ]

  let kerb-list sort-on [pycor] patches with [ patch-type = "kerb" ]
  let total-kerb length kerb-list
  let safe-ramps min list ramp-count total-kerb
  if safe-ramps < 0 [ set safe-ramps 0 ]

  if safe-ramps > 0 [
    let r 0
    while [ r < safe-ramps ] [
      let target-index 0
      ifelse safe-ramps = 1 [
        set target-index 0
      ] [
        set target-index round (r * (total-kerb - 1) / (safe-ramps - 1))
      ]
      if target-index >= total-kerb [ set target-index total-kerb - 1 ]
      ask item target-index kerb-list [
        set patch-type "ramp"
        set pcolor green
      ]
      set r r + 1
    ]
  ]

  ask patches with [
    patch-type = "walkable" and
    pxcor > min-pxcor + 3 and
    pxcor != kerb-x
  ] [
    if random-float 1.0 < obstacle-density [
      set patch-type "obstacle"
      set pcolor grey
    ]
  ]

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
    let tx min-pxcor + random 3
    let ty min-pycor + random (max-pycor - min-pycor + 1)
    let target-patch patch tx ty
    if target-patch != nobody and
       [patch-type] of target-patch = "walkable" and
       not any? turtles-on target-patch [
      setxy tx ty
      set heading 90
      set placed true
    ]
    set attempts attempts + 1
  ]
end

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
      set color grey
    ]
  ]

  tick
end

to move-general
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
  set heading heading + (90 - heading) * 0.3
end

to move-wheelchair
  let ahead-patch patch-ahead 1

  if ahead-patch != nobody and [patch-type] of ahead-patch = "kerb" [
    let nearby-ramp min-one-of patches with [ patch-type = "ramp" ] [ distance myself ]
    ifelse nearby-ramp != nobody and distance nearby-ramp <= ramp-search-radius [
      face nearby-ramp
      if [patch-type] of patch-ahead 1 != "obstacle" [
        forward speed * 0.6
      ]
    ] [
      set blocked-count blocked-count + 1
      set total-blocked-events total-blocked-events + 1
      ifelse random 2 = 0 [ set heading 0 ] [ set heading 180 ]
      if [patch-type] of patch-ahead 1 = "walkable" [
        forward speed * 0.4
      ]
    ]
    stop
  ]

  let moved false
  let tries 0
  while [ not moved and tries < 8 ] [
    let ap patch-ahead 1
    if ap != nobody [
      if [patch-type] of ap != "obstacle" and
         [patch-type] of ap != "kerb" [
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
