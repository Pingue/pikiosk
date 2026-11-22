import importlib.util
import os
import sys
import tempfile
import unittest
from pathlib import Path

# The module name contains a hyphen, so it can't be imported normally.
_APP_PATH = Path(__file__).resolve().parent.parent / "pikiosk-central.py"


def _load_app(db_path):
    os.environ["DB_PATH"] = db_path
    spec = importlib.util.spec_from_file_location("pikiosk_central", _APP_PATH)
    module = importlib.util.module_from_spec(spec)
    # Register the module so Flask resolves templates/static relative to this
    # file rather than the current working directory.
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module.app


class TestView(unittest.TestCase):

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        app = _load_app(os.path.join(self._tmp.name, "db.sqlite3"))
        app.testing = True
        self.client = app.test_client()

    def test_home_route(self):
        self.assertEqual(self.client.get('/').status_code, 200)

    def test_checkin_requires_mac(self):
        self.assertEqual(self.client.get('/checkin').status_code, 400)

    def test_checkin_unknown_mac(self):
        response = self.client.get('/checkin?mac=aa:bb:cc:dd:ee:ff')
        self.assertEqual(response.status_code, 400)

    def test_pi_registers_unconfigured_device(self):
        response = self.client.get('/pi?mac=aa:bb:cc:dd:ee:ff&ip=10.0.0.2')
        self.assertIn("No configuration", response.get_data(as_text=True))

    def test_update_then_pi_returns_config(self):
        self.client.get('/update?mac=aa:bb:cc:dd:ee:ff&name=lobby'
                        '&url=http://example.com&rotation=0&zoom=1')
        data = self.client.get('/pi?mac=aa:bb:cc:dd:ee:ff').get_json()
        self.assertEqual(data["name"], "lobby")
        self.assertEqual(data["status"], 0)

    def test_delete_unknown_mac(self):
        self.assertEqual(self.client.get('/delete?mac=nope').status_code, 404)

    def test_forget_unknown_mac(self):
        self.assertEqual(self.client.get('/forget?mac=nope').status_code, 404)

    def test_forget_removes_device(self):
        self.client.get('/update?mac=aa:bb:cc:dd:ee:ff&name=x&url=http://e.com'
                        '&rotation=0&zoom=1')
        self.assertEqual(self.client.get('/forget?mac=aa:bb:cc:dd:ee:ff').status_code, 200)
        self.assertEqual(self.client.get('/forget?mac=aa:bb:cc:dd:ee:ff').status_code, 404)


if __name__ == '__main__':
    unittest.main()
