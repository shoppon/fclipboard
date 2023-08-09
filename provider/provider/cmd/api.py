import uvicorn

from provider.api.subscription import app


def main():
    uvicorn.run(app, host="0.0.0.0", port=8000)
