interlinking
============

A REST-based interlinking service wrapping existing extraction and interlinking tools

Install
=======

1.- KEA:
Download and unzip kea 4.1 from: http://www.nzdl.org/Kea/Download/kea-4.1.zip
Set KEAHOME to be the directory which contains your kea 4.1 instalation. (command export)
Add $KEAHOME to your CLASSPATH environment variable.
Add $KEAHOME/lib/*.jar to your CLASSPATH environment variable.

2.- SILK:
Download and unzip silk 2.5.3 from: http://wifo5-03.informatik.uni-mannheim.de/bizer/silk/releases/
Copy the unziped silk.jar to your interlinker/silk253 folder.
Create the folder $HOME/.silk/datasets/ -> C://Users/<Username> in windows

3.- RUBY:
Install a ruby 1.9.1 or higher.
Install ruby with gems: rdf, sinatra, test-unit and json

4.- CONFIGURATION:
Copy this model http://www.nzdl.org/Kea/Download/Agrovoc50docs to interlinker/modelAgrovoc50docs (renamed)
Copy the theasaurus http://www.nzdl.org/Kea/Download/vocabularies/agrovoc.skos.zip (unzipped) to interlinker/VOCABULARIES/agrovoc.rdf
Edit interlinker.rb to introduce the silk workpath (variable "silk_data_path" (line 15)). In windows by default is "C:/Users/<username>/.silk", in linux "$HOME/.silk"
Copy the same agrovoc.rdf in .silk/datasets/

5.- RUNNING
Run interlinker.rb.
Tou can run the file client.rb and test the service.

Issues:

If kea doesn't work, you can test it with this command:
java KEAKeyphraseExtractor -l <aFolderWithAText> -v agrovoc -f skos -m modelAgrovoc50docs -d
This commad will identify missing files. If java doesn't recognize KeaKeyphraseExtractor, probably you added bad the environment variables. Take a look to the point 1.

If silk doesn't work, use this comand:
java -DconfigFile=silk253/lsl.xml -jar silk253/silk.jar Probably it wont find few files because lsl.xml isn't defined to work without modifications.
