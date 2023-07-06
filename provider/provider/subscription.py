import argparse
import yaml

import uvicorn
from fastapi import FastAPI

parser = argparse.ArgumentParser()
parser.add_argument("--config", type=str, default="subscription.yaml")
args = parser.parse_args()

app = FastAPI()


@app.get("/subscription")
def get_subscription():
    with open(args.config, encoding='utf-8') as f:
        content = yaml.safe_load(f)
        return content


def main():
    uvicorn.run(app, host="0.0.0.0", port=8000)


if __name__ == "__main__":
    main()
