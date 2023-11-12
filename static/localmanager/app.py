from flask import Flask, render_template, request
import os

app = Flask(__name__)


@app.route('/')
def home():
    return "Test"


if __name__ == "__main__":
    port = int(os.environ.get('PORT', 5000))
    app.run(debug=True, host='0.0.0.0', port=port)