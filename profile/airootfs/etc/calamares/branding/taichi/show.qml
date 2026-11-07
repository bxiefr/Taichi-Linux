import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation {
    id: presentation

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#f5f5f5"
        }
        Image {
            id: logo
            source: "logo.png"
            width: 128; height: 128
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 80
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo.bottom
            anchors.topMargin: 24
            text: "Taichi Linux kuruluyor"
            color: "#1f1f1f"
            font.pixelSize: 28
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo.bottom
            anchors.topMargin: 72
            text: "Denge ve sadelik. Lütfen bekleyin..."
            color: "#555555"
            font.pixelSize: 16
        }
    }
}
