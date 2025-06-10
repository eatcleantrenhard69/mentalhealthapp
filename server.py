
# Python-Server mit FastAPI
# -> starte mit: uvicorn embedding_server:app --reload

from fastapi import FastAPI, Request
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
import uvicorn

app = FastAPI()
model = SentenceTransformer("all-MiniLM-L6-v2")

class TextInput(BaseModel):
    text: str

@app.post("/embed")
async def embed_text(input: TextInput):
    embedding = model.encode(input.text).tolist()
    return {"embedding": embedding}

# Starte mit:
# uvicorn embedding_server:app --reload  


