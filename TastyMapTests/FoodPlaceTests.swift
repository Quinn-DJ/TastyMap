import SwiftData
import XCTest
@testable import TastyMap

final class FoodPlaceTests: XCTestCase {
    func testSearchMatchesNameAddressCategoryAndTags() {
        let place = FoodPlace(
            ownerID: "user-1",
            name: "小馆面馆",
            address: "文三路 18 号",
            latitude: 30.27,
            longitude: 120.15,
            category: "面食",
            tags: ["安静", "适合午餐"],
            note: "牛肉面很好吃"
        )

        XCTAssertTrue(place.matches("小馆"))
        XCTAssertTrue(place.matches("文三路"))
        XCTAssertTrue(place.matches("面食"))
        XCTAssertTrue(place.matches("安静 午餐"))
        XCTAssertTrue(place.matches("牛肉"))
        XCTAssertFalse(place.matches("咖啡"))
    }

    @MainActor
    func testSwiftDataRoundTripPreservesTagsAndOwner() throws {
        let schema = Schema([FoodPlace.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        let context = container.mainContext
        let place = FoodPlace(
            ownerID: "user-42",
            name: "测试餐厅",
            address: "测试路 1 号",
            latitude: 31.23,
            longitude: 121.47,
            category: "中餐",
            tags: ["朋友聚会", "不辣"],
            note: "脆皮鸡",
            status: .visited,
            rating: 4.5
        )

        context.insert(place)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<FoodPlace>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.ownerID, "user-42")
        XCTAssertEqual(fetched.first?.tags, ["朋友聚会", "不辣"])
        XCTAssertEqual(fetched.first?.status, .visited)
        XCTAssertEqual(fetched.first?.rating, 4.5)
    }

    func testRemotePlaceDecodesSyncTimestamps() throws {
        let json = """
        {
          "id": "remote-1",
          "owner": "user-1",
          "client_id": "0B0F7B8B-6E00-42AA-9D5A-860B9F0610A1",
          "name": "TastyMap Test",
          "address": "Test Road",
          "latitude": 31.23,
          "longitude": 121.47,
          "category": "restaurant",
          "tags": ["quiet"],
          "note": "",
          "status": "want_to_go",
          "rating": 4.5,
          "client_updated_at": "2026-10-27T10:00:00.000Z",
          "deleted": false,
          "created": "2026-10-27T10:00:00.000Z",
          "updated": "2026-10-27T10:01:00.000Z"
        }
        """

        let place = try JSONDecoder().decode(
            RemotePlace.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(place.id, "remote-1")
        XCTAssertEqual(place.clientId, "0B0F7B8B-6E00-42AA-9D5A-860B9F0610A1")
        XCTAssertNotNil(PocketBaseDate.date(from: place.updatedAt))
    }
}
