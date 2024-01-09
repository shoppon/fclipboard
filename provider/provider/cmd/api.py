import uvicorn

from provider.api import app
from provider.api import category  # noqa
from provider.api import entry  # noqa
from provider.api import subscription  # noqa


def main():
    uvicorn.run(app, host="0.0.0.0", port=8000)
