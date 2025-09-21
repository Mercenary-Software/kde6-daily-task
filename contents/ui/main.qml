import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid 2.0

PlasmoidItem {
    id: root
    // Prefer configurable dimension along the panel's length
    readonly property int configuredWidth: Plasmoid.configuration.horizontalWidth || 280
    readonly property int configuredHeight: Plasmoid.configuration.verticalHeight || 140

    implicitWidth: Plasmoid.formFactor === PlasmaCore.Types.Horizontal ? configuredWidth : 280
    implicitHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? configuredHeight : 140

    // Hint panel layout managers explicitly
    Layout.preferredWidth: Plasmoid.formFactor === PlasmaCore.Types.Horizontal ? configuredWidth : -1
    Layout.preferredHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? configuredHeight : -1
    Layout.minimumWidth: 80
    Layout.minimumHeight: 60

    // Updated at midnight via timer to keep bindings consistent
    property string todayKey: dateKey(new Date())
    readonly property string yesterdayKey: dateKey(new Date(Date.now() - 24*60*60*1000))

    property bool doneToday: Plasmoid.configuration.lastDoneDate === todayKey

    function dateKey(d) {
        // Local YYYY-MM-DD
        const y = d.getFullYear()
        const m = (d.getMonth() + 1).toString().padStart(2, '0')
        const day = d.getDate().toString().padStart(2, '0')
        return y + "-" + m + "-" + day
    }

    function msUntilMidnight() {
        const now = new Date()
        const midnight = new Date(now)
        midnight.setHours(24, 0, 0, 0)
        return midnight - now
    }

    function ensureStreakConsistency() {
        // Recompute current streak and normalize lastDoneDate from completedDates
        const streak = computeCurrentStreak()
        if ((Plasmoid.configuration.currentStreak || 0) !== streak) {
            Plasmoid.configuration.currentStreak = streak
        }
        // Set lastDoneDate to the most recent completed date (today if exists)
        const mostRecent = mostRecentCompletedDate()
        if ((Plasmoid.configuration.lastDoneDate || "") !== mostRecent) {
            Plasmoid.configuration.lastDoneDate = mostRecent
        }
    }

    function markDoneToday() {
        if (hasDate(todayKey))
            return
        addDate(todayKey)
        const newStreak = computeCurrentStreak()
        Plasmoid.configuration.lastDoneDate = todayKey
        Plasmoid.configuration.currentStreak = newStreak
        if ((Plasmoid.configuration.bestStreak || 0) < newStreak) {
            Plasmoid.configuration.bestStreak = newStreak
        }
    }

    function undoToday() {
        if (!hasDate(todayKey))
            return
        removeDate(todayKey)
        const newStreak = computeCurrentStreak()
        Plasmoid.configuration.currentStreak = newStreak
        Plasmoid.configuration.lastDoneDate = mostRecentCompletedDate()
    }

    Timer {
        id: midnightTimer
        interval: root.msUntilMidnight()
        repeat: false
        running: true
        onTriggered: {
            // Refresh date key and consistency across midnight
            root.todayKey = root.dateKey(new Date())
            root.ensureStreakConsistency()
            // Schedule next midnight update
            midnightTimer.interval = root.msUntilMidnight()
            midnightTimer.start()
        }
    }

    Component.onCompleted: ensureStreakConsistency()

    // Helpers for date history
    function hasDate(key) {
        const arr = Plasmoid.configuration.completedDates || []
        return arr.indexOf(key) !== -1
    }
    function addDate(key) {
        let arr = (Plasmoid.configuration.completedDates || []).slice()
        if (arr.indexOf(key) === -1) {
            arr.push(key)
            Plasmoid.configuration.completedDates = arr
        }
    }
    function removeDate(key) {
        let arr = (Plasmoid.configuration.completedDates || []).slice()
        const i = arr.indexOf(key)
        if (i !== -1) {
            arr.splice(i, 1)
            Plasmoid.configuration.completedDates = arr
        }
    }
    function parseDate(key) {
        // key = YYYY-MM-DD
        const y = parseInt(key.slice(0,4))
        const m = parseInt(key.slice(5,7)) - 1
        const d = parseInt(key.slice(8,10))
        const dt = new Date()
        dt.setFullYear(y, m, d)
        dt.setHours(0,0,0,0)
        return dt
    }
    function mostRecentCompletedDate() {
        const arr = Plasmoid.configuration.completedDates || []
        if (arr.length === 0) return ""
        // Find max by date
        let best = arr[0]
        for (let i = 1; i < arr.length; ++i) {
            if (parseDate(arr[i]) > parseDate(best)) best = arr[i]
        }
        return best
    }
    function computeCurrentStreak() {
        let count = 0
        const dayMs = 24*60*60*1000
        let d = new Date()
        d.setHours(0,0,0,0)
        while (hasDate(dateKey(d))) {
            count++
            d = new Date(d.getTime() - dayMs)
        }
        return count
    }

    Rectangle {
        radius: 5
        color: root.doneToday
               ? Kirigami.Theme.backgroundColor
               : (Plasmoid.configuration.remindEnabled
                    ? Kirigami.Theme.highlightColor
                    : Kirigami.Theme.backgroundColor)
        border.color: Kirigami.Theme.textColor
        anchors.fill: parent
        anchors.margins: 0
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4
            // Header row
            RowLayout {
                spacing: 4
                Kirigami.Icon {
                    source: root.doneToday ? "task-complete" : "task-past-due"
                    implicitWidth: 18
                    implicitHeight: 18
                }
                Label {
                    text: Plasmoid.configuration.taskLabel || "My Daily Task"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Label {
                    text: "(" + (Plasmoid.configuration.currentStreak || 0) + "/" + (Plasmoid.configuration.bestStreak || 0) + ")"
                    visible: (Plasmoid.configuration.currentStreak || 0) > 0 || (Plasmoid.configuration.bestStreak || 0) > 0
                    opacity: 0.8
                    font.pixelSize: Math.max(9, Kirigami.Theme.defaultFont.pixelSize - 2)
                }
            }

            // Action row (buttons on next line)
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Item { Layout.fillWidth: true }
                ToolButton {
                    text: root.doneToday ? i18n("Undo") : i18n("Done")
                    icon.name: root.doneToday ? "edit-undo" : "checkbox"
                    onClicked: root.doneToday ? root.undoToday() : root.markDoneToday()
                }
            }

            // Calendar grid for current month (compact)
            GridLayout {
                id: cal
                columns: 7
                columnSpacing: 1
                rowSpacing: 3
                Layout.fillWidth: true
                Layout.margins: 0
                // Weekday header, localized, starting from locale's first day
                property var loc: Qt.locale()
                property int firstDowQt: loc.firstDayOfWeek // 1=Mon..7=Sun
                Repeater {
                    model: 7
                    delegate: Label {
                        readonly property int dayQt: ((cal.firstDowQt - 1 + index) % 7) + 1 // 1=Mon..7=Sun
                        readonly property string narrow: cal.loc.standaloneDayName(dayQt, Locale.NarrowFormat)
                        readonly property string shortName: cal.loc.standaloneDayName(dayQt, Locale.ShortFormat)
                        text: narrow && narrow.length > 0 ? narrow : (shortName && shortName.length > 0 ? shortName.charAt(0) : "")
                        opacity: 0.7
                        font.pixelSize: Math.max(9, Kirigami.Theme.defaultFont.pixelSize - 2)
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                        Layout.minimumWidth: 12
                    }
                }
                // Days padding + day checkboxes
                property var now: new Date()
                property int year: now.getFullYear()
                property int month: now.getMonth() // 0..11
                function daysInMonth(y, m) { return new Date(y, m+1, 0).getDate() }
                function firstWeekdayOffset(y, m) {
                    // Leading blanks so first column aligns with locale's first day
                    let w = new Date(y, m, 1).getDay() // 0=Sun..6=Sat
                    let firstDowSundayBase = cal.firstDowQt % 7 // 7->0 (Sun), 1->1 (Mon)
                    return ((w - firstDowSundayBase) + 7) % 7
                }
                // Leading blanks
                Repeater {
                    model: cal.firstWeekdayOffset(cal.year, cal.month)
                    delegate: Item { width: 12; height: 12 }
                }
                // Day cells
                Repeater {
                    model: cal.daysInMonth(cal.year, cal.month)
                    delegate: Rectangle {
                        readonly property int day: index + 1
                        readonly property string key: root.dateKey(new Date(cal.year, cal.month, day))
                        width: 12
                        height: 12
                        radius: width / 2
                        antialiasing: true
                        color: root.hasDate(key) ? Kirigami.Theme.highlightColor : "transparent"
                        border.color: Kirigami.Theme.textColor
                        border.width: 2
                        opacity: root.hasDate(key) ? 1.0 : 0.6
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
