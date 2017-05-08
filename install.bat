robocopy .\ "%AppData%\Sketchup\Sketchup 2016\Sketchup\Plugins" jmSketchupPlugins.rb

IF NOT EXIST "%AppData%\Sketchup\Sketchup 2016\Sketchup\Plugins\jmSketchupPlugins\" mkdir "%AppData%\Sketchup\Sketchup 2016\Sketchup\Plugins\jmSketchupPlugins\"
robocopy  .\jmSketchupPlugins\ "%AppData%\Sketchup\Sketchup 2016\Sketchup\Plugins\jmSketchupPlugins" /e /s
