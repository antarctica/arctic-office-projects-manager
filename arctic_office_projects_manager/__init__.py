import logging

import sentry_sdk

from http import HTTPStatus

from flask import Flask, request, has_request_context, render_template
from flask.logging import default_handler
# noinspection PyPackageRequirements
from jinja2 import PrefixLoader, PackageLoader

from flask_reverse_proxy_fix.middleware import ReverseProxyPrefixFix
from flask_request_id_header.middleware import RequestID
from bas_style_kit_jinja_templates import BskTemplates

from config import config


def create_app(config_name):
    app = Flask(__name__)

    # Config
    app.config.from_object(config[config_name])
    config[config_name].init_app(app)

    # Middleware / Wrappers
    if app.config['APP_ENABLE_PROXY_FIX']:
        ReverseProxyPrefixFix(app)
    if app.config['APP_ENABLE_REQUEST_ID']:
        RequestID(app)
    if app.config['APP_ENABLE_SENTRY']:
        sentry_sdk.init(**app.config['SENTRY_CONFIG'])

    # Logging
    class RequestFormatter(logging.Formatter):
        def format(self, record):
            record.url = 'NA'
            record.request_id = 'NA'

            if has_request_context():
                record.url = request.url
                if app.config['APP_ENABLE_REQUEST_ID']:
                    record.request_id = request.environ.get("HTTP_X_REQUEST_ID")

            return super().format(record)
    formatter = RequestFormatter(
        '[%(asctime)s] [%(levelname)s] [%(request_id)s] [%(url)s] %(module)s: %(message)s'
    )
    default_handler.setFormatter(formatter)
    default_handler.setLevel(app.config['LOGGING_LEVEL'])

    # Templates
    app.jinja_loader = PrefixLoader({
        'app': PackageLoader('arctic_office_projects_manager'),
        'bas_style_kit': PackageLoader('bas_style_kit_jinja_templates'),
    })
    app.config['bsk_templates'] = BskTemplates()
    app.config['bsk_templates'].site_title = 'NERC Arctic Office Projects Manager'
    app.config['bsk_templates'].bsk_site_nav_brand_text = 'NERC Arctic Office Projects Manager'
    app.config['bsk_templates'].site_description = 'Management application for projects in the NERC Arctic Office ' \
                                                   'Projects Database'
    app.config['bsk_templates'].bsk_site_feedback_href = 'mailto:webapps@bas.ac.uk'
    app.config['bsk_templates'].bsk_site_nav_launcher.append({
        'title': 'Arctic Office Website',
        'href': 'https://www.arctic.ac.uk'
    })

    # Routes
    #

    @app.route('/')
    def index():
        # noinspection PyUnresolvedReferences
        return render_template(f"app/views/index.j2")

    @app.route('/meta/health/canary', methods=['get', 'options'])
    def meta_healthcheck_canary():
        """
        Returns whether this service is healthy

        This healthcheck checks the application itself (assumed to be healthy if this method can be executed).

        If healthy a 204 No Content response is returned, if unhealthy a 503 Service Unavailable response is returned.
        This healthcheck is binary and does not return any details to reduce payload size and prevent leaking sensitive
        data.

        Other healthcheck's should be used where more details are required. This healthcheck is intended for use with
        load balancers to give early indication of a service not being available.
        """
        return '', HTTPStatus.NO_CONTENT

    return app
