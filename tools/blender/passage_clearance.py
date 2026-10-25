"""Small game-port corrections to visible passenger passage clearances.

The pinned Blender masters stay immutable. The exporter and navigation baker
apply the same piecewise rigid translations to evaluated world-space vertices.
Seats, passenger markers, exterior doors, bogies and railway geometry are intact.
"""
REVISION = 1
MODELS = {'lhb_gs', 'lhb_2a', 'lhb_sl', 'vb_dtc'}


def position(model, name, point):
    result = point.copy()
    label = name.lower()
    if model in {'lhb_gs', 'lhb_2a', 'lhb_sl'}:
        # The end seating bay meets the transverse saloon doorway without a
        # turning space. Move that bulkhead 0.40 m into the vestibule, keeping
        # its complete central opening and the full seating arrangement.
        if label.startswith('saloon_') and abs(point.x) > 8.0:
            result.x += .40 if point.x > 0 else -.40
        elif model == 'lhb_gs' and label.startswith('gs_vertical_grab') and abs(point.x) > 8.5:
            # Align the end grab pole with the bench rather than the turn into
            # the vestibule. Its height and distance from the side wall stay.
            result.x -= .35 if point.x > 0 else -.35
    elif model == 'vb_dtc':
        # The rounded accessible compartment's front grazed the saloon doorway.
        # Moving its intact assembly aft makes room to turn around the corner.
        if label.startswith('vb02_int_service_accessible_') or label == 'vb02_int_service_removable_closed_door':
            result.x -= .22
    return result
