extends RefCounted
## RDSO MEMU body and inter-car dimensions, metres. See docs/stations.md.
const BODY_LENGTH := 21.337
const INTER_CAR_GAP := .795
const BOGIE_CENTRES := 14.783
const BOGIE_INSET := (BODY_LENGTH - BOGIE_CENTRES) * .5
const AXLE_SPACING := 2.896
const CARS := 8
const LENGTH := CARS * BODY_LENGTH + (CARS - 1) * INTER_CAR_GAP
