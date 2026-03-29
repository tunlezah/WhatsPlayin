import Foundation

struct IdentificationResult {
    let title: String?
    let artist: String?
    let album: String?
    let releaseYear: Int?
    let musicBrainzRecordingID: String?
    let musicBrainzReleaseID: String?
    let confidence: Double
    let fingerprintHash: String
    let provider: String

    var isValid: Bool {
        title != nil && artist != nil && confidence > 0
    }
}

struct AcoustIDResponse: Codable {
    let status: String
    let results: [AcoustIDResult]?

    struct AcoustIDResult: Codable {
        let id: String
        let score: Double
        let recordings: [Recording]?

        struct Recording: Codable {
            let id: String
            let title: String?
            let artists: [Artist]?
            let releasegroups: [ReleaseGroup]?

            struct Artist: Codable {
                let id: String
                let name: String
            }

            struct ReleaseGroup: Codable {
                let id: String
                let title: String?
                let type: String?
                let secondarytypes: [String]?
            }
        }
    }
}

struct MusicBrainzRecordingResponse: Codable {
    let id: String
    let title: String?
    let releases: [Release]?

    struct Release: Codable {
        let id: String
        let title: String?
        let date: String?

        enum CodingKeys: String, CodingKey {
            case id, title, date
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, title, releases
    }
}

struct CoverArtResponse: Codable {
    let images: [CoverArtImage]

    struct CoverArtImage: Codable {
        let image: String
        let thumbnails: Thumbnails?
        let front: Bool?

        struct Thumbnails: Codable {
            let small: String?
            let large: String?
            let the250: String?
            let the500: String?
            let the1200: String?

            enum CodingKeys: String, CodingKey {
                case small, large
                case the250 = "250"
                case the500 = "500"
                case the1200 = "1200"
            }
        }
    }
}
