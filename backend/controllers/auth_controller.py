import sys
from database.database import db
from werkzeug.security import generate_password_hash, check_password_hash
from models.user_model import User
from models.merchantdetails_model import MerchantDetails
from models.personaldetails_model import PersonalDetails
from flask import Blueprint, json, request, jsonify
from flask_jwt_extended import create_access_token, create_refresh_token, decode_token, jwt_required, get_jwt_identity,get_jwt
from services.extensions import jwt
auth_bp = Blueprint('auth',__name__)

blacklist = set()

@jwt.token_in_blocklist_loader
def check_if_token_revoked(jwt_header, jwt_payload):
    return jwt_payload['jti'] in blacklist

def hashing(password):
    hashed = generate_password_hash(password)
    return hashed
@auth_bp.route('/signup',methods=['POST'])
def register_user():
    if not request.is_json:
        return jsonify({'error': 'Unsupported Media Type, Content-Type must be application/json'}), 415
    data = request.get_json()
    if not data:
        return jsonify({"error":"No data provided"}),400
    print(data)
    email = data.get('email')
    password = data.get('password')
    mobile_no = data.get('mobile_no')
    usertype = data.get('usertype')
    pin = data.get('pin')
    full_name = data.get('full_name')
    job_title = data.get('job_title')
    
    merchant_name = data.get('merchant_name')
    business_name = data.get('business_name')
    business_category = data.get('business_category')
    location = data.get('location')
    
    
    user = User.query.filter_by(email=email).first()
    if user is not None:
        return jsonify({"error":"Email already exists!"}),409
    user = User.query.filter_by(mobile_no=mobile_no).first()
    if user is not None:
        return jsonify({"error":"Mobile number already exists!"}),410
    
    hashed_password = hashing(password)
    hashed_pin = hashing(pin)
    new_user = User(email=email,password=hashed_password,mobile_no=mobile_no,usertype=usertype,pin=hashed_pin)
    
    db.session.add(new_user)
    if usertype=='personal':
        personal_details = PersonalDetails(full_name=full_name,job_title=job_title,user_id = new_user.id)
        db.session.add(personal_details)
        user_name = personal_details.full_name
    else:
        merchant_details = MerchantDetails(merchant_name=merchant_name,business_name=business_name,business_category=business_category,location=location,user_id=new_user.id)
        db.session.add(merchant_details)
        user_name = merchant_details.merchant_name
    db.session.commit() 
    access_token = create_access_token(identity=mobile_no)
    refresh_token = create_refresh_token(identity=mobile_no)
    return jsonify({"access_token":access_token,"refresh_token":refresh_token,"user_id":new_user.id,"user_name":user_name}),201

@auth_bp.route('/login',methods=['POST'])    
def login_user():
    data = request.get_json()
    if not data:
        return jsonify({"error":"No data provided"}),400
    
    mobile_no= data.get('mobile_no')
    password = data.get('password')

    user = User.query.filter_by(mobile_no=mobile_no).first()
    
    if user is None:
        return jsonify({"error":"User not registered,Please sign up!"}),404
    if user.usertype == 'personal':
        personal = PersonalDetails.query.filter_by(id=user.id).first()
        user_name = personal.full_name
    else:
        merchant = MerchantDetails.query.filter_by(id=user.id).first()
        user_name = merchant.merchant_name
    
    stored_password = user.password
    if check_password_hash(stored_password,password):
        access_token = create_access_token(identity=mobile_no)
        refresh_token = create_refresh_token(identity=mobile_no)
        return jsonify({"access_token":access_token,"refresh_token":refresh_token,"user_id":user.id,"user_name":user_name}),201
    return jsonify({"error":"Invalid Password"}),401
    
@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh_token():
    current_user = get_jwt_identity()
    new_access_token = create_access_token(identity=current_user)
    return jsonify({"access_token": new_access_token}), 200
    

@auth_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    user_id = get_jwt_identity()  # Gets the user identity from the JWT token
    user = User.query.filter_by(id=user_id).first()  # Fetch user details from database

    if not user:
        return {"message": "User not found"}, 404

    return {
        "id": user.id,
        "username": user.username,
        "email": user.email
    }, 200


@auth_bp.route('/fetchbalance',methods=['POST'])
@jwt_required()
def fetch_balance():
    raw_data = request.get_data().decode('utf-8')
    print("Raw Request Body:", raw_data)
    sys.stdout.flush()  # Ensures print statements appear immediately
    token = request.headers.get("Authorization").split(" ")[1]
    decoded = decode_token(token)
    print("Decoded JWT:", decoded)
    sys.stdout.flush() 
    data = request.get_json()
    sys.stdout.flush()
    print("Received Data:", json.dumps(data, indent=4))  # Log incoming request
    if not data or 'user_id' not in data:
        return jsonify({'error': 'user_id is required'}), 422
    user_id = data['user_id']
    user = User.query.filter_by(id=user_id).first()
    return {
        "balance":user.balance
    },200

@auth_bp.route('/addmoney',methods=['POST'])
@jwt_required()
def add_money():
    if not request.is_json:
        return jsonify({'error': 'Unsupported Media Type, Content-Type must be application/json'}), 415
    raw_data = request.get_data().decode('utf-8')
    print("Raw Request Body:", raw_data)
    sys.stdout.flush()
    data = request.get_json()
    print("Parsed JSON:", data)
    sys.stdout.flush()
    if not data or 'amount' not in data:
        return jsonify({'error': 'amount is required'}), 422
    try:
    
        data = request.get_json()
        amount = data["amount"]
        user_id = data["user_id"]
        user = User.query.filter_by(id=user_id).first()
        user.balance+=amount
        db.session.commit()
        return jsonify({
            'message': 'Money added successfully',
            'new_balance': user.balance,
            'amount_added': amount
        }), 200
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Internal server error'}), 500

@auth_bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    jti = get_jwt()['jti']  # JWT ID
    blacklist.add(jti)
    return jsonify({'message': 'Successfully logged out.'}), 200
