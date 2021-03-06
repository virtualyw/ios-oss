import Library
import Prelude
import Result
import XCTest
@testable import Kickstarter_Framework
@testable import KsApi
@testable import ReactiveExtensions_TestHelpers

internal final class FundingGraphViewTests: TestCase {

  private let vm: DashboardFundingCellViewModelType = DashboardFundingCellViewModel()
  private let graphData = TestObserver<FundingGraphData, NoError>()

  override func setUp() {
    super.setUp()
    AppEnvironment.pushEnvironment(mainBundle: NSBundle.framework)
    self.vm.outputs.graphData.observe(self.graphData.observer)
  }

  override func tearDown() {
    super.tearDown()
    AppEnvironment.popEnvironment()
  }

  func testGoalLabelLanguages() {
    let graphView = FundingGraphView(frame: CGRect(x: 0, y: 0, width: 300, height: 225))
    let stats = [3_000, 4_000, 5_000, 7_000, 8_000, 13_000, 14_000, 15_000, 17_000, 18_000]

    self.vm.inputs.configureWith(
      fundingDateStats: fundingStats(forProject: project, pledgeValues: stats),
      project: project
    )

    graphView.project = self.graphData.lastValue!.project
    graphView.stats = self.graphData.lastValue!.stats
    graphView.yAxisTickSize = self.graphData.lastValue!.yAxisTickSize

    Language.allLanguages.forEach { language in
      withEnvironment(language: language) {
        graphView.setNeedsDisplay()
        FBSnapshotVerifyView(graphView, identifier: "lang_\(language)")
      }
    }
  }

  func testGraphStates() {
    let graphView = FundingGraphView(frame: CGRect(x: 0, y: 0, width: 300, height: 225))

    let underFundedStats = [
      3_000, 4_000, 5_000, 7_000, 8_000
    ]

    let justFundedStats = underFundedStats + [
      13_000, 14_000, 15_000, 17_000, 18_000,
      20_000, 21_000, 22_000, 24_000
    ]

    let backUnderFundedStats = justFundedStats + [
      23_000, 22_500, 20_000, 19_500, 18_000
    ]

    let backOverFunded = backUnderFundedStats + [
      21_000, 21_500, 22_500, 24_000, 25_000,
      26_000, 29_000
    ]

    let oneDayLeft = backOverFunded + [
      32_000, 38_000, 48_000, 50_000
    ]

    let completedStats = oneDayLeft + [55_000]

    let statStates = [
      "Under Funded": underFundedStats,
      "Just Funded": justFundedStats,
      "Back Under Funded": backUnderFundedStats,
      "Back Over Funded": backOverFunded,
      "One Day Left": oneDayLeft,
      "Completed": completedStats,
    ]

    for (key, stats) in statStates {
      self.vm.inputs.configureWith(
        fundingDateStats: fundingStats(forProject: project, pledgeValues: stats),
        project: project
      )

      graphView.project = self.graphData.lastValue!.project
      graphView.stats = self.graphData.lastValue!.stats
      graphView.yAxisTickSize = self.graphData.lastValue!.yAxisTickSize

      FBSnapshotVerifyView(graphView, identifier: "state_\(key)")
    }
  }
}

private let project = .template
  |> Project.lens.stats.goal .~ 22_000
  |> Project.lens.dates.launchedAt .~ 1477494745
  |> Project.lens.dates.deadline .~ 1480187443

private func fundingStats(forProject project: Project, pledgeValues: [Int])
  -> [ProjectStatsEnvelope.FundingDateStats] {

    return pledgeValues.enumerate().map { idx, pledged in
      .template
        |> ProjectStatsEnvelope.FundingDateStats.lens.cumulativePledged .~ pledged
        |> ProjectStatsEnvelope.FundingDateStats.lens.date
          .~ (project.dates.launchedAt + NSTimeInterval(idx * 86_400))
    }
}
