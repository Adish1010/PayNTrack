from flask import Flask,jsonify
from controllers.auth_controller import auth_bp
from dotenv import load_dotenv
from services.extensions import jwt
import os
from database.database import db

load_dotenv()


SECRET_KEY = os.getenv("SECRET_KEY")
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv("DATABASE_URL")
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY')

db.init_app(app)
jwt.init_app(app)

app.register_blueprint(auth_bp, url_prefix='/auth')

with app.app_context():
    db.create_all()

@app.route('/')
def home():
    return jsonify({"message":"PayNTrack Backend!!!"})

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True)
