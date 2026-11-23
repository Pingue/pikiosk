import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import netifaces

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import localmanager  # noqa: E402


class TestLocalManager(unittest.TestCase):

    def setUp(self):
        # The app reads/writes ./manager and ./cacheddetails relative to the cwd.
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        cwd = os.getcwd()
        os.chdir(self._tmp.name)
        self.addCleanup(os.chdir, cwd)

        patches = [
            mock.patch.object(netifaces, "gateways",
                              return_value={"default": {netifaces.AF_INET: ("10.0.0.1", "eth0")}}),
            mock.patch.object(netifaces, "ifaddresses",
                              return_value={netifaces.AF_LINK: [{"addr": "aa:bb:cc:dd:ee:ff"}]}),
            mock.patch.object(localmanager, "get_current_git_tag", return_value="v0.0.0"),
            mock.patch.object(localmanager.subprocess, "call", return_value=0),
        ]
        self.mocks = [p.start() for p in patches]
        for p in patches:
            self.addCleanup(p.stop)

        localmanager.app.testing = True
        self.client = localmanager.app.test_client()

    def test_home_without_cached_details(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("aa:bb:cc:dd:ee:ff", response.get_data(as_text=True))

    def test_save_writes_config_and_home_shows_it(self):
        response = self.client.get(
            "/save?manager=http://mgr&url=http://site&name=lobby&rotation=90&zoom=1")
        self.assertEqual(response.status_code, 302)
        self.assertEqual(Path("manager").read_text(), "http://mgr")
        page = self.client.get("/").get_data(as_text=True)
        self.assertIn("lobby", page)

    def test_reload_restarts_service(self):
        self.assertEqual(self.client.get("/reload").status_code, 302)
        localmanager.subprocess.call.assert_called_once_with(
            ["systemctl", "restart", "--user", "pikiosk.service"])

    def test_shutdown_powers_off(self):
        self.assertEqual(self.client.get("/shutdown").status_code, 302)
        localmanager.subprocess.call.assert_called_once_with(["poweroff"])


if __name__ == "__main__":
    unittest.main()
