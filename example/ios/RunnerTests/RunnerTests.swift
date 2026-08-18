import XCTest
@testable import notivera_flutter

class RunnerTests: XCTestCase {
  func testPluginCanBeConstructed() {
    XCTAssertNotNil(NotiveraFlutterPlugin())
  }
}
