;;CYBERSLUG

;;Create animats and assign qualities

breed [Cslugs Cslug]
breed [probos proboscis]
breed [flabs flab]
breed [hermis hermi]
breed [fauxflabs fauxflab]
probos-own [parent phase]
Cslugs-own [sns_hermi Reward Reward_neg App_State_Switch sns_flab_left sns_flab_right sns_hermi_left sns_hermi_right sns_betaine_left sns_betaine_right speed turn-angle Nutrition Satiation
 App_State Incentive Somatic_Map Vf Vh alpha_hermi beta_hermi lambda_hermi alpha_flab beta_flab lambda_flab delta_Vh delta_Vf hermcount flabcount
fauxflabcount]
patches-own [odor_flab odor_hermi odor_betaine]

to startup
  setup

end

to setup
  clear-all

  create-Cslugs 1 [
    set shape "Cslug"
    set color orange - 2
    set size 16
    set heading 0

    set Nutrition 0.5
    set Incentive 0
    set Somatic_Map 0
    set Satiation 0.5

;Preliminary Rescorla-Wagner parameters for learning Hermi & Flab odors. V is learned value of an odor, alpha is the salience
;(or noticeability) of an odor, beta is the learning rate, and lambda sets the maximum value of learning (between 0 and 1).
    set Vf 0
    set Vh 0
    set alpha_hermi 0.5
    set beta_hermi 1
    set lambda_hermi 1
    set alpha_flab 0.5
    set beta_flab 1
    set lambda_flab 1

;Give Cslug a feeding apparatus for decorative effect
    hatch-probos 1 [
      set shape "airplane"
      set size size / 2
      set parent myself
    ]

; Track Cslug's path
    pen-down
  ]

 create-flabs flab-populate [
    set shape "circle"
    set size 1
    set color red + 2
    setxy random-xcor random-ycor
  ]

  create-hermis hermi-populate [
    set shape "circle"
    set size 1
    set color green + 2
    setxy random-xcor random-ycor
  ]

    create-fauxflabs fauxflab-populate [
    set shape "circle"
    set size 1
    set color blue
    setxy random-xcor random-ycor
  ]

    reset-ticks

end

to go

;; allow user to drag things around
  if mouse-down? [
    ask Cslugs [
      if distancexy mouse-xcor mouse-ycor < 3 [setxy mouse-xcor mouse-ycor]
    ]
    ask flabs [
      if distancexy mouse-xcor mouse-ycor < 3 [setxy mouse-xcor mouse-ycor]
    ]
    ask hermis [
      if distancexy mouse-xcor mouse-ycor < 3 [setxy mouse-xcor mouse-ycor]
    ]
  ]

; Initialize, deposit, diffuse, and evaporate odors
  ask hermis [set odor_hermi 0.5]
  ask hermis [set odor_betaine 0.5]
  ask flabs [set odor_flab 0.5]
  ask flabs [set odor_betaine 0.5]
  ask fauxflabs [set odor_flab 0.5]
  ask fauxflabs [set odor_betaine 0.5]

;; diffuse odors
  diffuse odor_hermi 0.5
  diffuse odor_flab 0.5
  diffuse odor_betaine 0.5

;; evaporate odors
  ask patches [
    set odor_hermi 0.95 * odor_hermi
    set odor_flab 0.95 * odor_flab ; changed from 0.98 to 0.95
    set odor_betaine 0.95 * odor_betaine
    recolor-patches
  ]

;; Cslug actions

  ask Cslugs [

    update-sensors
    update-proboscis
    set speed 0.06
    set turn-angle -1 + random-float 2


    ;; Detecting prey
    set sns_hermi (sns_hermi_left + sns_hermi_right ) / 2
    let sns_betaine (sns_betaine_left + sns_betaine_right) / 2
    let sns_flab (sns_flab_left + sns_flab_right ) / 2
    let H (sns_hermi - sns_flab)
    let F (sns_flab - sns_hermi)

    set Reward sns_betaine / (1 + (0.5 * Vh * sns_hermi) ) + 1.32 * Vh * sns_hermi ; R
    set Reward_neg 1.32 * Vf * sns_flab ; R-



    set Nutrition Nutrition - 0.0005 * Nutrition ; Nutritional state declines with time
    set Satiation 1 / ((1 + 0.7 * exp(-4 * Nutrition + 2)) ^ (2))
    set Incentive Reward - Reward_neg;
    set Somatic_Map (- ((sns_flab_left - sns_flab_right) / (1 + exp (-50 * F)) + (sns_hermi_left - sns_hermi_right) / (1 + exp (-50 * H))))
    set App_State 0.01 + (1 / (1 + exp(- (Incentive * 0.6) + 10 * satiation)) + 0.1 * ((App_State_Switch - 1) * 0.5)); + 0.25
    set App_State_Switch (((-2 / (1 + exp(-100 * (App_State - 0.245)))) + 1)) ; The switch for approach-avoidance

    set turn-angle (2 * App_State_Switch) / (1 + exp (3 * Somatic_Map)) - App_State_Switch

    set speed 0.1

    rt turn-angle
    fd speed

;; PREY CONSUMPTION AND ODOR LEARNING

    let hermitarget other (turtle-set hermis) in-cone (0.4 * size) 45
    if any? hermitarget [
      set Nutrition Nutrition + count hermitarget * 0.3
      set hermcount hermcount + 1
      ask hermitarget [setxy random-xcor random-ycor]
      set delta_Vh alpha_hermi * beta_hermi * (lambda_hermi - Vh)
      set Vh Vh + delta_Vh ; The Rescorla-Wagner Learning Algorithm
    ]

    let flabtarget other (turtle-set flabs) in-cone (0.4 * size) 45
    if any? flabtarget [
      set Nutrition Nutrition + count flabtarget * 0.3;
      set flabcount flabcount + 1
      ask flabtarget [setxy random-xcor random-ycor]
      set delta_Vf alpha_flab * beta_flab * (lambda_flab - Vf)
      set Vf Vf + delta_Vf ; The Rescorla-Wagner Learning Algorithm
    ]

    let fauxflabtarget other (turtle-set fauxflabs) in-cone (0.4 * size) 45
    if any? fauxflabtarget [
      set Nutrition Nutrition + count fauxflabtarget * 0.3
      set fauxflabcount fauxflabcount + 1
      ask fauxflabtarget [setxy random-xcor random-ycor]

      set delta_Vf alpha_flab * beta_flab * (0 - Vf)
      set Vf Vf + delta_Vf; Odor_flab is linked to Reward, a virtual extinction mechanism
    ]

  ]


;; Hermi and Flab actions

  ask flabs [
    rt -1 + random-float 2
    fd 0.02
  ]

  ask hermis [
    rt -1 + random-float 2
    fd 0.02
  ]

  ask fauxflabs [
    rt -1 + random-float 2
    fd 0.02
  ]


  tick
  if ticks = 150000 [stop] ; definitie end of an epoch of play
end

to update-proboscis
 ask probos [
    set heading [heading] of parent
    setxy ([xcor] of parent) ([ycor] of parent)
    ifelse ([sns_betaine_left] of parent > 5.5) or ([sns_betaine_right] of parent > 5.5)
      [set phase (phase + 1) mod 20]
      [set phase 0]
    fd (0.15 * size) + (0.1 * phase)
  ]
end


to update-sensors

  let odor_flab_left [odor_flab] of patch-left-and-ahead 40 (0.4 * size)
  ifelse odor_flab_left > 1e-7
    [set sns_flab_left 7 + (log odor_flab_left 10)]
    [set sns_flab_left 0]

  let odor_flab_right [odor_flab] of patch-right-and-ahead 40 (0.4 * size)
  ifelse odor_flab_right > 1e-7
    [set sns_flab_right 7 + (log odor_flab_right 10)]
    [set sns_flab_right 0]

  let odor_hermi_left [odor_hermi] of patch-left-and-ahead 40 (0.4 * size)
  ifelse odor_hermi_left > 1e-7
    [set sns_hermi_left 7 + (log odor_hermi_left 10)]
    [set sns_hermi_left 0]

  let odor_hermi_right [odor_hermi] of patch-right-and-ahead 40 (0.4 * size)
  ifelse odor_hermi_right > 1e-7
    [set sns_hermi_right 7 + (log odor_hermi_right 10)]
    [set sns_hermi_right 0]

  let odor_betaine_left [odor_betaine] of patch-left-and-ahead 40 (0.4 * size)
  ifelse odor_betaine_left > 1e-7
    [set sns_betaine_left 7 + (log odor_betaine_left 10)]
    [set sns_betaine_left 0]

  let odor_betaine_right [odor_betaine] of patch-right-and-ahead 40 (0.4 * size)
  ifelse odor_betaine_right > 1e-7
    [set sns_betaine_right 7 + (log odor_betaine_right 10)]
    [set sns_betaine_right 0]

end

to recolor-patches
    ifelse odor_flab > odor_hermi [
      set pcolor scale-color red odor_flab 0 1
    ][
      set pcolor scale-color green odor_hermi 0 1
    ]
end


to show-sensors
  ask Cslugs [
    ask patch-left-and-ahead 40 (0.4 * size) [set pcolor yellow]
    ask patch-right-and-ahead 40 (0.4 * size) [set pcolor yellow]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
205
10
728
524
-1
-1
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
-51
51
-50
50
1
1
1
ticks
30.0

BUTTON
37
19
100
52
NIL
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
112
20
174
53
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
1

MONITOR
41
286
97
331
Hermi-L
[sns_hermi_left] of Cslug 0
2
1
11

MONITOR
112
286
168
331
Hermi-R
[sns_hermi_right] of Cslug 0
2
1
11

MONITOR
39
333
96
378
Flab-L
[sns_flab_left] of one-of Cslugs
2
1
11

MONITOR
112
338
169
383
Flab-R
[sns_flab_right] of one-of Cslugs
2
1
11

BUTTON
76
63
139
96
step
go
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
48
497
156
530
NIL
show-sensors
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
900
84
978
129
Nutrition
[nutrition] of Cslug 0
2
1
11

MONITOR
909
137
975
182
Satiation
[satiation] of Cslug 0
2
1
11

MONITOR
64
391
144
436
sns_betaine
[(sns_betaine_left + sns_betaine_right) / 2] of Cslug 0
2
1
11

MONITOR
756
45
856
90
V_Hermi (Learning)
[Vh] of Cslug 0
3
1
11

MONITOR
755
255
857
300
Incentive
[Incentive] of Cslug 0
2
1
11

MONITOR
761
310
847
355
Somatic_Map
[Somatic_Map] of Cslug 0
2
1
11

MONITOR
756
101
856
146
V_Flab (Learning)
[Vf] of Cslug 0
3
1
11

MONITOR
756
368
855
413
Hermissenda eaten
[hermcount] of Cslug 0
0
1
11

MONITOR
758
422
855
467
Flabellina eaten
[flabcount] of Cslug 0
0
1
11

MONITOR
749
477
865
522
Faux-Flabellina eaten
[fauxflabcount] of Cslug 0
0
1
11

MONITOR
771
151
843
196
App_State
[App_State] of Cslug 0
2
1
11

MONITOR
755
202
858
247
App_State_Switch
[App_State_Switch] of Cslug 0
2
1
11

MONITOR
916
192
973
237
Reward
[reward] of Cslug 0
2
1
11

MONITOR
29
445
96
490
sns_hermi
[sns_hermi] of Cslug 0
2
1
11

MONITOR
903
247
984
292
Reward-neg
[Reward_neg] of Cslug 0
2
1
11

MONITOR
43
232
100
277
Bet-L
[sns_betaine_left] of Cslug 0
2
1
11

MONITOR
113
233
170
278
Bet-R
[sns_betaine_right] of Cslug 0
2
1
11

SLIDER
21
150
193
183
flab-populate
flab-populate
0
15
10.0
1
1
NIL
HORIZONTAL

SLIDER
21
111
193
144
hermi-populate
hermi-populate
0
15
3.0
1
1
NIL
HORIZONTAL

SLIDER
20
189
192
222
fauxflab-populate
fauxflab-populate
0
15
0.0
1
1
NIL
HORIZONTAL

MONITOR
107
445
172
490
sns_flab
[sns_hermi] of Cslug 0
2
1
11

@#$#@#$#@
## ## WHAT IS IT?

Cyberslug™ reproduces the decisions for approach or avoidance in the predatory sea-slug Pleurobranchaea californica. It applies relations discovered in the nervous system of the real animal that underlie decisions in foraging for prey. Those decisions are based on motivation and reward learning. The approach-avoidance decision is basic to foraging as well as to most other economic behavior.

## ## HOW IT WORKS

Approach-avoidance choice is organized around appetitive state, which is how the Cyberslug agent feels in terms of hunger, the savory qualities of prey odor, and what it remembers about earlier experience with that prey. The agent adds up sensation, motivation (satiation/hunger), and memory from moment-to-moment into its appetitive state. Appetitive state controls the switch for approach vs. avoidance turn responses to prey.

The difference of odor sensation at two sensors on Cyberslug's head is used to calculate the probable location of prey for the turn response. The sensors respond to betaine, an odor representing the energy value of the prey (like the taste of sugar to the human tongue), and to the learned identifying odors of Hermi and Flab.

## ## HOW TO USE IT

The user can occupy the world with valuable and dangerous prey, Hermis and Flabs respectively, with the slider bars. In the beginning the simulation starts with three Hermis and 10 Flabs. Cyberslug learns to prefer or avoid the different prey.

The progress of learning is shown in the interface tabs V_hermi and V_flab. Other tabs show important quantities used in calculating the decision: the nutritional and satiation states, summed appetitive state (App_State), and the positive and negative rewards and incentives sensed for prey. There is also a tab for Cyberslug's estimate of the odor source direction (Somatic_Map). Other tabs on the left show the strengths of the three odors sensed at the two sensors, and the averaged strengths of the odors (sns_odor).

Another animal prey can be introduced, Faux-Flab, which has the odor of the noxious Flab but is not dangerous. It is a "Batesian mimic", which is a harmless species that evolved to imitate the warning signals of a harmful species directed at a predator of them both.  It may receive protection if the predator learns from the real Flab that the odor can signal danger. Three tabs on the right record the numbers of the different prey eaten.

The program is set to run for 150,000 software cycles (ticks). This can be changed in the code.

## ## THINGS TO NOTICE

What happens to approach-avoidance decision when Cyberslug is not hungry? What happens to decision about the noxious Flab prey when the Cyberslug is very hungry?


## ## THINGS TO TRY

What is the effect on prey selection when Faux-Flab is introduced?.
What are the effects of altering the densities of the different prey?
At what different prey densities does Faux-Flab receive protection or not?
Is the Cyberslug always accurate in prey choice? Why or why not, do you think?
Learning happens here according to the Rescorla-Wagner rule for classical learning. What happens if you go into the program and alter the values of the Rescorla-Wagner equation? What are the effects on the Batesian mimic of altering the densities of itself, the prey it mimics, and the predator?

## ## CREDITS AND REFERENCES

Jeffrey W Brown, Derek Caetano-Anollés, Marianne Catanho, Ekaterina Gribkova, Nathaniel Ryckman, Kun Tian, Mikhail Voloshin, and Rhanor Gillette. Implementing Goal-Directed Foraging Decisions of a Simpler Nervous System in Simulation. In preparation, 2017.
The relations are discussed in detail in the following technical references:
1. Brown JW, Caetano-Anollés D, Catanho M, Gribkova E, Ryckman N, Tian K, Voloshin M, and Gillette R. Implementing Goal-Directed Foraging Decisions of a Simpler Nervous System in Simulation. In preparation, 2017.
2. Gillette R, Brown JW (2015) The sea slug, Pleurobranchaea californica: A signpost species in the evolution of complex nervous systems and behavior.  Integrative and Comparative Biology, v. 55, pages 1058-1069
3. http://www.scholarpedia.org/article/Pleurobranchaea. The article's Curator is: R Gillette. Published November 13, 2014.
4. Hirayama K and others (2012) A core circuit module for cost/benefit decision. Frontiers in Neuroscience, v. 6, pages 123-128.
5. Gillette R and others (2000) Cost-benefit analysis potential in feeding behavior of a predatory snail by integration of hunger, taste, and pain. Proceedings of the National Academy of Sciences USA, v. 97, pages3585-3590.
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

cslug
true
0
Polygon -7500403 true true 135 285 165 285 210 240 240 165 225 105 210 90 195 75 105 75 90 90 75 105 60 165 90 240
Polygon -7500403 true true 150 60 240 60 210 105 90 105 60 60
Polygon -7500403 true true 195 120 255 90 195 90
Polygon -7500403 true true 105 120 45 90 105 90

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

pleuro
true
0
Polygon -7500403 true true 135 285 165 285 210 240 240 165 225 105 210 90 195 75 105 75 90 90 75 105 60 165 90 240
Polygon -7500403 true true 150 60 240 60 210 105 90 105 60 60
Polygon -7500403 true true 195 120 255 90 195 90
Polygon -7500403 true true 105 120 45 90 105 90

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
NetLogo 6.0.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
