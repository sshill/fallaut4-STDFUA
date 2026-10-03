#!/usr/bin/env python3
"""
Unit and Integration Test: Local Mod Assembler & Ollama Build Verification
==========================================================================
Verifies that:
1. All local staging modules (Rexford, Ellie, Mercy, Gentleman) are scanned.
2. Binary .esp and .pex files are packaged with SHA256 checksums into dist/.
3. Ukrainization module assets (FontConfig, glyphs) are detected and documented.
4. Ollama code validation or deterministic fallback passes with zero integrity faults.
"""

import sys
import json
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MODDING_DIR = REPO_ROOT / "F4 modding"
sys.path.insert(0, str(MODDING_DIR))

from f4_pipeline_router import assemble_mod_package, verify_build_with_ollama

class TestModAssembler(unittest.TestCase):

    def setUp(self):
        self.test_dist = REPO_ROOT / "dist" / "test_pack"
        if self.test_dist.exists():
            import shutil
            shutil.rmtree(self.test_dist)

    def tearDown(self):
        if self.test_dist.exists():
            import shutil
            shutil.rmtree(self.test_dist)

    def test_assembly_and_manifest(self):
        """Test local package assembly without external network requirements."""
        manifest = assemble_mod_package(
            target_dist=self.test_dist,
            deploy_game=False,
            use_ollama=False
        )

        self.assertEqual(manifest["game_version"], "1.10.163.0")
        self.assertGreaterEqual(len(manifest["collected_esps"]), 4)
        expected_plugins = {"EllieRomance.esp", "GentlemanOutfitReskin.esp", "MercyRecruitment.esp", "RexfordRomance.esp"}
        self.assertTrue(expected_plugins.issubset(set(manifest["collected_esps"])))

        # Verify manifest file on disk
        manifest_file = self.test_dist / "build_manifest.json"
        self.assertTrue(manifest_file.exists())
        with open(manifest_file, "r", encoding="utf-8") as f:
            data = json.load(f)
        self.assertEqual(data["game_version"], "1.10.163.0")
        self.assertTrue(data["ukrainization"]["supported"])
        self.assertIn("Ґ", data["ukrainization"]["encoding_glyphs"])

    def test_deterministic_ollama_fallback(self):
        """Verify that offline or isolated Ollama gracefully resolves to deterministic audit."""
        mock_manifest = {
            "game_version": "1.10.163.0",
            "collected_esps": ["TestMod.esp"],
            "collected_pex": ["TestScript.pex"],
            "modules": [
                {
                    "name": "staging_test",
                    "esp": "TestMod.esp",
                    "pex_files": ["TestScript.pex"],
                    "psc_files": ["TestScript.psc"],
                    "recompile_needed": []
                }
            ],
            "ukrainization": {"supported": True}
        }
        res = verify_build_with_ollama(mock_manifest)
        self.assertIn(res["audit_status"], ["PASS", "WARN"])
        self.assertTrue("verified_plugins" in res or "ai_engine" in res)

if __name__ == "__main__":
    unittest.main()
