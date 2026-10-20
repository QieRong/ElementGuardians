"""Map audit must reject overlapping deployment slots, not just road collisions."""
import copy
import unittest

from check_map import build_report, load_map, load_towers


class MapGeometryTests(unittest.TestCase):
    def test_overlapping_slots_are_rejected(self):
        data = copy.deepcopy(load_map())
        data["slots"][0]["center"] = data["slots"][1]["center"][:]
        report = build_report(data, load_towers())
        self.assertTrue(report["problems"], "overlapping slots were accepted")

    def test_approved_map_is_clear(self):
        report = build_report(load_map(), load_towers())
        self.assertEqual(report["problems"], [])


if __name__ == "__main__":
    unittest.main()
