import Foundation
import FirebaseFirestore

/// Lưu toàn bộ DB vào 1 document duy nhất (field "json": String chứa JSON đầy đủ).
/// Cloud path: collection "wifiOffline" / doc "db"
final class CloudSyncService {
    static let shared = CloudSyncService()
    private init() {}

    private var db: Firestore { Firestore.firestore() }
    private var docRef: DocumentReference { db.collection("wifiOffline").document("db") }

    // Đẩy local -> cloud (ghi đè toàn bộ)
    func push(from store: WiFiStore, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let payload = WiFiStore.ExportFileV2(items: store.items)
            let data = try JSONEncoder.iso.encode(payload)
            guard let json = String(data: data, encoding: .utf8) else {
                return completion(.failure(NSError(domain: "CloudSync", code: -1, userInfo: [NSLocalizedDescriptionKey:"Encode JSON failed"])))
            }
            let body: [String: Any] = [
                "json": json,
                "updatedAt": Date()
            ]
            docRef.setData(body, merge: false) { error in
                if let e = error { completion(.failure(e)) } else { completion(.success(())) }
            }
        } catch {
            completion(.failure(error))
        }
    }

    // Kéo cloud -> local (ghi đè local)
    func pull(into store: WiFiStore, completion: @escaping (Result<Void, Error>) -> Void) {
        docRef.getDocument { snap, error in
            if let e = error { return completion(.failure(e)) }
            guard let data = snap?.data(), let json = data["json"] as? String else {
                return completion(.failure(NSError(domain: "CloudSync", code: 404, userInfo: [NSLocalizedDescriptionKey:"Không tìm thấy dữ liệu trên Cloud"])))
            }
            do {
                let raw = Data(json.utf8)
                // decode linh hoạt v2 / wrapper / array
                let dec = JSONDecoder()
                if let v2 = try? dec.decode(WiFiStore.ExportFileV2.self, from: raw) {
                    store.replaceAll(with: v2.items)
                } else if let wrap = try? dec.decode(Wrapper.self, from: raw) {
                    store.replaceAll(with: wrap.items)
                } else {
                    let arr = try dec.decode([WiFiNetwork].self, from: raw)
                    store.replaceAll(with: arr)
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private struct Wrapper: Codable { let items: [WiFiNetwork] }
}
