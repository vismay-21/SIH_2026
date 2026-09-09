# PRICING & INCENTIVE MODEL — DOCUMENTATION

## 1. TASK CATALOG (Category, Task, Duration in min, Wage ₹)

**Plumbing — ₹5/min base rate**
Leaking tap repair 20/100 | Pipe leakage fix 30/150 | Ceiling/wall dripping leak 45/225 | Clogged drain unclogging 25/125 | Toilet flush tank repair 30/150 | Toilet clog removal 20/100 | Toilet seat/bowl installation 40/200 | Wash basin install/repair 45/225 | Bathroom fitting install 40/200 | Kitchen sink install/repair 45/225 | Water tank install/cleaning 60/300 | Water motor/pump repair 45/225 | Water heater installation 60/300 | Water heater repair 40/200 | Pipe fitting/replacement 40/200 | Bibcock/valve replacement 20/100 | RO installation 60/300 | RO repair/service 30/150 | Drainage pipe installation 60/300 | Float valve repair 25/125 | Bathroom fixture install 15/75 | Sewage blockage clearing 60/300 | Leakage detection 45/225 | Washing machine pipe fix 20/100 | New pipeline install (full) 180/900 | Full tap/fitting set replacement 90/450

**Carpentry — ₹4.7/min base rate**
Door repair 30/140 | Door installation 90/425 | Window repair/install 60/280 | Cupboard repair 40/190 | Cupboard installation 120/565 | Drawer repair/replace 30/140 | Lock installation/repair 25/120 | Furniture assembly 60/280 | Furniture repair 45/210 | Bed install/repair 90/425 | Shelf installation 30/140 | False ceiling work 180/850 | Wooden partition install 240/1130 | Curtain rod installation 20/95 | Kitchen cabinet install/repair 120/565 | Polishing/varnishing 90/425 | Frame fitting 60/280 | Plywood/laminate work 90/425 | TV unit installation 60/280 | Modular furniture fitting 150/705 | Hinges/handles replacement 20/95 | Termite damage repair 90/425 | Custom furniture fabrication 300/1410 | Wall shelf/rack fitting 30/140

**Electrician — ₹5.3/min base rate**
Fan repair 25/130 | Fan installation 30/160 | Switchboard/socket repair 20/105 | Switchboard/socket install 30/160 | MCB/fuse replacement 20/105 | Wiring troubleshooting 40/210 | New wiring (room) 150/795 | New wiring (full house) 480/2545 | Light fixture installation 20/105 | Light fixture repair 20/105 | Tube/LED fitting 15/80 | Doorbell install/repair 20/105 | Inverter install/repair 45/240 | Stabilizer install/repair 30/160 | AC installation 90/480 | AC repair/servicing 45/240 | AC gas refilling 60/320 | Geyser electrical connection 30/160 | Chimney/exhaust fan install 45/240 | Exhaust fan repair 20/105 | Washing machine connection 20/105 | Refrigerator repair 45/240 | Microwave repair 30/160 | Mixer/grinder repair 25/130 | Water pump electrical repair 30/160 | Extension/wiring extension 20/105 | Earthing install/check 40/210 | Short circuit troubleshooting 45/240 | Intercom/video door phone install 60/320 | CCTV installation (per camera) 45/240 | Smart switch installation 30/160 | Electrical safety inspection 40/210

**Painter — ₹4.2/min base rate**
Wall painting (1 room) 240/1010 | Full house painting 960/4030 | Exterior wall painting 480/2015 | Wall putty application 180/755 | Waterproofing 240/1010 | Texture/design painting 300/1260 | Wood polishing/painting 180/755 | Grille/gate painting 120/505 | Ceiling painting 120/505 | Crack filling & repair 60/250 | Primer application 120/505 | Wallpaper installation 180/755 | Wallpaper removal 90/380 | Stencil/mural painting 240/1010 | Touch-up painting 30/125 | Damp wall treatment 120/505 | Enamel/metal furniture painting 90/380 | POP work 240/1010

**House Help — ₹3.3/min base rate**
Full house deep cleaning 180/595 | Bathroom deep cleaning 45/150 | Kitchen deep cleaning 60/200 | Sofa cleaning 45/150 | Carpet/rug cleaning 45/150 | Mattress cleaning 30/100 | Water tank cleaning 60/200 | Utensil washing 30/100 | Cooking help 90/300 | Laundry & ironing 60/200 | Babysitting (per hr) 60/200 | Elderly care (per hr) 60/200 | Pest control 60/200 | Cockroach/ant treatment 45/150 | Termite treatment 120/400 | Move-in/out cleaning 240/795 | Post-construction cleaning 300/995 | Window/glass cleaning 30/100 | Balcony/terrace cleaning 30/100 | Fridge/microwave interior cleaning 20/65 | Car washing 30/100 | Gardening/plant care 45/150 | Society common area cleaning 90/300 | Daily domestic help (per visit) 120/400

---

## 2. COMPLEXITY NORMALIZATION (per task)

```
complexity = (ln(t) - ln(t_min)) / (ln(t_max) - ln(t_min))
```

Per-category bounds (t_min, t_max in minutes):
- Plumbing: 15, 180
- Carpentry: 20, 300
- Electrician: 15, 480
- Painter: 30, 960
- House Help: 20, 300

Buckets: 0–0.33 Low | 0.34–0.66 Mid | 0.67–1.0 High

---

## 3. EXPERIENCE SCORE (0–1)

Rolling window of last N=50 completed jobs:
```
experience_score = (Σ complexity_i) / N
```

---

## 4. RATING SYSTEM

**Categories (1–5 stars each):**
1. Quality of Work — correctness/durability of task
2. Reliability & Punctuality — on-time, reasonable duration
3. Professionalism & Behavior — polite, no rule-breaking
4. Communication — explained clearly, responsive

**Per-job rating normalization:**
```
avg_rating = (R1+R2+R3+R4) / 4
rating_score = (avg_rating - 1) / 4     // 1★→0, 5★→1
```

**Bayesian aggregation across all reviews (0–1):**
```
bayesian_score = (C×m + Σ rating_score_i) / (C + n)
```
- n = number of reviews for worker
- m = 0.7 (platform-wide prior mean — MVP assumption, adjust once real data exists)
- C = 10 (confidence constant / phantom prior reviews — MVP assumption)

---

## 5. FINAL COMBINED SCORE (0–1)

```
final_score = 0.5 × experience_score + 0.5 × bayesian_score
```

---

## 6. INCENTIVE PREMIUM MAPPING — ⚠️ AMBIGUITY, NOT YET DECIDED

worker_wage = base_task_wage × (1 + final_score × 0.3)

