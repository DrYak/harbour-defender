import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.4
import "pages"

ApplicationWindow
{
    id: mainWindow
    initialPage: Component { WelcomePage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.All
    _defaultPageOrientations: Orientation.All
    property string appName: qsTr("Defender")
    property string appname: appName.toLowerCase()
    property date last_update

    property bool updating: true

    property var cookieBlacklist: []
    property var cookieWhitelist: []
    property bool cookiesLocked
    property var stats

    Python {
        id: py
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('python'));
            importModule(appname, function() {
                call(appname+'.load_sources', [], function (result) {
                    for (var i = 0; i < result.length; i++) {
                        sourcesModel.append(result[i])
                    }
                });
                call(appname+'.cookie_load_list', [false], function (result) {
                    cookieWhitelist = result
                });
                call(appname+'.cookie_load_list', [true], function (result) {
                    cookieBlacklist = result
                });
                call(appname+'.cookie_is_locked', [], function (result) {
                    cookiesLocked = result
                });
                call(appname+'.get_stats', [], function (result) {
                    stats = result
                });
            });
            importModule('os', function() {
                call('os.getcwd', [], function(result) {
                    console.log('Working directory: ' + result);
                })
            })
        }
    }
    ListModel {
        id: sourcesModel
    }

    function changeConfig(section, key, value, index) {
        py.call(appname+'.change_config', [section, key, value], function(result) {
            console.log(result);
            sourcesModel.setProperty(index, key, value)
        })
    }

    function updateNow() {
        py.call(appname+'.update_now', [], function(result) {
            updating = true
        })
    }

    function disableAll() {
        py.call(appname+'.disable_all', [], function(result) {
            sourcesModel.clear()
            for (var i = 0; i < result.length; i++) {
                sourcesModel.append(result[i])
            }
        })
    }

    Timer {
        id: updatingTimer
        running: updating
        interval: 2000
        repeat: true
        onTriggered: {
            py.call(appname+'.check_update', [], function(result) {
                updating = result
                if (!updating) {
                    py.call(appname+'.get_stats', [], function (result) {
                        stats = result
                    });
                }
            })
        }
    }
}

