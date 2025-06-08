from sentence_transformers import SentenceTransformer
import json

# === Modell laden ===
model = SentenceTransformer('all-MiniLM-L6-v2')

# === User-Input ===
text = input("Was fühlst du gerade? 🤔\n> ")

# === Embedding berechnen ===
embedding = model.encode(text).tolist()

# === In JSON speichern ===
with open("user_embedding.json", "w") as f:
    json.dump({"embedding": embedding}, f)

print("✅ Embedding wurde gespeichert in 'user_embedding.json'")