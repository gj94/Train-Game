"""Validate and summarize a completed five-train native benchmark JSON."""
import argparse
import json
from pathlib import Path


def summarize(path):
    report = json.loads(path.read_text(encoding='utf-8-sig'))
    assert report['complete'] and not report.get('error'), 'Incomplete benchmark'
    assert not report['quick_validation'], 'Quick runs are not performance evidence'
    fixture = report['traffic_fixture']
    assert fixture['trains'] == 5 and len(fixture['services']) == 5
    assert fixture['vehicles'] == 91 and fixture['passengers'] == 5580
    assert len({s['road'] for s in fixture['services']}) == 5
    cases = {case['view']: case for case in report['cases']}
    rows = []
    for view in ('pilot', 'passenger', 'platform', 'overview'):
        pair = []
        for suffix in ('full', 'culled'):
            case = cases[f'five_trains_{view}_{suffix}']
            traffic = case['traffic']
            assert case['frames'] >= 120 and case['duration_ms'] >= 12000
            assert case['loading_frames'] == 0, f'{view}: loading during measurement'
            assert traffic['resident_trains'] == 5
            assert traffic['simulated_passengers'] == fixture['passengers']
            assert case['captured_pixels'][0] > 0 and case['captured_pixels'][1] > 0
            if suffix == 'culled' and view == 'pilot':
                assert traffic['rendered_seated'] == 0
            if suffix == 'culled' and view == 'passenger':
                assert traffic['rendered_seated'] > 0
            m = case['metrics']
            pair.append(dict(mode=suffix, pixels=case['captured_pixels'], frames=case['frames'],
                             frame_median_ms=m['frame_ms']['median'], frame_p95_ms=m['frame_ms']['p95'],
                             frame_p99_ms=m['frame_ms']['p99'], gpu_median_ms=m['gpu_ms']['median'],
                             primitives=m['primitives']['median'], draws=m['draw_calls']['median'],
                             gpu_bytes=m['gpu_bytes']['median'], traffic=traffic,
                             unfocused_frames=case['unfocused_frames']))
        assert pair[0]['pixels'] == pair[1]['pixels']
        saving = 100 * (1 - pair[1]['frame_median_ms'] / pair[0]['frame_median_ms'])
        rows.append(dict(view=view, comparison=pair, median_frame_time_reduction_percent=saving))
    live = cases['five_trains_live']
    assert live['frames'] >= 120 and live['loading_frames'] == 0
    assert live['traffic']['resident_trains'] == 5
    assert all(distance > 1 for distance in live['traffic']['travelled_metres'].values())
    return dict(adapter=report['adapter'], engine=report['engine']['string'],
                fixture=fixture, cases=rows,
                live=dict(traffic=live['traffic'], frame_ms=live['metrics']['frame_ms'],
                          simulation_ms=live['metrics']['simulation_ms'], train_ms=live['metrics']['train_ms']),
                build_steps=report.get('formation_build_steps', []),
                note='Same-process paused rendering A/B, followed by a separate live five-train coasting phase.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('report', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = summarize(args.report)
    print(result['adapter'], '| 5 trains | 91 vehicles | 5580 passengers')
    for row in result['cases']:
        before, after = row['comparison']
        print(f"{row['view']}: median {before['frame_median_ms']:.2f} -> {after['frame_median_ms']:.2f} ms; "
              f"p95 {before['frame_p95_ms']:.2f} -> {after['frame_p95_ms']:.2f} ms; "
              f"rendered primitives {before['primitives']:,.0f} -> {after['primitives']:,.0f}")
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, indent=2) + '\n')
