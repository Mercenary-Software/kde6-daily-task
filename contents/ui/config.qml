import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid 2.0

Kirigami.FormLayout {
    id: root
    // Do not use Layout attached properties here to avoid attached object issues

    // Config property bindings expected by the dialog
    property alias cfg_taskLabel: taskLabelField.text
    property alias cfg_remindEnabled: remindEnabledBox.checked
    property alias cfg_horizontalWidth: horizontalWidthSpin.value
    property alias cfg_verticalHeight: verticalHeightSpin.value

    // Only expose the properties we actually bind

    TextField {
        id: taskLabelField
        Kirigami.FormData.label: i18n("Task name")
        placeholderText: i18n("My Daily Task")
        enabled: !Plasmoid.immutable
    }

    CheckBox {
        id: remindEnabledBox
        Kirigami.FormData.label: i18n("Reminder")
        text: i18n("Use remind color when not done")
        enabled: !Plasmoid.immutable
    }

    SpinBox {
        id: horizontalWidthSpin
        Kirigami.FormData.label: i18n("Horizontal width (px)")
        from: 80
        to: 2000
        stepSize: 10
        editable: true
        enabled: !Plasmoid.immutable
    }

    SpinBox {
        id: verticalHeightSpin
        Kirigami.FormData.label: i18n("Vertical height (px)")
        from: 60
        to: 2000
        stepSize: 10
        editable: true
        enabled: !Plasmoid.immutable
    }
}
