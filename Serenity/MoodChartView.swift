//
//  MoodChartView.swift
//  Serenity
//
//  Grafico dell'umore con Swift Charts, ispirato ad Apple Health
//

import SwiftUI
import Charts

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let score: Double
}

enum TimePeriod: String, CaseIterable {
    case week = "Settimana"
    case month = "Mese"

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        }
    }
}

struct MoodChartView: View {
    let entries: [MoodEntry]
    let period: TimePeriod

    private var chartData: [ChartDataPoint] {
        let calendar = Calendar.current

        // Raggruppa per giorno e calcola la media
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date)
        }

        return grouped.map { date, dayEntries in
            let validEntries = dayEntries.filter { $0.checkInType == .evening }
            guard !validEntries.isEmpty else {
                return ChartDataPoint(date: date, score: 0)
            }
            let avg = Double(validEntries.reduce(0) { $0 + $1.moodScore }) / Double(validEntries.count)
            return ChartDataPoint(date: date, score: avg)
        }.sorted { $0.date < $1.date }
    }

    private var hasData: Bool {
        !chartData.isEmpty && chartData.contains { $0.score != 0 }
    }

    private let chartTeal = Color(red: 0.2, green: 0.7, blue: 0.7)
    private let chartCoral = Color(red: 0.95, green: 0.5, blue: 0.45)
    private let cardMint = Color(red: 0.92, green: 0.98, blue: 0.96)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(chartTeal)
                Text("Andamento umore")
                    .font(.headline)
                    .foregroundStyle(Color(white: 0.2))
            }

            if hasData {
                Chart(chartData) { point in
                    // Area sotto la linea
                    AreaMark(
                        x: .value("Data", point.date, unit: .day),
                        y: .value("Umore", point.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                chartTeal.opacity(0.4),
                                chartTeal.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    // Linea principale
                    LineMark(
                        x: .value("Data", point.date, unit: .day),
                        y: .value("Umore", point.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [chartTeal, ChatStyle.accentPurpleDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    // Punti colorati in base al valore
                    PointMark(
                        x: .value("Data", point.date, unit: .day),
                        y: .value("Umore", point.score)
                    )
                    .foregroundStyle(pointColor(for: point.score))
                    .symbolSize(50)
                }
                .chartYScale(domain: -2.5...2.5)
                .chartYAxis {
                    AxisMarks(values: [-2, -1, 0, 1, 2]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color(white: 0.8))
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text(moodEmoji(for: intValue))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: period == .week ? .day : .weekOfYear)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color(white: 0.8))
                        AxisValueLabel(format: period == .week ? .dateTime.weekday(.abbreviated) : .dateTime.day().month(.abbreviated))
                            .font(.caption2)
                            .foregroundStyle(Color(white: 0.5))
                    }
                }
                .frame(height: 180)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundStyle(chartTeal.opacity(0.5))
                    Text("Nessun dato")
                        .font(.headline)
                        .foregroundStyle(Color(white: 0.3))
                    Text("Completa il check-in serale per vedere il grafico del tuo umore")
                        .font(.caption)
                        .foregroundStyle(Color(white: 0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardMint)
                .shadow(color: chartTeal.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }

    private func pointColor(for score: Double) -> Color {
        switch score {
        case 1.5...: return Color(red: 0.3, green: 0.8, blue: 0.5) // Green
        case 0.5..<1.5: return Color(red: 0.5, green: 0.8, blue: 0.7) // Teal
        case -0.5..<0.5: return Color(red: 0.95, green: 0.75, blue: 0.3) // Amber
        case -1.5..<(-0.5): return Color(red: 0.95, green: 0.6, blue: 0.5) // Light coral
        default: return Color(red: 0.9, green: 0.4, blue: 0.4) // Coral
        }
    }

    private func moodEmoji(for score: Int) -> String {
        switch score {
        case 2: return "😊"
        case 1: return "🙂"
        case 0: return "😐"
        case -1: return "😔"
        case -2: return "😢"
        default: return ""
        }
    }
}

#Preview {
    let sampleEntries: [MoodEntry] = [
        MoodEntry(date: Date().addingTimeInterval(-86400 * 6), checkInType: .evening, moodScore: 1),
        MoodEntry(date: Date().addingTimeInterval(-86400 * 5), checkInType: .evening, moodScore: 2),
        MoodEntry(date: Date().addingTimeInterval(-86400 * 4), checkInType: .evening, moodScore: 0),
        MoodEntry(date: Date().addingTimeInterval(-86400 * 3), checkInType: .evening, moodScore: -1),
        MoodEntry(date: Date().addingTimeInterval(-86400 * 2), checkInType: .evening, moodScore: 1),
        MoodEntry(date: Date().addingTimeInterval(-86400 * 1), checkInType: .evening, moodScore: 2),
        MoodEntry(date: Date(), checkInType: .evening, moodScore: 1),
    ]

    return MoodChartView(entries: sampleEntries, period: .week)
        .padding()
}
