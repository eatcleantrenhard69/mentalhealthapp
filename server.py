from fastapi import FastAPI, Request, HTTPException
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
import uvicorn
import ctypes
import os
import json # Nützlich für detailliertere Fehlerbehandlung oder zukünftige JSON-Verarbeitung
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI(
    title="Zitatfinder API",
    description="Ein API-Service zum Finden passender Zitate basierend auf Text-Embeddings und einer C++-Suchbibliothek."
)

# --- CORS Konfiguration ---
origins = [
   "*" #umbedingt beim launchen ändern
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True, # Allows cookies, authorization headers, etc.
    allow_methods=["*"],    # Allows all standard methods (GET, POST, PUT, DELETE, OPTIONS)
    allow_headers=["*"],    # Allows all headers
)

# --- SentenceTransformer Modell laden ---
# Das Modell wird einmal beim Start des Servers geladen. Das kann einen Moment dauern.
# Fehler beim Laden sollten hier abgefangen werden, um den Serverstart nicht zu verhindern.
try:
    # Lade das Modell von Hugging Face. Erfordert Internetzugang beim ersten Laden.
    model = SentenceTransformer("all-MiniLM-L6-v2")
    print("Python: SentenceTransformer Modell erfolgreich geladen.")
except Exception as e:
    print(f"Python: FEHLER beim Laden des SentenceTransformer-Modells: {e}")
    model = None # Setze Modell auf None, um spätere Aufrufe abzufangen

# --- C++-Bibliothek laden und ctypes-Schnittstelle konfigurieren ---
# Ermittle den korrekten Bibliotheksnamen basierend auf dem Betriebssystem
library_name = "mental_health_main.dll" if os.name == "nt" else "mental_health_main.dll"
# Erstelle absolute Pfade, um Probleme mit dem Arbeitsverzeichnis zu vermeiden
# Die Bibliothek und quotes_with_embeddings.json sollten im selben Verzeichnis wie dieses Skript sein.
LIBRARY_PATH = os.path.join(os.path.dirname(__file__), library_name)
QUOTES_JSON_PATH = os.path.join(os.path.dirname(__file__), "quotes_with_embeddings.json")

# Überprüfe, ob die C++-Bibliothek existiert, bevor wir versuchen, sie zu laden
if not os.path.exists(LIBRARY_PATH):
    raise RuntimeError(f"Python: FEHLER: C++-Bibliothek nicht gefunden unter: {LIBRARY_PATH}")

# Lade die C++-Bibliothek und konfiguriere die Funktionen für ctypes
quote_matcher_lib = None # Initialisiere als None, falls das Laden fehlschlägt
try:
    print(f"Versuche, DLL zu laden von: {LIBRARY_PATH}")
    # Laden der dynamischen C++-Bibliothek
    quote_matcher_lib = ctypes.CDLL(LIBRARY_PATH)

    # Konfiguration der `find_best_quote`-Funktion für ctypes:
    # argtypes: Die Typen der Argumente, die an die C++-Funktion übergeben werden.
    # restype: Der Rückgabetyp der C++-Funktion.
    quote_matcher_lib.find_best_quote.argtypes = [
        ctypes.POINTER(ctypes.c_float), # user_embedding_arr (Pointer auf ein C-Array von floats)
        ctypes.c_int,                   # embedding_dim (Integer)
        ctypes.c_char_p                 # quotes_file_path (C-String/Bytes)
    ]
    quote_matcher_lib.find_best_quote.restype = ctypes.POINTER(ctypes.c_char) # Rückgabe ist ein Zeiger auf einen C-String

    # Konfiguration der `free_string`-Funktion:
    # Diese Funktion ist ESSENZIELL, um den in C++ alloziierten Speicher freizugeben.
    quote_matcher_lib.free_string.argtypes = [ctypes.POINTER(ctypes.c_char)] # Nimmt einen Zeiger auf einen C-String
    quote_matcher_lib.free_string.restype = None # Gibt nichts zurück

    print("Python: C++-Bibliothek erfolgreich geladen und Funktionen konfiguriert.")
except Exception as e:
    print(f"Python: FEHLER beim Laden oder Initialisieren der C++-Bibliothek: {e}")
    quote_matcher_lib = None # Falls ein Fehler auftritt, wird quote_matcher_lib auf None gesetzt

# Pydantic-Modell für die eingehenden Anfragen von Flutter
class TextInput(BaseModel):
    text: str

# --- FastAPI Endpunkt ---
# Dieser Endpunkt empfängt Text vom Flutter-Client und gibt das beste Zitat zurück.
@app.post("/get_quote")
async def get_quote_from_text(input_data: TextInput):
    # Überprüfe, ob das ML-Modell geladen werden konnte
    if model is None:
        raise HTTPException(status_code=500, detail="SentenceTransformer Modell konnte nicht geladen werden.")
    # Überprüfe, ob die C++-Bibliothek geladen werden konnte
    if quote_matcher_lib is None:
        raise HTTPException(status_code=500, detail="C++ Bibliothek konnte nicht geladen werden.")

    try:
        # 1. Text-Embedding generieren (Python-Teil)
        # model.encode gibt ein NumPy-Array zurück, .tolist() wandelt es in eine Python-Liste von Floats um.
        embedding_list = model.encode(input_data.text).tolist()

        # 2. Embedding für C++ vorbereiten (ctypes-Kompatibilität)
        embedding_dim = len(embedding_list)
        # Erstelle ein C-kompatibles Array von `c_float` aus der Python-Liste.
        # (*embedding_list) entpackt die Liste in einzelne Argumente für den Array-Konstruktor.
        c_float_array = (ctypes.c_float * embedding_dim)(*embedding_list)

        # 3. C++-Funktion zur Zitatensuche aufrufen
        # Übergabe des C-Arrays, der Dimension und des Pfades zur Zitat-JSON-Datei.
        # Der Pfad muss als `bytes` übergeben werden (`.encode('utf-8')`).
        result_ptr = quote_matcher_lib.find_best_quote(
            c_float_array,
            embedding_dim,
            QUOTES_JSON_PATH.encode('utf-8')
        )

        # 4. Ergebnis von C++ in Python-String konvertieren
        # ctypes.cast wandelt den Zeiger in einen `c_char_p` (C-String-Zeiger).
        # .value holt die Bytes, .decode('utf-8') konvertiert Bytes in einen Python-String.
        result_str = ctypes.cast(result_ptr, ctypes.c_char_p).value.decode('utf-8')

        # 5. WICHTIG: Speicher in C++ freigeben, um Memory Leaks zu verhindern!
        quote_matcher_lib.free_string(result_ptr)

        # 6. Fehlerbehandlung für C++-Fehlermeldungen
        if result_str.startswith("ERROR:"):
            # Wenn C++ einen Fehler zurückgibt (beginnend mit "ERROR:"),
            # werfen wir eine HTTP-Fehlermeldung.
            raise HTTPException(status_code=500, detail=result_str)

        # 7. Erfolgreiche Antwort an den Flutter-Client senden
        # Das formatierte Zitat und seine Metadaten werden im 'quote_info'-Feld zurückgegeben.
        return {"quote_info": result_str}

    except HTTPException:
        # Leite HTTPException (von obiger Fehlerbehandlung) einfach weiter
        raise
    except Exception as e:
        # Fange alle anderen unerwarteten Fehler ab und logge sie
        print(f"Python: Unerwarteter Fehler bei der Zitatabfrage: {e}")
        # Gib eine generische Fehlermeldung an den Client zurück
        raise HTTPException(status_code=500, detail=f"Interner Serverfehler: {e}")

# Optional: Ein separater Endpunkt nur zum Generieren von Embeddings
# Kann nützlich sein für Debugging oder wenn du Embeddings separat benötigst.
@app.post("/embed")
async def embed_text(input_data: TextInput):
    if model is None:
        raise HTTPException(status_code=500, detail="SentenceTransformer Modell konnte nicht geladen werden.")
    try:
        embedding = model.encode(input_data.text).tolist()
        return {"embedding": embedding}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fehler beim Generieren des Embeddings: {e}")

# uvicorn server:app --host 0.0.0.0 --port 8000 --reload
#erst server starten dann funktioniert es erst.