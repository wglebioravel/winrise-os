// WinRise Connect OS — layout padrão estilo Windows 10
// Barra de tarefas única embaixo: Iniciar | apps fixados + janelas | bandeja | relógio | mostrar área de trabalho

var panel = new Panel;
panel.location = "bottom";
panel.height = 2 * Math.ceil(gridUnit * 2.4 / 2);
panel.hiding = "none";
try { panel.floating = false; } catch (e) {}

// Menu Iniciar (Kickoff: busca, fixados e categorias)
var kickoff = panel.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["Shortcuts"];
kickoff.writeConfig("global", "Alt+F1");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "winrise-start");
kickoff.writeConfig("favoritesDisplay", 0);      // fixados em grade
kickoff.writeConfig("applicationsDisplay", 1);   // categorias em lista
kickoff.writeConfig("showActionButtonCaptions", true);
kickoff.writeConfig("favorites", [
    "google-chrome.desktop",
    "org.kde.dolphin.desktop",
    "winrise-google-docs.desktop",
    "winrise-google-sheets.desktop",
    "winrise-google-gmail.desktop",
    "firefox-esr.desktop",
    "org.kde.kate.desktop",
    "org.kde.konsole.desktop",
    "systemsettings.desktop",
    "org.kde.discover.desktop",
    "org.kde.plasma-systemmonitor.desktop"
]);

// Barra de tarefas só com ícones (como no Windows 10), apps fixados
var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:google-chrome.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:org.kde.discover.desktop"
]);
tasks.writeConfig("groupingStrategy", 1);
tasks.writeConfig("showOnlyCurrentDesktop", false);

panel.addWidget("org.kde.plasma.marginsseparator");

// Bandeja do sistema (rede, som, bateria, notificações) — sem clima, notícias ou widgets
panel.addWidget("org.kde.plasma.systemtray");

// Relógio com data embaixo da hora
var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", 2);
clock.writeConfig("dateFormat", "shortDate");

// Botão "mostrar área de trabalho" no canto direito
panel.addWidget("org.kde.plasma.showdesktop");

// Área de trabalho: papel de parede WinRise e ícones em colunas (como no Windows)
var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    var d = desktopsArray[j];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file:///usr/share/wallpapers/WinRise/");
    d.currentConfigGroup = ["General"];
    d.writeConfig("arrangement", 1);
    d.writeConfig("alignment", 0);
}
