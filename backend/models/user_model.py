from database.database import db
from datetime import datetime
class User(db.Model):
    id = db.Column(db.Integer,primary_key=True)
    email=db.Column(db.String,unique=True,nullable=False)
    password = db.Column(db.String,nullable=False)
    usertype = db.Column(db.Enum('personal', 'business', name='usertype'), nullable=False)
    mobile_no = db.Column(db.String(10),unique=True,nullable=False)
    created_at = db.Column(db.DateTime)
    pin = db.Column(db.String,nullable=False)
    balance = db.Column(db.Float,default=0.0)
    def __repr__(self):
        return f"<User {self.email}>"
