<?php

function adminer_object() {

    // required to run any plugin
    include_once "../adminer/plugins/plugin.php";
    
    class AdminerCustomization extends AdminerPlugin {
        function css() {
            $theme = $_ENV["ELEDMINER_SETTINGS_THEME"];
            if ($theme === "default") {
                return array("");
            }
            $theme = strtr($theme, " ", "_");
            return array("../adminer/themes/" . $theme. ".css");
        }
    }

    // autoloader
    foreach (glob("../adminer/plugins/*.php") as $filename) {
        include_once "./$filename";
    }
    
    $plugins = array(
        // specify enabled plugins here
    );
    
    /* It is possible to combine customization and plugins:
    class AdminerCustomization extends AdminerPlugin {
    }
    return new AdminerCustomization($plugins);
    */
    
    return new AdminerCustomization($plugins);
}

// include original Adminer or Adminer Editor
include "../adminer/adminer-4.7.7.php";
