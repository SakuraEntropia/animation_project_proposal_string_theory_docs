# WIDE SCAN — canonical instructions (read before every batch)

You are given a JSON arg object: `{"works": ["<medium>|<title>|<year>", ...], "batch": N}`.

## Task
For EACH work, emit one compact record. Return a JSON array only.

## Record schema (all fields required)
```json
{"title":"","medium":"","year":0,
 "wbid":0,"fsid":0,"rwid":0,"symd":0,
 "comm":"L","conf":"L","fs":[],"sym":[],"wb":[],"lesson":""}
```
- `wbid` worldbuilding density 0-10 (coherent world beyond the plot)
- `fsid` foreshadowing 0-10 (earlier material recontextualised later)
- `rwid` rewatch/reread value 0-10 (NEW meaning on a second pass)
- `symd` symbolism density 0-10
- `comm` community/theory discussion volume: L | M | H
- `conf` your knowledge of the work: A well | B moderate | C thin
- `lesson` <=25 words, a METHODOLOGICAL lesson for a project about universe-scale
  entropy plus a civilisation with a deliberately broken tech tree

## ALLOWED IDS — exact strings only, never invent

FS (foreshadowing mechanisms):
FS-01 Environmental Foreshadowing | FS-02 Delayed Explanation | FS-03 Misleading Interpretation
FS-04 Naming Foreshadowing | FS-05 Repeated Motif | FS-06 Historical Artifact
FS-07 Biological Foreshadowing | FS-08 Religious Symbol | FS-09 Visual Composition
FS-10 Prop / Object Foreshadowing | FS-11 Dialogue Double-Meaning | FS-12 Numerical / Scale
FS-13 Calendar / Time-Unit | FS-14 Language / Script | FS-15 Architectural
FS-16 Food / Daily-Life | FS-17 Medical / Pathology | FS-18 Cartographic / Map
FS-19 Off-Screen Inference | FS-20 Unreliable Narrator | FS-21 False Document / In-World Text
FS-22 Absence / Negative Space | FS-23 Technological Anachronism | FS-24 Ritual
FS-25 Myth-Embedded Truth | FS-26 Cosmic / Astronomical

SYM (symbolism types):
SYM-ENT Entropy/decay | SYM-TIM Time/irreversibility | SYM-LGT Light | SYM-DRK Darkness
SYM-DSC Descent/depth | SYM-OCN Ocean/fluid | SYM-BDY Body/flesh | SYM-DIS Disease/infection
SYM-EVO Evolution/metamorphosis | SYM-MCH Machine/mechanism | SYM-BIR Birth/gestation
SYM-DTH Death/afterlife | SYM-MEM Memory/forgetting | SYM-LNG Language/writing
SYM-FOD Food/consumption | SYM-ARC Architecture/ruins | SYM-WTR Water/ice | SYM-FIR Fire/heat
SYM-INF Information/signal | SYM-NOI Noise/static | SYM-OBS Observer/measurement
SYM-SLF Self/identity | SYM-CIV Civilization/collective | SYM-REL Religion/ritual
SYM-SAC Sacrifice | SYM-KNW Forbidden knowledge | SYM-LAB Labor/industry
SYM-CTL Control/surveillance | SYM-EXP Empire/colonization | SYM-CLS Class/hierarchy
SYM-TEC Technology-as-value | SYM-PRG Progress-as-ideology | SYM-GRD Garden/cultivation
SYM-SDN Void/nothingness

WB (worldbuilding techniques):
WB-01 Unknown World as Puzzle | WB-02 Wrong World Model | WB-03 Information Delay
WB-04 Environmental Foreshadowing | WB-05 Historical Artifact Layer | WB-06 Civilization Ruins
WB-07 Broken Tech Tree | WB-08 Black-box Technology | WB-09 Accidental Breakthrough
WB-10 Can-Use-not-Can-Explain | WB-11 Brute-force Engineering | WB-12 Daily Life Reveals World
WB-13 Repeated Motif as Structure | WB-14 Naming System as Lore | WB-15 Language as Worldbuilding
WB-16 Medicine as Worldbuilding | WB-17 Ritual as Technology | WB-18 Technology as Ritual
WB-19 Non-Human Cognition | WB-20 Observer-Dependent Reality | WB-21 Nested/Recursive World
WB-22 Document/Archive Frame | WB-23 Oral History Frame | WB-24 Scale Contrast
WB-25 Deep Time | WB-26 Extremophile/Alien Ecology | WB-27 Post-Scarcity Logic
WB-28 Institutional Inertia | WB-29 Religion as Infrastructure | WB-30 Map-as-Narrative
WB-31 Body as World | WB-32 World as Organism | WB-33 Time-Loop/Cyclic History
WB-34 Parallel/Many-Worlds | WB-35 Simulation/Nested Reality | WB-36 Wonder+Dread Coupling
WB-37 Small Person/Grand World | WB-38 Craft/Technical Detail as Truth
WB-39 Cost Structure Made Explicit | WB-40 Mythic Recurrence

## HARD RULES (override everything)
1. Unknown work → still emit the record, `conf:"C"`, zeros and empty arrays.
   A blank record is CORRECT. A fabricated one is a failure.
2. NEVER write a plot summary.
3. Emit exactly one record per work. Skip none.
4. No commentary.

## Persist
After building the array, write it with a shell heredoc to:
`/Users/faputa/Documents/000STRING_THEORY_WORLDSETTING/research/data/batch<N>.json`
Preserve content exactly. Reply `WROTE <bytes>`.
