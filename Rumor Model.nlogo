extensions [array nw csv]        ;; necessary to use the array code utilized in spread rumor

globals
[
  sum-link-weight         ;; the sum of all the link-weight's a turtle has between another
  initial-rumor           ;; the original rumor
  zero-rumor              ;; rumor for people who have not heard it yet
  total-changes           ;; to measure the toal number of instancaces a rumor changes
  spreading               ;; number of turtles checking link-neighbors at each time step
  spread                  ;; list of spreading values
  infecting               ;; number of turtles infecting link-neighbors at each time step
  infect                  ;; list of infecting values
  infect%                 ;; list of % of students infected per time step
  fidelity                ;; list of number turtles with unaltered rumor at each time step
  sum-pop-link-weight     ;; sum of the link-strength values, used to find average link strength
  ave-pop-link-weight     ;; average link-weight values recorded at each successfull incidence of rumor transmission
  trans-total             ;; total number of times the rumor is successfully transmitted

  num-memes               ;; number of memes within the rumor
  meme-length             ;; length of each meme
  codon-fitness           ;; fitness of each codon (how likely the codon will be distorted)
  meme-relevance          ;; value that is compared to turtle relevance to determine if the meme is relevant
  juiciness               ;; can be 0, 0.5, or 1 depending on how many people find the meme relevant to talk about
  total-meme-lengths      ;; keeps track of the length of previous memes combined
  meme-length-list        ;; array containing all meme lengths
  codon-fitness-list      ;; array containing all codon fitnesses
  meme-relevance-list     ;; array containing all meme juicinesses

  credibility             ;; truthfulness of a times the link weight of a and b
  sharing-probability     ;; probablity meme i is passed between a and b
  distortion-probability  ;; probability meme i is distorted when passed between a and b
  meme-distortion         ;; average distortion of meme i
  meme-fitness            ;; average fitness of meme i
  sharability
  
  sport-count
  greek-count
  house-count
  club-count
  ]

links-own
[
  link-type               ;; sport = 1, greek = 2, club = 3, house = 4
]

turtles-own
[
  infected?             ;; if true, the turtle has heard a rumor
  sport?                ;; if true, the turtle plays a sport
  greek?                ;; if true, the turtle is part of a greek organization
  club?                 ;; if true, the turtle is part of club
  house?                ;; if true, the turtle lives in a dorm on campus
  known                 ;; array that stores the rumor a turtle is given
  sport-sg              ;; sport subgroup classification
  greek-sg              ;; greek subgroup classification
  club-sg               ;; club subgroup classification
  house-sg              ;; housing subgroup classification
  rumor                 ;; list containing 0's and 1's that is the information in the rumor
  checked?              ;; true for turtle b if turtle a has tried to pass rumor
  loner?                ;; agents with no links
  links-between         ;; number of links a has with b
  link-count            ;; total number of links for a turtle
  truthfulness          ;; percent of the time a turtle will tell the full truth
  turtle-relevance      ;; if this value is within a certain range from the meme relevance, then the meme is relvant and juiciness increases by 0.5
]


undirected-link-breed [sport-links sport-link]         
undirected-link-breed [greek-links greek-link]
undirected-link-breed [club-links club-link]
undirected-link-breed [house-links house-link]

to setup
  clear-all
  set sum-pop-link-weight 0
  set trans-total 0
  set ave-pop-link-weight 0
  set initial-rumor []
  set zero-rumor []
  set spread []
  set infect []
  set fidelity []
  set infect% []
  set meme-length-list []
  set codon-fitness-list []
  set meme-relevance-list []
  setup-network                          ;;links turtles with the same social subgroup
  setup-rumor

  ask n-of num-start-pop turtles with [loner? = false]
    [set infected? true               ;;infects start group
     set rumor initial-rumor
     set known array:from-list rumor
     set checked? true
     set color red]

  ask turtles with [infected? = false]      ;;sets the rumor of those not infected to all zeroes
    [set known array:from-list n-values (rumor-length)  [0]
     set rumor zero-rumor]
  reset-ticks

end

to setup-rumor
  let n 0                        ;;set intial rumor to all 1's
      while [n < rumor-length]
        [
          set initial-rumor lput 1 initial-rumor
          set n n + 1
        ]

  let m 0                        ;;set zero rumor to all 0's
      while [m < rumor-length]
        [
          set zero-rumor lput 0 zero-rumor
          set m m + 1
        ]
  set num-memes 0                                               ;;memes lengths are randomly chosen between 1 and the max meme length
  set total-meme-lengths 0                                      ;;the rumor is filled in by these memes and their lengths are recorded in meme-length-list
  while [rumor-length - total-meme-lengths > max-meme-length]
  [
    set meme-length 1 + random max-meme-length
    set total-meme-lengths total-meme-lengths + meme-length
    set meme-length-list lput meme-length meme-length-list
    set num-memes num-memes + 1
  ]
  if rumor-length - total-meme-lengths <= max-meme-length
  [
    let space-left (rumor-length - total-meme-lengths)
    set meme-length-list lput space-left meme-length-list
    set num-memes num-memes + 1
  ]

  let r 1                                                         ;;sets codon fitness to a random float between 0 and 1
  while [r <= rumor-length]
  [
    set codon-fitness .8 + random-float .2
    set codon-fitness-list lput codon-fitness codon-fitness-list
    set r r + 1
  ]

  let s 1                                                         ;;sets meme relevance to a random float between 0 and 1
  while [s <= num-memes]
  [
    set meme-relevance random-float 1
    set meme-relevance-list lput meme-relevance meme-relevance-list
    set s s + 1
  ]
end

to setup-network
  create-turtles number-of-students
  [;;turtles
    set shape "circle"
    set size .5
    set color green
    setxy (random-xcor * 0.95) (random-ycor * 0.95)
    set sport? false
    set greek? false
    set club? false
    set house? false
    set loner? false
    if random-float 1 < .22 [ set sport? true set sport-sg 1 + random sport-groups ]     ;;25% of students participate in a sport
    if random-float 1 < .22 [ set greek? true set greek-sg 1 + random greek-groups ]     ;;50% of students participate in greek life
    if random-float 1 < .22 [ set house? true set house-sg 1 + random house-groups ]     ;;71% of students live in a dorm on campus
    if random-float 1 < .22 [ set club? true set club-sg 1 + random club-groups ]        ;;40% of students participate in a club
    set infected? false
    set checked? false
    set link-count 0
    set truthfulness random-float 1
    set turtle-relevance random-float 1
  ]

    let x 1               ;;creates all sport links
    while [x <= sport-groups]
    [ if count turtles with [ sport-sg = x ] > 1
      [ ask turtles with [ sport-sg = x]
        [ create-sport-links-with other turtles with [sport-sg = x]
          [ set link-type 1
            set color white
            hide-link
          ]
          set link-count link-count + 1
        ]
      ]
      set x x + 1
    ]

    let y 1               ;;creates all greek links
    while [y <= greek-groups]
    [ if count turtles with [greek-sg = y] > 1
      [ ask turtles with [greek-sg = y]
        [ create-greek-links-with other turtles with [greek-sg = y]
          [ set link-type 2
            set color blue
            hide-link
          ]
          set link-count link-count + 1
        ]
      ]
      set y y + 1
    ]

    let z 1               ;;creates all club links
    while [z <= club-groups]
    [ if count turtles with [club-sg = z] > 1
      [ ask turtles with [club-sg = z]
        [ create-club-links-with other turtles with [club-sg = z]
          [ set link-type 3
            set color yellow
            hide-link
          ]
          set link-count link-count + 1
        ]
       ]
      set z z + 1
    ]

    let q 1               ;;creates all house links
    while [q <= house-groups]
    [ if count turtles with [house-sg = q] > 1
      [ ask turtles with [house-sg = q]
        [ create-house-links-with other turtles with [house-sg = q]
          [ set link-type 4
            set color red
            hide-link
          ]
          set link-count link-count + 1
        ]
      ]
      set q q + 1
    ]

   ask turtles with [link-count = 0] [set loner? true set color blue]

end

to go
  print-results
  spread-rumor
  tick
  
end

to spread-rumor
  set spreading 0 
  set infecting 0
  ask turtles with [infected? = true and loner? = false]
    [ let a self
      let me [who] of a 
       let x count link-neighbors
        ask n-of (random x) link-neighbors                     ;;takes a random subset of a's neighbors
        [ let b self
          if [rumor] of a != 0                                 ;;makes sure that a is linked with b and that a's 'rumor' is not = 0
          [ set links-between count-links a b
            set sum-link-weight sum-links2 a b                  ;;calculates the link weight and credibilities
            let credibility-a-to-b take-credibility a b
            let credibility-b-to-a take-credibility b a

            ask b
            [ set checked? true
              set spreading spreading + 1

            ifelse [infected?] of b = false

                 [ ;; if b is not infected
                 set known array:from-list [rumor] of a                    ;;sets the array 'known' of b to the values in the list 'rumor' of a
                                                                           ;;we convert the array to a list because the list is easier to alter
                 let i 0
                 let k 0
                 let meme-lengths-passed 0

                  while [i < num-memes]
                    [set meme-fitness average-meme-fitness (i)
                     set meme-distortion average-meme-distortion (i) (me) ;if meme-distortion != 1 [print meme-distortion]
                     set juiciness 0
                     set juiciness calculate-juiciness (relevancy-range) ([turtle-relevance] of a) (item i meme-relevance-list)
                     set juiciness calculate-juiciness (relevancy-range) ([turtle-relevance] of b) (item i meme-relevance-list)
                     set sharability calculate-sharability (juiciness) (sum-link-weight) (meme-distortion)
                     set sharing-probability calculate-meme-sharing (sharability) ;if sharing-probability < .9 [print sharability print sharing-probability]
                     ifelse random-float 1 <= sharing-probability
                      [set distortion-probability calculate-meme-distortion (meme-fitness) ([truthfulness] of a) ([truthfulness] of b) (meme-distortion) ;print distortion-probability ;if distortion-probability != 0 [print meme-fitness print [truthfulness] of a print [truthfulness] of b print meme-distortion print distortion-probability]

                      while [k < (item i meme-length-list + meme-lengths-passed)]                           ;;changes b's codons
                        [ifelse random-float 1 < distortion-probability and item k [rumor] of a < 5

                          [array:set ([known] of b) k (item k [rumor] of a + 1)
                           set rumor array:to-list [known] of b]

                          [array:set ([known] of b) k (item k [rumor] of a)
                           set rumor array:to-list [known] of b]

                         set k k + 1
                        ]

                     ]

                     [
                       while [k < (item i meme-length-list + meme-lengths-passed)]                           ;;a forgets to tell the meme and changes b's codons to 0
                        [
                         array:set ([known] of b) k 0
                         set rumor array:to-list [known] of b

                         set k k + 1
                        ]

                     ]

                     set meme-lengths-passed meme-lengths-passed + item i meme-length-list
                     set i i + 1
                    ]


                  set rumor array:to-list [known] of myself
                  set color red
                  set infected? true
                  set sum-pop-link-weight sum-pop-link-weight + (sum-link-weight / links-between)     ;;if infected, adds the link weight to sum of infected population's link weights
                  set trans-total trans-total + 1                                                  ;;tracks the number of times an agent is infected
                  ask link-with a [show-link]                                                      ;;shows link during go procedure
                  set infecting infecting + 1                                                      ;;tracks infected per time step
                 ]


                 [ ;; if b is infected
                  let i 0        ;;meme number
                  let k 0        ;;codon number
                  let meme-lengths-passed 0

                  while [i < num-memes]
                    [  set meme-fitness average-meme-fitness (i)
                       set meme-distortion average-meme-distortion (i) (me) ;if meme-distortion != 1 [print meme-distortion]
                       set juiciness calculate-juiciness (0.2) ([turtle-relevance] of a) (item i meme-relevance-list)
                       set juiciness calculate-juiciness (0.2) ([turtle-relevance] of b) (item i meme-relevance-list)
                       set sharability calculate-sharability (juiciness) (sum-link-weight) (meme-distortion)
                       set sharing-probability calculate-meme-sharing (sharability) ;if sharing-probability < .9 [print sharability print sharing-probability]
                       set distortion-probability calculate-meme-distortion (meme-fitness) ([truthfulness] of a) ([truthfulness] of b) (meme-distortion) ;print distortion-probability ;if distortion-probability != 0 [print meme-fitness print [truthfulness] of a print [truthfulness] of b print meme-distortion print distortion-probability]


                      ifelse random-float 1 <= sharing-probability
                      [

                    while [k < item i meme-length-list + meme-lengths-passed]                           ;;changes each codon within the meme
                      [
                       ifelse item k [rumor] of a != item k [rumor] of b                 ;;if they don't have the same codon
                       [


                       if item k [rumor] of a != 0 and item k [rumor] of b != 0    ;;as long as one of them knows something
                        [
                          if item k [rumor] of a = 0 and credibility-b-to-a > credibility-a-to-b       ;;if a's codon = 0 and b has a higher credibility, update a
                          [
                            ifelse random-float 1 < distortion-probability and item k [rumor] of b < 5

                            [array:set ([known] of a) k (item k [rumor] of b + 1)
                             set rumor array:to-list [known] of a]

                            [array:set ([known] of a) k (item k [rumor] of b)
                             set rumor array:to-list [known] of a]
                          ]

                        if item k [rumor] of b = 0 and credibility-a-to-b > credibility-b-to-a         ;;if b's codon = 0 and a has a higher credibility, update b
                        [
                          ifelse random-float 1 < distortion-probability and item k [rumor] of a < 5

                          [array:set ([known] of b) k (item k [rumor] of a + 1)
                           set rumor array:to-list [known] of b]

                          [array:set ([known] of b) k (item k [rumor] of a)
                           set rumor array:to-list [known] of b]
                        ]

                        if credibility-a-to-b > credibility-b-to-a and item k [rumor] of a != 0                 ;;if a's credibility is higher than b's, then update b's rumor
                         [
                          ifelse random-float 1 < distortion-probability and item k [rumor] of a < 5

                          [array:set ([known] of b) k (item k [rumor] of a + 1)
                           set rumor array:to-list [known] of b]

                          [array:set ([known] of b) k (item k [rumor] of a)
                           set rumor array:to-list [known] of b]
                         ]

                        if credibility-b-to-a > credibility-a-to-b and item k [rumor] of b != 0                 ;;if b's credibility is higher, then update a's rumor
                         [
                          ifelse random-float 1 < distortion-probability and item k [rumor] of b < 5


                          [array:set ([known] of a) k (item k [rumor] of b + 1)
                           set rumor array:to-list [known] of a]

                          [array:set ([known] of a) k (item k [rumor] of b)
                           set rumor array:to-list [known] of a]
                          ]

                        if credibility-a-to-b = credibility-b-to-a                   ;;if a and b have equal credibilities, then it's a 50/50 chance as to whos rumor gets updated
                         [
                          ifelse random-float 1 <= 0.5

                          [array:set ([known] of a) k (item k [rumor] of b)
                           set rumor array:to-list [known] of a]

                          [array:set ([known] of b) k (item k [rumor] of a)
                           set rumor array:to-list [known] of b]
                         ]
                        ]

                        set k k + 1



                    ]

                    [
                    set k k + 1

                    ]
                   ]
                    set k meme-lengths-passed + item i meme-length-list
                   set meme-lengths-passed meme-lengths-passed + item i meme-length-list
                   set i i + 1

                  ]

                  [set k meme-lengths-passed + item i meme-length-list
                   set meme-lengths-passed meme-lengths-passed + item i meme-length-list
                   set i i + 1
                  ]

                   ]
                    set color white
                    set sum-pop-link-weight sum-pop-link-weight + (sum-link-weight / links-between)
                    set trans-total trans-total + 1
                    set infecting infecting + 1

                  ]
                ]
              ]
            ]
          ]






end

to-report sum-links [a b]             ;;increases the link strength if agents are in the same subgroup
  set sum-link-weight 0

  if [sport-sg] of a = [sport-sg] of b
     [ set sum-link-weight sum-link-weight + sport-weight ]

  if [greek-sg] of a = [greek-sg] of b
     [ set sum-link-weight sum-link-weight + greek-weight ]

  if [club-sg] of a = [club-sg] of b
     [ set sum-link-weight sum-link-weight + club-weight ]

  if [house-sg] of a = [house-sg] of b
     [ set sum-link-weight sum-link-weight + house-weight ]

  set sum-link-weight sum-link-weight / (count-links a b)

  report sum-link-weight
end

to-report sum-links2 [a b]             ;;increases the link strength if agents are in the same subgroup
  set sum-link-weight 0
  let sport 0
  let greek 0
  let club 0
  let house 0
  let name ""

  if [sport-sg] of a = [sport-sg] of b
     [ set sport sport-weight 
       set name word name "s"]

  if [greek-sg] of a = [greek-sg] of b
     [ set greek greek-weight 
       set name word name "g"]

  if [club-sg] of a = [club-sg] of b
     [ set club club-weight 
       set name word name "c"]

  if [house-sg] of a = [house-sg] of b
     [ set house house-weight 
       set name word name "h"]
     
  if name = ""
  [set sum-link-weight 0]
  
  if name = "s"
  [set sum-link-weight sport]
  
  if name = "g"
  [set sum-link-weight greek]

  if name = "c"
  [set sum-link-weight club]
  
  if name = "h"
  [set sum-link-weight house]
  
  if name = "sg"
  [set sum-link-weight (sport + greek) - (sport * greek)]
  
  if name = "sc"
  [set sum-link-weight (sport + club) - (sport * club)]
  
  if name = "sh"
  [set sum-link-weight (sport + house) - (sport * house)]
  
  if name = "gc"
  [set sum-link-weight (greek + club) - (greek * club)]
  
  if name = "gh"
  [set sum-link-weight (greek + house) - (greek * house)]
  
  if name = "ch"
  [set sum-link-weight (club + house) - (club * house)]
  
  if name = "sgc"
  [set sum-link-weight (sport + greek + club) - (sport * greek) - (sport * club) - (greek * club) + (sport * greek * club)]
  
  if name = "sgh"
  [set sum-link-weight (sport + greek + house) - (sport * greek) - (sport * house) - (greek * house) + (sport * greek * house)]
  
  if name = "sch"
  [set sum-link-weight (sport + club + house) - (sport * club) - (sport * house) - (club * house) + (sport * club * house)]
  
  if name = "gch"
  [set sum-link-weight (greek + club + house) - (greek * club) - (greek * house) - (club * house) + (greek * club * house)]
  
  if name = "sgch"
  [set sum-link-weight (sport + greek + club + house) - (sport * greek) - (sport * club) - (sport * house) - (greek * club) - (greek * house) - (club * house) + (sport * greek * club) + (sport * greek * house) + (sport * club * house) + (greek * club * house) - (sport * greek * club * house)]

  report sum-link-weight
end
 
to-report count-links [a b]             ;;counts the links between a and b
  set links-between 0

  if [sport-sg] of a = [sport-sg] of b
      [ set links-between links-between + 1 ]

  if [greek-sg] of a = [greek-sg] of b
     [ set links-between links-between + 1 ]

  if [club-sg] of a = [club-sg] of b
     [ set links-between links-between + 1 ]

  if [house-sg] of a = [house-sg] of b
     [ set links-between links-between + 1 ]

  report links-between
end


to-report calculate-juiciness [a b c]
  if (c <= (b + a)) and (c >= (b - a))
      [set juiciness juiciness + 0.5]

  report juiciness
end


to-report take-credibility [a b]                               ;;reports credibility of a to b
  set credibility ([truthfulness] of a) * (sum-links2 a b)
  report credibility
end


to-report calculate-meme-sharing [a]
  set sharing-probability (a ^ 2) / ((.25) + (a ^ 2)) ;print sharing-probability
  report sharing-probability
end


to-report calculate-meme-distortion [a b c d]
  set distortion-probability exp ((-1) * (a + b + c + d)) ;print distortion-probability
  report distortion-probability
end

to-report calculate-sharability[a b c]
  ifelse c = 0
  [set sharability 0]
  [set sharability (a + b) / c] ;print sharability
  report sharability
end

to-report calculate-average-fitness
  let i 0
  let total 0
  let avg 0
  while [i < 20]
  [set total total + item i codon-fitness-list
    set i i + 1]
  set avg total / 20
  report avg 
end

to-report average-meme-fitness [a]
  let i 1
  let j item a meme-length-list
  let k 0
  let f 0
  let prev-meme-lengths 0
  set meme-fitness 0

  while [f < a] ; calculate length of previous memes
  [
    set prev-meme-lengths prev-meme-lengths + item f meme-length-list
    set f f + 1
  ]
  set k prev-meme-lengths

  while [i <= j] ; while i <= length of meme a
  [
    let d item k codon-fitness-list ; d is the fitness of codon k
    set meme-fitness meme-fitness + d
    set i i + 1
    set k k + 1
  ]
  set meme-fitness meme-fitness / j
  report meme-fitness
end

to-report average-meme-distortion [a b]
  let i 1 ;iterates through the length of meme a
  let j item a meme-length-list ;length of meme a
  let k 0 ;which codon in meme a
  let f 0 ;length of each previous meme
  let g 0 ;number of zeroes in meme a
  let prev-meme-lengths 0
  let distortion 0

  while [f < a] ; calculate length of previous memes
  [
    set prev-meme-lengths prev-meme-lengths + item f meme-length-list
    set f f + 1
  ]
  set k prev-meme-lengths

  while [i <= j] ; while i <= length of meme a, find total value of a's codons
  [
    let d item k [rumor] of turtle b ; d is the value of codon k
    set distortion distortion + d
    set i i + 1
    set k k + 1
  ]
  set distortion distortion / j
  report distortion
end

to-report calculate-average-links
  let total-links 0
  let i 0
  while [i < number-of-students]
    [
  ask turtle i[
  let person-total 0

  let s sport-sg
  if s != 0 
  [set sport-count count turtles with [sport-sg = s] - 1] 

  let g greek-sg
  if g != 0
  [set greek-count count turtles with [greek-sg = g] - 1] 

  let h house-sg
  if h != 0
  [set house-count count turtles with [house-sg = h] - 1] 

  let c club-sg
  if c != 0
  [set club-count count turtles with [club-sg = c] - 1] 
  
  set person-total sport-count + greek-count + house-count + club-count
  set total-links total-links + person-total
  ]
  set i i + 1
    ]
    
  report total-links / number-of-students
end

to-report calculate-mutation-measure
  let total-who-know array:from-list n-values (rumor-length)  [0] ; initialize array to all zeros
  let total-with-1 array:from-list n-values (rumor-length) [0] ; initialize # of agents who have a 1 for codons
  let total-with-2 array:from-list n-values (rumor-length) [0]
  let total-with-3 array:from-list n-values (rumor-length) [0]
  let total-with-4 array:from-list n-values (rumor-length) [0]
  let total-with-5 array:from-list n-values (rumor-length) [0]

  ask turtles with [infected? = true]
  [ let i 0
    let a self
    while [i < rumor-length]
    [
      if item i [rumor] of a >= 1 [ array:set total-who-know i ((array:item total-who-know i) + 1) ]

      if item i [rumor] of a = 1  [ array:set total-with-1 i ((array:item total-with-1 i) + 1) ]
      if item i [rumor] of a = 2  [ array:set total-with-2 i ((array:item total-with-2 i) + 1) ]
      if item i [rumor] of a = 3  [ array:set total-with-3 i ((array:item total-with-3 i) + 1) ]
      if item i [rumor] of a = 4  [ array:set total-with-4 i ((array:item total-with-4 i) + 1) ]
      if item i [rumor] of a = 5  [ array:set total-with-5 i ((array:item total-with-5 i) + 1) ]

      set i i + 1
    ]

    ;set mutation-measure ((total-with-one / total-who-know) + 2 * (total-with-two / total-who-know) + 3 * (total-with-three / total-who-know) + 4 * (total-with-four / total-who-know) + 5 * (total-with-five / total-who-know))
  ]

  let i 0
  let mutation-measure array:from-list n-values (rumor-length) [0]
  let proportion-with-1 array:from-list n-values (rumor-length) [0]
  let proportion-with-2 array:from-list n-values (rumor-length) [0]
  let proportion-with-3 array:from-list n-values (rumor-length) [0]
  let proportion-with-4 array:from-list n-values (rumor-length) [0]
  let proportion-with-5 array:from-list n-values (rumor-length) [0]

  while [ i < rumor-length]
  [ array:set proportion-with-1 i (array:item total-with-1 i) / (array:item total-who-know i)
    array:set proportion-with-2 i (array:item total-with-2 i) / (array:item total-who-know i)
    array:set proportion-with-3 i (array:item total-with-3 i) / (array:item total-who-know i)
    array:set proportion-with-4 i (array:item total-with-4 i) / (array:item total-who-know i)
    array:set proportion-with-5 i (array:item total-with-5 i) / (array:item total-who-know i)


    array:set mutation-measure i (array:item proportion-with-1 i) + (array:item proportion-with-2 i) * 2 + (array:item proportion-with-3 i) * 3 + (array:item proportion-with-4 i) * 4 + (array:item proportion-with-5 i) * 5
    array:set mutation-measure i (round ((array:item mutation-measure i) * 100)) / 100
    set i (i + 1)
  ]

  report mutation-measure
end

to print-mutation-measure
  let mm calculate-mutation-measure
  let filename "Rumor Mutation Measure.csv"

  if ticks = 0 [ if file-exists? filename [file-delete filename] ]

  file-open filename

    let i 0
    while [ i < rumor-length]
    [ file-write array:item mm i
      file-type (word ",")
      set i (i + 1)
    ]

    file-print ticks
    file-close
end

to print-meme-length-list
  let filename "Meme Length List.csv"

  if file-exists? filename [file-delete filename]

  file-open filename

  let i 0
  while [i < num-memes]
  [ file-print (word (item i meme-length-list) "," (item i meme-relevance-list) "," (item i codon-fitness-list))
    set i (i + 1)
  ]

  file-close

end

to print-meme-relevance
  let filename "Meme Relevance.csv"

  if ticks = 0 [ if file-exists? filename [file-delete filename] ]

  file-open filename

  let i 0
    while [ i < num-memes]
    [ file-write item i meme-relevance-list
      file-type (word ",")
      set i (i + 1)
    ]

  file-close
end

to print-meme-lengths
  let filename "Meme Lengths.csv"

  if ticks = 0 [ if file-exists? filename [file-delete filename] ]

  file-open filename

  let i 0
    while [ i < num-memes]
    [ file-write item i meme-length-list
      file-type (word ",")
      set i (i + 1)
    ]

  file-close
end

to print-results
  let mm calculate-mutation-measure
  let filename "Rumor Results.csv"

  if ticks = 0 [ if file-exists? filename [file-delete filename] ]

  file-open filename

    let i 0
    while [ i < rumor-length]
    [ file-write array:item mm i
      file-type (word ",")
      set i (i + 1)
    ]

    file-write count turtles with [rumor = initial-rumor] * 100 / count turtles with [infected? = true] ;;percent fidelity
    file-type (word ",")
    file-type 100 * count turtles with [infected? = true] / number-of-students  ;;percent infected
    file-type (word ",")
    file-print ticks
    
    file-close
end

to print-percent-infected
  let filename "Percent Infected List.csv"

  if ticks = 0 [ if file-exists? filename [file-delete filename] ]

  file-open filename

  file-write 100 * count turtles with [infected? = true] / number-of-students
  file-type (word ",")
  file-print ticks
  
  file-close
  
end

to print-percent-fidelity
  let filename "Percent Fidelity List.csv"

  if ticks = 0 [ if file-exists? filename [file-delete filename] ]

  file-open filename

  file-write count turtles with [rumor = initial-rumor] * 100 / count turtles with [infected? = true]
  file-type (word ",")
  file-print ticks
  
  file-close
  
end

to print-fitness
  let filename "Rumor Fitness.csv"

  if ticks = 0 [ if file-exists? filename [file-delete filename] ]

  file-open filename

  let i 0
    while [ i < rumor-length]
    [ file-write item i codon-fitness-list
      file-type (word ",")
      set i (i + 1)
    ]

  file-close
end

to save
  nw:set-context turtles links
  nw:save-graphml "Practice.graphml"
end

to load
  clear-all
  nw:load-graphml "Practice.graphml"
  reset-ticks
  
  ask turtles[
    let temp[]                            ;restore rumor and known
    set temp read-from-string rumor
    set rumor[]
    set known array:from-list temp
    set rumor array:to-list known]
  
  file-open "Rumor Fitness.csv"           ;convert codon-fitness-list to list again
  let csv file-read-line
  set csv word csv "," 
  let mylist []  ; list of values 
  while [not empty? csv] 
  [
    let $x position "," csv 
    let $item substring csv 0 $x  ; extract item 
    carefully [set $item read-from-string $item][] ; convert if number 
    set mylist lput $item mylist  ; append to list 
    set csv substring csv ($x + 1) length csv  ; remove item and comma 
  ] 
  let fileList mylist
  set codon-fitness-list fileList
  set codon-fitness-list but-last codon-fitness-list
  file-close
  
  
  file-open "Meme Lengths.csv"           ;convert meme-length-list to list again
  let csv2 file-read-line
  set csv2 word csv2 "," 
  let mylist2 []  ; list of values 
  while [not empty? csv2] 
  [
    let $x position "," csv2 
    let $item substring csv2 0 $x  ; extract item 
    carefully [set $item read-from-string $item][] ; convert if number 
    set mylist2 lput $item mylist2  ; append to list 
    set csv2 substring csv2 ($x + 1) length csv2  ; remove item and comma 
  ] 
  let fileList2 mylist2
  set meme-length-list fileList2
  set meme-length-list but-last meme-length-list
  file-close
  
  set num-memes length meme-length-list
  
  
  file-open "Meme Relevance.csv"           ;convert codon-fitness-list to list again
  let csv3 file-read-line
  set csv3 word csv3 "," 
  let mylist3 []  ; list of values 
  while [not empty? csv3] 
  [
    let $x position "," csv3 
    let $item substring csv3 0 $x  ; extract item 
    carefully [set $item read-from-string $item][] ; convert if number 
    set mylist3 lput $item mylist3  ; append to list 
    set csv3 substring csv3 ($x + 1) length csv3  ; remove item and comma 
  ] 
  let fileList3 mylist3
  set meme-relevance-list fileList3
  set meme-relevance-list but-last meme-relevance-list
  file-close
  
  
  set initial-rumor[]                     ;convert initial rumor back to list
  let x 0                        
      while [x < rumor-length]
        [
          set initial-rumor lput 1 initial-rumor
          set x x + 1
        ]
        
end






;;Brandon Bates and Dr. Erin Bodine
@#$#@#$#@
GRAPHICS-WINDOW
208
10
729
552
18
18
13.811
1
10
1
1
1
0
0
0
1
-18
18
-18
18
0
0
1
ticks
30.0

SLIDER
734
48
906
81
number-of-students
number-of-students
0
2055
2055
1
1
NIL
HORIZONTAL

BUTTON
53
10
134
43
setup
setup\nprint-fitness\nprint-meme-lengths\nprint-meme-relevance
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
52
46
202
79
go
print-meme-length-list\ngo\nif ticks > 10\n[stop]
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
55
84
125
129
# Infected
count turtles with [infected? = true]
17
1
11

SLIDER
734
85
906
118
rumor-length
rumor-length
0
5000
20
10
1
NIL
HORIZONTAL

SLIDER
734
123
906
156
sport-weight
sport-weight
0
1
0.5
.01
1
NIL
HORIZONTAL

SLIDER
734
160
906
193
greek-weight
greek-weight
0
1
0.4
.01
1
NIL
HORIZONTAL

SLIDER
734
197
906
230
club-weight
club-weight
0
1
0.1
.01
1
NIL
HORIZONTAL

SLIDER
734
234
906
267
house-weight
house-weight
0
1
0.5
.01
1
NIL
HORIZONTAL

SLIDER
734
11
906
44
num-start-pop
num-start-pop
0
10
5
1
1
NIL
HORIZONTAL

MONITOR
129
84
206
129
% Infected
100 * count turtles with [infected? = true] / number-of-students
2
1
11

BUTTON
136
10
202
43
one step
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

MONITOR
55
133
126
178
% Fidelity
count turtles with [rumor = initial-rumor] * 100 / count turtles with [infected? = true]
2
1
11

SLIDER
733
271
905
304
sport-groups
sport-groups
0
100
21
1
1
NIL
HORIZONTAL

SLIDER
734
308
906
341
greek-groups
greek-groups
0
100
10
1
1
NIL
HORIZONTAL

SLIDER
734
345
906
378
club-groups
club-groups
0
100
70
1
1
NIL
HORIZONTAL

SLIDER
734
382
906
415
house-groups
house-groups
0
100
17
1
1
NIL
HORIZONTAL

MONITOR
131
133
203
178
# Loners
count turtles with [loner? = true]
0
1
11

SLIDER
733
422
905
455
max-meme-length
max-meme-length
1
rumor-length
5
1
1
NIL
HORIZONTAL

SLIDER
734
461
906
494
relevancy-range
relevancy-range
0
1
0.3
0.05
1
NIL
HORIZONTAL

PLOT
982
89
1309
376
Fidelity Plot
Ticks
% Fidelity
0.0
10.0
0.0
100.0
true
false
"plot-pen-reset" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles with [rumor = initial-rumor] * 100 / count turtles with [infected? = true]"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="ave-pop-link-weight vs %inf and %con" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>100 * count turtles with [infected? = true] / number-of-students</metric>
    <metric>count turtles with [rumor = initial-rumor] * 100 / count turtles with [infected? = true]</metric>
    <metric>ave-pop-link-weight</metric>
    <enumeratedValueSet variable="greek-groups">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="club-groups">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="house-groups">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sport-groups">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumor-length">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-students">
      <value value="2055"/>
    </enumeratedValueSet>
    <steppedValueSet variable="sport-weight" first="0.2" step="0.2" last="1"/>
    <steppedValueSet variable="greek-weight" first="0.2" step="0.2" last="1"/>
    <steppedValueSet variable="house-weight" first="0.2" step="0.2" last="1"/>
    <steppedValueSet variable="club-weight" first="0.2" step="0.2" last="1"/>
    <enumeratedValueSet variable="num-start-pop">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Mutuation Measure" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10"/>
    <metric>calculate-mutation-measure</metric>
    <enumeratedValueSet variable="sport-groups">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-meme-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="club-groups">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="greek-groups">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-start-pop">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="club-weight">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rumor-length">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="house-groups">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="house-weight">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-students">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sport-weight">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="greek-weight">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
