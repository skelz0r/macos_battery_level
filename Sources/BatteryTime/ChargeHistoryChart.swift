import Charts
import SwiftUI

struct ChargeHistoryChart: View {
    let history: ChargeHistory

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            chart(until: context.date)
        }
        .frame(height: 96)
    }

    private func chart(until now: Date) -> some View {
        let segments = history.segments(until: now)
        return Chart {
            ForEach(Array(history.pluggedInPeriods(until: now).enumerated()), id: \.offset) { _, period in
                RectangleMark(
                    xStart: .value("Plugged in", period.lowerBound),
                    xEnd: .value("Unplugged", period.upperBound)
                )
                .foregroundStyle(.green.opacity(0.18))
            }
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                ForEach(segment, id: \.date) { sample in
                    AreaMark(
                        x: .value("Time", sample.date),
                        yStart: .value("Floor", 0),
                        yEnd: .value("Charge", sample.percentage),
                        series: .value("Segment", index)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Color.primary.opacity(0.18), .clear], startPoint: .top, endPoint: .bottom))
                    LineMark(
                        x: .value("Time", sample.date),
                        y: .value("Charge", sample.percentage),
                        series: .value("Segment", index)
                    )
                    .foregroundStyle(Color.primary.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }
                if let sample = segment.first, segment.count == 1 {
                    PointMark(x: .value("Time", sample.date), y: .value("Charge", sample.percentage))
                        .foregroundStyle(Color.primary.opacity(0.7))
                        .symbolSize(12)
                }
            }
        }
        .chartXScale(domain: now.addingTimeInterval(-ChargeHistory.window)...now)
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) {
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0, 50, 100]) {
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}
