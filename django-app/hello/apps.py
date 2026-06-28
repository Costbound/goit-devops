import os
from django.apps import AppConfig


class HelloConfig(AppConfig):
    name = "hello"

    def ready(self):
        if os.environ.get("RUN_MAIN") == "true":
            return

        from django.db import connection
        from django.db.utils import OperationalError

        try:
            connection.ensure_connection()
            print("Database connected successfully.")
        except OperationalError as e:
            print(f"Database connection failed: {e}")
