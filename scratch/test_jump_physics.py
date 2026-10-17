"""
Verification and design script for Contra Re situational platforms across all 8 stages.
"""

def test_jump_physics():
    speed = 180.0
    jump_v = -450.0
    gravity = 950.0
    t_peak = -jump_v / gravity
    max_h = (jump_v ** 2) / (2 * gravity)
    t_flight = 2 * t_peak
    max_dist = speed * t_flight
    print(f"Jump physics: peak_h={max_h:.1f}px, airtime={t_flight:.2f}s, max_h_dist={max_dist:.1f}px")

test_jump_physics()
