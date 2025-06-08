from sentence_transformers import SentenceTransformer
import json

# Lade das Modell
model = SentenceTransformer('all-MiniLM-L6-v2')

# Lade Quotes aus Datei
with open("books_dataset.json", "r", encoding="utf-8") as f:
    quotes = json.load(f)

# Füge Embeddings hinzu
for quote in quotes:
    text = quote["quote"]
    quote["embedding"] = model.encode(text).tolist()

# Speichern mit Embeddings
with open("quotes_with_embeddings.json", "w", encoding="utf-8") as f:
    json.dump(quotes, f, ensure_ascii=False, indent=2)

print("✅ Embeddings erfolgreich erstellt und gespeichert!")