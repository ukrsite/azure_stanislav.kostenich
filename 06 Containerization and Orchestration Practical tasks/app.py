from flask import Flask
import os

app = Flask(__name__)

@app.route("/")
def home():
    # Read the message from the environment variable
    message = os.getenv("APP_MESSAGE", "Hello, Azure Container Instances!")
    return message

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
