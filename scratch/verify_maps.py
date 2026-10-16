# Test and verification of new LevelMaps layouts
LEVEL_MAX_X = 9800.0
BOSS_TRIGGER_X = 8800.0

def verify_stage(stage_id, ground_segments, platforms):
    print(f"--- Verifying Stage {stage_id} ---")
    # Check ground segments
    for i in range(len(ground_segments) - 1):
        g1 = ground_segments[i]
        g2 = ground_segments[i + 1]
        g1_end = g1[0] + g1[2]
        g2_start = g2[0]
        gap = g2_start - g1_end
        if gap <= 0:
            print(f"ERROR: Ground overlap between seg {i} and {i+1}: end={g1_end}, start={g2_start}")
        else:
            # Check if pit is jumpable
            is_jumpable = gap <= 160.0
            # Check if any platform is directly above this pit
            platforms_above = []
            for p_idx, p in enumerate(platforms):
                px = p['rect'][0]
                pw = p['rect'][2]
                pend = px + pw
                # Overlaps pit
                if not (pend <= g1_end or px >= g2_start):
                    platforms_above.append(p_idx)
            
            if is_jumpable and len(platforms_above) > 0:
                print(f"WARNING: Pit between {g1_end} and {g2_start} (w={gap:.1f}) is jumpable but has platforms above: {platforms_above}")
            else:
                pass
                # print(f"Pit {i}: {g1_end:.1f} to {g2_start:.1f} (w={gap:.1f}), jumpable={is_jumpable}, plats={len(platforms_above)}")

    # Check last ground segment reaches LEVEL_MAX_X
    last_g = ground_segments[-1]
    last_end = last_g[0] + last_g[2]
    if last_end < LEVEL_MAX_X:
        print(f"ERROR: Last ground segment ends at {last_end}, less than {LEVEL_MAX_X}")
    if last_g[0] > BOSS_TRIGGER_X:
        print(f"ERROR: Last ground segment starts after BOSS_TRIGGER_X ({last_g[0]} > {BOSS_TRIGGER_X})")

    print(f"Stage {stage_id} OK! Total ground segments: {len(ground_segments)}, Platforms: {len(platforms)}")

if __name__ == '__main__':
    print("Verification script ready.")
