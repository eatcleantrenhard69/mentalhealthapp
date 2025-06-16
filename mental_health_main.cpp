#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <cmath>
#include <stdexcept> // Für std::runtime_error
#include <cstring>   // Für strcpy (zum Kopieren von Strings)

// Externe Bibliothek für JSON
// Du musst sicherstellen, dass 'json.hpp' im selben Verzeichnis liegt
// oder in einem vom Compiler gefundenen Include-Pfad.
#include "json.hpp"

// Makro für den Export von Funktionen aus der dynamischen Bibliothek.
// Ermöglicht es anderen Programmen (wie Python über ctypes), diese Funktionen aufzurufen.
#ifdef _WIN32
#define EXPORT_DLL __declspec(dllexport) // Für Windows DLLs
#else
#define EXPORT_DLL                      // Für Linux/macOS Shared Objects
#endif

// Verwende den nlohmann/json-Namespace, um 'json::' zu vermeiden.
using json = nlohmann::json;
// Verwende den Standard-Namespace, um 'std::' vor Datentypen zu sparen.
using namespace std;

// --- Datenstrukturen und Globale Variablen ---

// Struktur zum Speichern der Details eines Zitats und seines Embeddings.
struct QuoteData {
    string quote;
    string author;
    string book;
    vector<float> embedding;
};

// Eine globale Liste, die alle Zitate und ihre Embeddings im Speicher hält.
// Sie wird nur einmal geladen, um die Performance zu optimieren.
vector<QuoteData> all_quotes;
// Ein Flag, das anzeigt, ob die Zitate bereits in 'all_quotes' geladen wurden.
bool quotes_loaded = false;

// --- Cosine Similarity Funktion ---

// Diese Funktion bleibt unverändert, da sie bereits korrekt implementiert ist.
float cosine_similarity(const vector<float>& a, const vector<float>& b) {
    float dot = 0.0, normA = 0.0, normB = 0.0;
    for (size_t i = 0; i < a.size(); i++) {
        dot += a[i] * b[i];
        normA += a[i] * a[i];
        normB += b[i] * b[i];
    }
    // Kleiner Wert (1e-10) im Nenner, um Division durch Null zu verhindern,
    // falls Vektornormen sehr klein oder Null sind.
    return dot / (sqrt(normA) * sqrt(normB) + 1e-10);
}

// --- Funktionen für die Bibliotheks-Schnittstelle ---

// Funktion, die die Zitate aus einer JSON-Datei lädt.
// Sie wird nur einmal aufgerufen, wenn die Bibliothek das erste Mal verwendet wird.
bool load_quotes_from_json(const char* filename) {
    if (quotes_loaded) {
        return true; // Zitate sind bereits geladen, es ist nichts zu tun.
    }
    try {
        ifstream quotes_file(filename);
        if (!quotes_file.is_open()) {
            // Fehlermeldung, wenn die Datei nicht gefunden oder geöffnet werden kann.
            cerr << "C++: Fehler: Zitatendatei '" << filename << "' konnte nicht geoeffnet werden." << endl;
            return false;
        }
        json quotes_json;
        quotes_file >> quotes_json; // JSON-Daten aus der Datei in das 'quotes_json'-Objekt lesen.

        // Überprüfen, ob das gelesene JSON ein Array ist (wie erwartet).
        if (!quotes_json.is_array()) {
            cerr << "C++: Fehler: Zitatendatei ist kein JSON-Array. Erwartet wurde eine Liste von Zitaten." << endl;
            return false;
        }

        // Iteriere über jedes JSON-Objekt (Zitat) im Array.
        for (const auto& item : quotes_json) {
            QuoteData qd;
            // Greife auf die Zitat-, Autor- und Buchinformationen zu.
            // '.value()' bietet einen Standardwert, falls ein Schlüssel im JSON fehlt, um Abstürze zu vermeiden.
            qd.quote = item.value("quote", "Unbekanntes Zitat");
            qd.author = item.value("author", "Unbekannter Autor");
            qd.book = item.value("book", "Unbekanntes Buch");
            // Hole das Embedding; '.get<vector<float>>()' konvertiert das JSON-Array in einen C++-Vektor.
            qd.embedding = item["embedding"].get<vector<float>>();
            all_quotes.push_back(qd); // Füge das Zitat zur globalen Liste hinzu.
        }
        quotes_loaded = true; // Setze das Flag, dass Zitate nun geladen sind.
        cout << "C++: Erfolgreich " << all_quotes.size() << " Zitate geladen." << endl;
        return true;
    } catch (const exception& e) {
        // Allgemeine Fehlerbehandlung beim Laden oder Parsen der JSON-Datei.
        cerr << "C++: Fehler beim Laden der Zitate: " << e.what() << endl;
        return false;
    }
}

// Die Hauptfunktion, die von Python über ctypes aufgerufen wird.
// 'extern "C"' ist wichtig, damit Python (ctypes) diese Funktion finden kann.
// 'EXPORT_DLL' ist für das korrekte Exportieren der Funktion aus der Bibliothek (DLL/SO).
// Argumente:
//   - user_embedding_arr: Zeiger auf das User-Embedding (ein C-Array von Floats), das von Python kommt.
//   - embedding_dim: Die Größe (Anzahl der Elemente) des User-Embeddings.
//   - quotes_file_path: Der Pfad zur JSON-Datei mit allen Zitat-Embeddings.
// Rückgabetyp:
//   - char*: Ein Zeiger auf einen C-String. Dieser String enthält das gefundene Zitat und seine Metadaten.
//     WICHTIG: Dieser String wird im C++-Code dynamisch alloziiert (`new char[]`) und MUSS später in Python
//     mit der 'free_string'-Funktion freigegeben werden, um Memory Leaks zu verhindern!
extern "C" EXPORT_DLL char* find_best_quote(float* user_embedding_arr, int embedding_dim, const char* quotes_file_path) {
    // Sicherstellen, dass die Zitate in den Speicher geladen sind.
    // 'load_quotes_from_json' wird nur beim ersten Aufruf wirklich laden.
    if (!quotes_loaded) {
        if (!load_quotes_from_json(quotes_file_path)) {
            // Wenn das Laden fehlschlägt, geben wir eine Fehlermeldung zurück.
            char* error_msg = new char[50]; // Genug Platz für die Fehlermeldung
            strcpy(error_msg, "ERROR: C++ Konnte Zitate nicht laden.");
            return error_msg;
        }
    }

    // Prüfen, ob Zitate überhaupt geladen wurden (kann bei leerer Datei passieren).
    if (all_quotes.empty()) {
        char* error_msg = new char[50];
        strcpy(error_msg, "ERROR: C++ Keine Zitate geladen.");
        return error_msg;
    }

    // Das User-Embedding von einem C-Array (Pointer) in einen C++-Vektor konvertieren.
    vector<float> user_embedding(user_embedding_arr, user_embedding_arr + embedding_dim);

    float best_score = -1.0;
    string best_quote_str = "Kein passendes Zitat gefunden."; // Standardmeldung
    string best_author_str = "";
    string best_book_str = "";

    // Schleife durch alle geladenen Zitate, um das beste Match zu finden.
    for (const auto& quote_data : all_quotes) {
        // Sicherstellen, dass die Dimensionen der Embeddings übereinstimmen.
        if (quote_data.embedding.size() != embedding_dim) {
            cerr << "C++: Warnung: Embedding-Dimensionen stimmen nicht ueberein. Ueberspringe Zitat." << endl;
            continue;
        }
        // Berechne die Ähnlichkeit zwischen dem User-Embedding und dem Zitat-Embedding.
        float score = cosine_similarity(user_embedding, quote_data.embedding);
        // Wenn dieser Score besser ist, aktualisiere das beste Zitat.
        if (score > best_score) {
            best_score = score;
            best_quote_str = quote_data.quote;
            best_author_str = quote_data.author;
            best_book_str = quote_data.book;
        }
    }

    // Formatiere das Ergebnis in einem einzigen String.
    string result_str = "✨ Passendstes Zitat:\n";
    result_str += "\"" + best_quote_str + "\"\n";
    result_str += "- " + best_author_str + ", " + best_book_str + "\n";
    result_str += "(Ähnlichkeit: " + to_string(best_score) + ")";

    // Alloziere Speicher für den String, der an Python zurückgegeben wird.
    // +1 für das Nullterminierungszeichen, das das Ende des C-Strings markiert.
    char* c_str_result = new char[result_str.length() + 1];
    // Kopiere den C++-String in den alloziierten C-String-Speicher.
    strcpy(c_str_result, result_str.c_str());

    return c_str_result; // Gib den Zeiger auf den C-String zurück.
}

// Eine Hilfsfunktion, die ebenfalls exportiert wird, um den in C++ alloziierten String-Speicher freizugeben.
// Python MUSS diese Funktion aufrufen, nachdem es den von 'find_best_quote' erhaltenen String verwendet hat.
extern "C" EXPORT_DLL void free_string(char* s) {
    delete[] s; // Gib den Speicher frei.
}