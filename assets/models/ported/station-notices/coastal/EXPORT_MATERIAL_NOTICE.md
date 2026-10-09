# Portable GLB material colour correction

Status: checked current exports are available for 53 entries; see the [current portable export list](PORTABLE_EXPORTS.md). All 53 overnight entries have closed native/gallery and portable-colour gates.

Packed Blender scenes and their rendered previews retain the intended appearance. A targeted review found that some original overnight GLB materials omitted explicit fallback base colours, leaving surfaces white. This affected northern, middle and southern export families. Earlier rich-v02 assets were not reassessed by this scan.

Current replacements are explicitly linked. Their independent colour-only gates bind exact source palettes and prove unchanged geometry buffers, transforms, resource references, existing factors, alpha semantics and all other JSON fields. First-release packages can instead contain already-correct RGB exports, with their full station gate. Original published scenes, archives, images, manifests and prior reviews remain preserved. Earlier full-export acceptance did not cover the subsequently identified colour issue.

The restored solid authored base colours approximate procedural Blender appearance. Noise, bump and arbitrary Blender-node effects are not baked. Full materials remain authoritative in the packed scene. Native/galleried source and station-specific geometry checks retain their disclosed limits, without operational, as-built or accessibility certification.

Lossless archives and transport parts guarantee exact recorded export bytes, not equivalence of every Blender shader. Superseded archives remain history; use the explicit current selections above.

[Original material-table evidence snapshot](qa/reports/EXPORT_MATERIAL_SCAN_20261008.json) · [Open models](OPEN_MODELS.md) · [Station status](ROUTE_INDEX.md)
