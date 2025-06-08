#include <iostream>
#include <fstream>
#include <vector>
#include <cmath>
#include "json.hpp"

using json = nlohmann::json;
using namespace std;

// Cosine Similarity Funktion
float cosine_similarity(const vector<float>& a, const vector<float>& b) {
    float dot = 0.0, normA = 0.0, normB = 0.0;
    for (size_t i = 0; i < a.size(); i++) {
        dot += a[i] * b[i];
        normA += a[i] * a[i];
        normB += b[i] * b[i];
    }
    return dot / (sqrt(normA) * sqrt(normB) + 1e-10); // +1e-10 gegen Division durch 0
}

int main() {
    // 1. User-Embedding laden
    ifstream user_file("user_embedding.json");
    json user_json;
    user_file >> user_json;
    vector<float> user_embedding = user_json["embedding"];

    // 2. Quotes mit Embeddings laden
    ifstream quotes_file("quotes_with_embeddings.json");
    json quotes_json;
    quotes_file >> quotes_json;

    // 3. Bestes Zitat finden
    float best_score = -1.0;
    json best_quote;

    for (const auto& quote : quotes_json) {
        vector<float> quote_embedding = quote["embedding"];
        float score = cosine_similarity(user_embedding, quote_embedding);
        if (score > best_score) {
            best_score = score;
            best_quote = quote;
        }
    }

    // 4. Ausgabe
    cout << "\n✨ Passendstes Zitat:\n";
    cout << "\"" << best_quote["quote"] << "\"\n";
    cout << "- " << best_quote["author"] << ", " << best_quote["book"] << "\n";
    cout << "(Score: " << best_score << ")" << endl;

    return 0;
}
