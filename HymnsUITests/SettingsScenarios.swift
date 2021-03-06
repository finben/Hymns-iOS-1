import XCTest

class SettingsScenarios: BaseTestCase {

    override func setUp() {
        super.setUp()
        app.launch()
    }

    func test_toggleRepeatChorus() {
        _ = HomeViewCan(app, testCase: self)
            .waitForButtons("classic2")
            .tapResult("classic2")
            .waitForStaticTexts("classic hymn 2 chorus")
            .checkStaticTextCount("classic hymn 2 chorus", 1)
            .goBackToHome()
            .goToSettings()
            .toggleRepeatChorus()
            .returnToHome()
            .tapHome()
            .tapResult("classic2")
            .waitForStaticTexts("classic hymn 2 chorus")
            .checkStaticTextCount("classic hymn 2 chorus", 2)
    }

    func test_clearHistory() {
        _ = HomeViewCan(app, testCase: self)
            .waitForButtons("classic1151")
            .goToSettings()
            .tapClearHistory()
            .waitForStaticTexts("Recent songs cleared")
            .returnToHome()
            .tapHome()
            .verifyButtonsNotExist("classic1151")
            .waitForImages("empty search illustration")
    }

    func test_goToAboutUs() {
        _ = HomeViewCan(app, testCase: self)
            .goToSettings()
            .tapAboutUs()
            .verifyAboutUsDialogExists()
            .cancelAboutUs()
            .verifyAboutUsDialogNotExists()
    }
}
