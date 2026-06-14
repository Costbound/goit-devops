import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = "django-insecure-sa*c@!96k_5*i*j)%iyamxmy87$vf-%bge1+@xpmr4c(p#swxj"

DEBUG = True

ALLOWED_HOSTS = os.environ.get("ALLOWED_HOSTS", "localhost").split(",")

INSTALLED_APPS = []

ROOT_URLCONF = "hw4.urls"
