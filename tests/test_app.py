import unittest

from http import HTTPStatus

from flask import current_app

from tests.base_test import BaseTestCase


@unittest.skip('Skipped until projects API can be mocked')
class AppTestCase(BaseTestCase):
    def test_app_exists(self):
        self.assertFalse(current_app is None)

    def test_app_is_testing(self):
        self.assertTrue(current_app.config['TESTING'])

    def test_route_index(self):
        response = self.client.get(
            '/',
            base_url='http://localhost:9000'
        )
        self.assertEqual(response.status_code, HTTPStatus.OK)

    def test_route_meta_healthcheck_canary_success(self):
        for method in ['get', 'options']:
            with self.subTest(method=method):
                if method == 'get':
                    response = self.client.get(
                        '/meta/health/canary',
                        base_url='http://localhost:9000'
                    )
                elif method == 'options':
                    response = self.client.options(
                        '/meta/health/canary',
                        base_url='http://localhost:9000'
                    )
                else:
                    raise NotImplementedError("HTTP method not supported")

                self.assertEqual(response.status_code, HTTPStatus.NO_CONTENT)
