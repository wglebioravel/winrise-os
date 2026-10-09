/* Apresentação exibida durante a instalação do WinRise OS */
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    function onActivate() { }
    function onLeave() { }

    Timer {
        interval: 12000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1f6fd1" }
                GradientStop { position: 1.0; color: "#0b2550" }
            }
        }
        Image {
            id: logo0
            source: "winrise-logo.png"
            width: 96; height: 96
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.12
        }
        Text {
            id: title0
            text: "Bem-vindo ao WinRise OS"
            color: "white"
            font.pixelSize: 30
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo0.bottom
            anchors.topMargin: 24
        }
        Text {
            text: "Seu novo sistema está sendo instalado. Isso leva só alguns minutos — enquanto isso, conheça um pouco do WinRise."
            color: "#dcecff"
            font.pixelSize: 17
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            width: parent.width * 0.75
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: title0.bottom
            anchors.topMargin: 16
        }
    }
    Slide {
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1f6fd1" }
                GradientStop { position: 1.0; color: "#0b2550" }
            }
        }
        Image {
            id: logo1
            source: "winrise-logo.png"
            width: 96; height: 96
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.12
        }
        Text {
            id: title1
            text: "Visual familiar"
            color: "white"
            font.pixelSize: 30
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo1.bottom
            anchors.topMargin: 24
        }
        Text {
            text: "Barra de tarefas, menu Iniciar, Este Computador, Lixeira e os atalhos que você já conhece: Win, Win+E, Win+D, Alt+Tab e Ctrl+Shift+Esc."
            color: "#dcecff"
            font.pixelSize: 17
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            width: parent.width * 0.75
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: title1.bottom
            anchors.topMargin: 16
        }
    }
    Slide {
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1f6fd1" }
                GradientStop { position: 1.0; color: "#0b2550" }
            }
        }
        Image {
            id: logo2
            source: "winrise-logo.png"
            width: 96; height: 96
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.12
        }
        Text {
            id: title2
            text: "Leve e rápido"
            color: "white"
            font.pixelSize: 30
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo2.bottom
            anchors.topMargin: 24
        }
        Text {
            text: "Base Debian estável e KDE Plasma configurado no essencial. Mais memória e processador sobrando para o que importa: você."
            color: "#dcecff"
            font.pixelSize: 17
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            width: parent.width * 0.75
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: title2.bottom
            anchors.topMargin: 16
        }
    }
    Slide {
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1f6fd1" }
                GradientStop { position: 1.0; color: "#0b2550" }
            }
        }
        Image {
            id: logo3
            source: "winrise-logo.png"
            width: 96; height: 96
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.12
        }
        Text {
            id: title3
            text: "Sem bloatware"
            color: "white"
            font.pixelSize: 30
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo3.bottom
            anchors.topMargin: 24
        }
        Text {
            text: "Nada de notícias, clima, anúncios, telemetria ou apps empurrados. Só o essencial: navegador, arquivos, editor, terminal e loja de apps."
            color: "#dcecff"
            font.pixelSize: 17
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            width: parent.width * 0.75
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: title3.bottom
            anchors.topMargin: 16
        }
    }
    Slide {
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1f6fd1" }
                GradientStop { position: 1.0; color: "#0b2550" }
            }
        }
        Image {
            id: logo4
            source: "winrise-logo.png"
            width: 96; height: 96
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.12
        }
        Text {
            id: title4
            text: "Instale o que quiser"
            color: "white"
            font.pixelSize: 30
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo4.bottom
            anchors.topMargin: 24
        }
        Text {
            text: "Abra a Discover para instalar programas com um clique, ou dê duplo clique em arquivos .deb e AppImage."
            color: "#dcecff"
            font.pixelSize: 17
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            width: parent.width * 0.75
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: title4.bottom
            anchors.topMargin: 16
        }
    }
}
