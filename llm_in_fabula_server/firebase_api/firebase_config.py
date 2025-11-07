import os
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore

load_dotenv()

cred_path = os.getenv("FIREBASE_CREDENTIALS")
if not cred_path:
    raise ValueError("Missing FIREBASE_CREDENTIALS enviroment variable")

#Initialize firebase
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()