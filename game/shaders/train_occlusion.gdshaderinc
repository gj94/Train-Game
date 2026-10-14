// Offline, geometry-derived visibility. White is the safe legacy fallback.
// Apply to ambient/reflected light only: moving sunlight and lamps stay dynamic.
uniform float train_occlusion_strength : hint_range(0.0, 1.0) = 1.0;
uniform vec3 train_fixture_emission = vec3(0.0);
uniform float train_fixture_min_height = -1000.0;
vec3 train_ceiling_emission(float author_height) {
 return train_fixture_emission * step(train_fixture_min_height, author_height);
}
float train_ambient_visibility(vec2 visibility) {
 float contact = mix(0.55, 1.0, visibility.r);
 float enclosure = mix(0.55, 1.0, visibility.g);
 return mix(1.0, contact * enclosure, train_occlusion_strength);
}
