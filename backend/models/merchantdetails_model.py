from database.database import db
class MerchantDetails(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    merchant_name = db.Column(db.String(150), nullable=False)
    business_name = db.Column(db.String(150), nullable=False)
    business_category = db.Column(db.String(150), nullable=False)
    location = db.Column(db.String,nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=True)
    
    userm = db.relationship('User', foreign_keys=[user_id])
