from django.urls import path
from . import views

urlpatterns = [
    path('add/', views.add_message, name='add_message'),
    path('messages/', views.list_messages, name = 'list_messages'),
]