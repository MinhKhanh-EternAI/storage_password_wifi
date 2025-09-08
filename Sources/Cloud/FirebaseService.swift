import Foundation
import FirebaseFirestore

/// Service để sync với Firestore
final class FirebaseService {
    private var db: Firestore { Firestore.firestore() }
    private var docRef: DocumentReference { 
        db.collection("wifiOffline").document("db") 
    }
    
    // Upload networks lên Firebase
    func uploadNetworks(_ networks: [WiFiNetwork], completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let payload = WiFiStore.ExportFileV2(items: networks)
            let data = try JSONEncoder.iso.encode(payload)
            guard let json = String(data: data, encoding: .utf8) else {
                return completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Encode JSON failed"])))
            }
            
            let body: [String: Any] = [
                "json": json,
                "updatedAt": Date()
            ]
            
            docRef.setData(body, merge: false) { error in
                if let e = error { 
                    completion(.failure(e)) 
                } else { 
                    completion(.success(())) 
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // Fetch networks từ Firebase
    func fetchNetworks(completion: @escaping (Result<[WiFiNetwork], Error>) -> Void) {
        docRef.getDocument { snap, error in
            if let e = error { 
                return completion(.failure(e)) 
            }
            
            guard let data = snap?.data(), 
                  let json = data["json"] as? String else {
                return completion(.failure(NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy dữ liệu trên Cloud"])))
            }
            
            do {
                let raw = Data(json.utf8)
                let dec = JSONDecoder()
                
                // Thử decode nhiều format
                if let v2 = try? dec.decode(WiFiStore.ExportFileV2.self, from: raw) {
                    completion(.success(v2.items))
                } else if let wrap = try? dec.decode(Wrapper.self, from: raw) {
                    completion(.success(wrap.items))
                } else {
                    let arr = try dec.decode([WiFiNetwork].self, from: raw)
                    completion(.success(arr))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private struct Wrapper: Codable { 
        let items: [WiFiNetwork] 
    }
}

private extension JSONEncoder {
    static var iso: JSONEncoder {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return enc
    }
}