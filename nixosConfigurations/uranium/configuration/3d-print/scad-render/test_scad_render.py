import unittest

from scad_render import build_command


def cmd(*args, mesh_scad="/tmp/m.scad"):
    return build_command(list(args), mesh_scad)


class BuildCommandTest(unittest.TestCase):
    def test_defaults(self):
        argv, mesh = cmd("model.scad")
        self.assertIsNone(mesh)
        self.assertEqual(argv, ["openscad", "--render", "-o", "model.png", "--colorscheme=Tomorrow",
                                "--imgsize=1024,1024", "model.scad"])

    def test_preview_suppresses_render(self):
        argv, _ = cmd("--preview", "m.scad", "-o", "x.png")
        self.assertNotIn("--render", argv)
        self.assertEqual(argv[1:3], ["--preview", "-o"])

    def test_camera_shorthand(self):
        for form in (["--camera=30,45"], ["--camera", "30,45"]):
            argv, _ = cmd(*form, "m.scad")
            self.assertIn("--camera=0,0,0,60,0,45,500", argv)
            self.assertIn("--viewall", argv)

    def test_camera_full_passthrough(self):
        argv, _ = cmd("--camera=0,0,0,55,0,25,140", "m.scad")
        self.assertIn("--camera=0,0,0,55,0,25,140", argv)
        self.assertNotIn("--viewall", argv)

    def test_unknown_colorscheme_falls_back(self):
        argv, _ = cmd("--colorscheme=Purple", "m.scad")
        self.assertIn("--colorscheme=Tomorrow", argv)
        argv, _ = cmd("--colorscheme", "Tomorrow Night", "m.scad")
        self.assertIn("--colorscheme=Tomorrow Night", argv)

    def test_defines_pass_through(self):
        argv, _ = cmd("-D", "w=20", "-Dh=3", "m.scad")
        self.assertEqual(argv[-4:], ["-D", "w=20", "-Dh=3", "m.scad"])

    def test_mesh_input_and_stl_output(self):
        argv, mesh = cmd("pot.stl")
        self.assertEqual(mesh, "pot.stl")
        self.assertEqual(argv[-1], "/tmp/m.scad")
        self.assertEqual(argv[3], "pot.png")
        argv, mesh = cmd("m.scad", "-o", "out.stl")
        self.assertIsNone(mesh)
        self.assertEqual(argv, ["openscad", "-o", "out.stl", "m.scad"])

    def test_no_input(self):
        with self.assertRaises(SystemExit):
            cmd("-o", "x.png")


if __name__ == "__main__":
    unittest.main()
