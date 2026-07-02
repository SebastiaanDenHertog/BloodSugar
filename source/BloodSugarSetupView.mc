
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import BloodSugarStore;

class BloodSugarSetupView extends WatchUi.View {

    public function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onShow() as Void {

    }

    public function onUpdate(dc as Dc) as Void {
       
    }

    function onHide() as Void {
    }

}
