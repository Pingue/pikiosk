
class TestView(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

    def test_home_route(self):
        response = self.app.get('/')
        self.assertEqual(response.status_code, 200)
        # Add more assertions to test the content of the response

    def test_pi_route(self):
        response = self.app.get('/pi')
        self.assertEqual(response.status_code, 200)
        # Add more assertions to test the content of the response

    def test_update_route(self):
        response = self.app.get('/update')
        self.assertEqual(response.status_code, 200)
        # Add more assertions to test the content of the response

    def test_delete_route(self):
        response = self.app.get('/delete')
        self.assertEqual(response.status_code, 200)
        # Add more assertions to test the content of the response

    def test_forget_route(self):
        response = self.app.get('/forget')
        self.assertEqual(response.status_code, 200)
        # Add more assertions to test the content of the response

if __name__ == '__main__':
    unittest.main()
import unittest
from flask import Flask
from view import app
