from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from firebase_admin import auth
import json
from . import firebase_config

db = firebase_config.db

@csrf_exempt
def verify_token(request):
    """ Verify Firebase ID token sent from client """
    id_token = request.headers.get("Authorization")
    if not id_token:
        return None, JsonResponse({"error": "Missing authorization header"}, status=401)
    
    try:
        decoded = auth.verify_id_token(id_token)
        return decoded, None
    except Exception as e:
        return None, JsonResponse({"error": f"Invalid token: {e}"}, status=401)

@csrf_exempt
def add_message(request):
    """ Add document to firebase """
    decoded, error = verify_token(request)
    if error:
        return error
    
    try:
        uid = decoded.get("uid", "unknown")
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=401)
    
    data = json.loads(request.body)
    message = data.get("message")

    doc_ref = db.collection("messages").document()
    doc_ref.set({
        "uid": uid,
        "text": message,
    })
    return JsonResponse({"status": "Message saved", "id": doc_ref.id})

def list_messages(request):
    """List al firebase messages"""
    docs = db.collection("messages").stream()
    messages = []
    for doc in docs:
        data = doc.to_dict()
        if data:
            messages.append({
                    "id": doc.id,
                    "message": data.get("text")
            })
    return JsonResponse(messages, safe=False)
