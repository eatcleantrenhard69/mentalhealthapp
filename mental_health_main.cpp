#include <windows.h>
#include <iostream>
#include <string>
#include <fstream>
#include "json.hpp" // Stelle sicher, dass du nlohmann::json verwendest
#include <fstream>
#include <cstdio>
#include <cstdlib>
#include <stdexcept> // For std::stoi exceptions
#include <limits>    // For std::numeric_limits (for std::cin.ignore)
#include <algorithm> // For trimming (using find_first/last_not_of)
#include <vector>    // To ensure books is treated as a vector (JSON array)
#include <cctype>
#include <unordered_map>
#include <limits.h>
using json = nlohmann::json;
//return: string in der richtigen Form 
//param: Eingabe von User 
std::string normalizeEmotion(const std::string& userInput);

//return: bool 
//param: user input 
bool isValidEmotion(const std::string& word);

//return: emotion
//param: keine 
std::string dateilesen();
//return: die Zitate im json format
//param: keine 
nlohmann::json loadBooksDataset();

//return: void 
//param: Userinput und Zitate 
void runLLM(const std::string& userFeeling, json& books);

//return: emotion
//param: emotion und zitate
void showQuoteForEmotion(const std::string& emotion, const json& books);





std::vector<std::string> validEmotions = 
{
"discouraged", "overwhelm", "anxious", "stuck", "restless",
"resentment", "resistance", "confusion", "panic", "negative", "rumination", "regret", 
"overwhelmed", "powerlessness", "self-pity", "anger", "helplessness",
"discontent", "procrastination", "dishonesty", "frustration", "overwhelm", "self-doubt",
"boredom", "turmoil", "grudge", "stagnation",
"fear", "grief", "disorder", "apathy", "impatience", "stubbornness", "envy", "ease",
"greed", "aimlessness", "rigidity", "revenge", "disconnection", "distraction","inaction",
"isolation", "overwhelm", "victimhood", "identity", "stress",
"inner conflict", "anxiety", "resistance", "acceptance", "guilt",
"frustration", "exhaustion", "hopelessness","denial","grief","empathy","self-doubt","longing",
"vulnerability","insecurity","indifference", "betrayal"
};
std::map<std::string, std::string> emotionMappings = {
    {"overwhelmed", "overwhelm"},
    {"resentful", "resentment"},
    {"negativity", "negative"},
    {"self-pity", "victimhood"},
    {"helplessness", "powerlessness"},
    {"powerless", "powerlessness"},
    {"grudge", "resentment"},
    {"panic", "fear"},
    {"turmoil", "inner conflict"},
    {"disorder", "confusion"},
    {"dishonesty", "guilt"},
    {"stuck", "stagnation"},
    {"mad", "anger"},
    {"uncertain", "confusion"},
    {"hopeless", "hopelessness"},
    {"afraid", "fear"},
    {"tired", "exhaustion"},
    {"lazy", "inaction"},
    {"withdrawn", "isolation"},
    {"conflicted", "inner conflict"},
    {"doubtful", "insecurity"},
    {"numb", "apathy"},
    {"negative", "negativity"},  // for unifying forms
    {"overwhelm", "overwhelm"},  // keep consistent
    {"confusion", "confusion"},
    {"frustration", "frustration"},
    {"anger", "anger"},
    {"anxious", "anxiety"},
    {"discouraged", "discouraged"},
    {"grief", "grief"},
    {"guilt", "guilt"},
    {"insecurity", "insecurity"},
    {"bored", "boredom"},
    {"lonely", "isolation"},
    {"ashamed", "guilt"},
    {"restless", "restless"},
    {"longing", "longing"},
    {"hopelessness", "hopelessness"},
    {"denial", "denial"},
    {"victim", "victimhood"},
    {"envy", "envy"},
    {"stress", "stress"},
    {"apathy", "apathy"},
    {"rumination", "rumination"},
    {"resistance", "resistance"},
    {"powerlessness", "powerlessness"},
    {"ease", "ease"},
    {"identity", "identity"},
    {"acceptance", "acceptance"},
    {"indifference", "indifference"},
    {"vulnerability", "vulnerability"},
    {"empathy", "empathy"},
    {"revenge", "revenge"},
    {"rigidity", "rigidity"},
    {"greed", "greed"},
    {"aimlessness", "aimlessness"},
    {"exhaustion", "exhaustion"},
    {"procrastination", "procrastination"},
    {"discontent", "discontent"},
    {"distracted", "distraction"},
    {"inaction", "inaction"},
    {"impatience", "impatience"},
    {"stubbornness", "stubbornness"},
    {"grief", "sad"},
    {"stressed", "stress"}, 
     {"sadness", "sad"},
     {"overwhelmed", "overwhelm"}


};

std::string normalizeEmotion(const std::string& userInput)
{
    auto it = emotionMappings.find(userInput);
    if (it != emotionMappings.end()) {
        return it->second;
    }
    return userInput; // fallback to original if no mapping exists
}
// 🔄 Check function
bool isValidEmotion(const std::string& word) {
    return !normalizeEmotion(word).empty();
}

std::string dateilesen() {
    std::ifstream file("llm_output.txt");
    std::string emotion;
    char ch;

    while (file.get(ch)) {
        if(ch == '<' || ch=='.') break;
        emotion += ch;
    }

    file.close();

    // Optional: trim whitespace
    emotion.erase(0, emotion.find_first_not_of(" \t\n\r"));
    emotion.erase(emotion.find_last_not_of(" \t\n\r") + 1);
    std::transform(emotion.begin(), emotion.end(), emotion.begin(), ::tolower);
    std::string normalized = normalizeEmotion(emotion); 
    if (normalized.empty()) {
        std::cerr << "⚠️ Ungültige Emotion erkannt: '" << emotion << "' — keine passende Antwort verfügbar." << std::endl;
        return "";
    }
    return normalized;
}
nlohmann::json loadBooksDataset() {
    std::ifstream file("books_dataset.json");
    if (!file.is_open()) {
        std::cerr << "Fehler beim Öffnen der books_dataset.json Datei!" << std::endl;
        exit(1);
    }

    nlohmann::json books;
    file >> books;
    return books;
}

void runLLM(const std::string& userFeeling, json& books) {
    using std::ifstream;

    std::string emotionsStr;
    for (const auto& emotion : validEmotions) 
    {
        emotionsStr += emotion + ", ";
    }
// Entferne das letzte ", "
    if (!emotionsStr.empty()) {
    emotionsStr.erase(emotionsStr.size() - 2);
}


    std::string llamaExe = "D:\\Userslol\\mental_health_app\\llama.cpp\\build\\bin\\Release\\llama-run.exe";
    std::string modelPath = "D:\\Userslol\\mental_health_app\\llama.cpp\\models\\mistral-7b-instruct-v0.1.Q4_K_M.gguf";

    std::string prompt =    "The user feels like this '" + userFeeling + "'. Return the feeling the user propably feels at this moment. Only answer in one word. For example happy, denial, insecurity. ";

    // Baue den Befehl wie in der CMD
    std::string command = "\"" + llamaExe + "\" --temp 0.2 \"" + modelPath + "\" \"" + prompt + "\"";
    
    // Wrap in cmd /C, um sicherzustellen, dass der Befehl korrekt geparst wird
    const std::string Tempfile = "llm_output.txt"; 
    std::string command_redirect = command + ">" + Tempfile; 
    std::string finalCommand = "cmd /C \"" + command + " > " + Tempfile + "\"";

    int result = system(finalCommand.c_str());

    std::cout << "system() return code: " << result << std::endl;

    if (result != 0) {
        std::cerr << "Fehler beim Ausführen des LLM-Befehls!" << std::endl;
    }
    
    
}// Hilfsfunktion zum Bereinigen von Strings
std::string cleanString(const std::string& str) {
    std::string cleaned = str;
    
    // Entferne Whitespace am Anfang und Ende
    cleaned.erase(0, cleaned.find_first_not_of(" \t\n\r"));
    cleaned.erase(cleaned.find_last_not_of(" \t\n\r") + 1);
    
    // Konvertiere zu lowercase
    std::transform(cleaned.begin(), cleaned.end(), cleaned.begin(), ::tolower);
    
    return cleaned;
}

void showQuoteForEmotionRobust(const std::string& emotion, const json& books) {
    
    std::string cleanedEmotion = cleanString(emotion);
    bool found = false;
    int entryCount = 0;
    int topScores[3] = {INT_MIN, INT_MIN, INT_MIN};
        json topQoutes[3]; 
    std::srand(std::time(0));


    for (const nlohmann::json& entry : books) {
        entryCount++;
       
        if (entry.contains("emotion")) {
            std::string jsonEmotion = entry["emotion"];
            std::string cleanedJsonEmotion = cleanString(jsonEmotion);
            
            // Mehrere Vergleichsmethoden:
            bool exactMatch = (cleanedJsonEmotion == cleanedEmotion);
            bool containsMatch = (cleanedJsonEmotion.find(cleanedEmotion) != std::string::npos);
            bool reverseContains = (cleanedEmotion.find(cleanedJsonEmotion) != std::string::npos);
            
            if (exactMatch || (containsMatch && cleanedEmotion.length() > 3) || (reverseContains && cleanedJsonEmotion.length() > 3)) {
                int score = entry.value("positive", 0) - entry.value("negative", 0);

                std::cout << score; 
                for(int i = 0; i<3; i++) {
                    if(score >topScores[i]) {
                         for (int j = 2; j > i; --j) {
                        topScores[j] = topScores[j - 1];
                        topQoutes[j] = topQoutes[j - 1];
                    }
                    topScores[i] = score;
                    topQoutes[i] = entry;
                    break;
                }
                    
                }
                
           
                found = true;
            }
        }
    }
        
    if(found) {
         int available = (topScores[1] == INT_MIN) ? 1 : (topScores[2] == INT_MIN ? 2 : 3);
            int randomIndex = std::rand() % available;

            json& selectedQuote = topQoutes[randomIndex];
                  std::cout << "\n✅ MATCH FOUND!" << std::endl;
                std::cout << "\nQuote that matches your emotion:\n";
                std::cout << "\"" << selectedQuote["quote"] << "\"" << std::endl;
                std::cout << "- " << selectedQuote["author"] << ", " << selectedQuote["book"] 
              << ", Emotion: " << selectedQuote["emotion"]
              << ", +: " << selectedQuote["positive"] 
              << ", -: " << selectedQuote["negative"] << std::endl;
    }

    else 
    {
        std::cout << "\n❌ No matching quote found for emotion '" << emotion << "'" << std::endl;
    }
    }

int main() {
    SetConsoleOutputCP(CP_UTF8);

    // Lade die Bücher-Daten aus der JSON-Datei
    json books = loadBooksDataset();

    std::string userInput;
    std::cout << "Wie fühlst du dich? ";
    std::getline(std::cin, userInput);

    runLLM(userInput, books);
    std::string emotion = dateilesen(); 
    std::cout << "[" << emotion << "]";
    showQuoteForEmotionRobust(emotion, books);
    std::cout << "\nFertig! Drücke Enter zum Beenden...";
    std::cin.get();
    return 0;
    //Kein Enter bei der Eingabe dann sendet es los!
}
