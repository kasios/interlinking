Interlinking service
====================

This code implements a REST-based interlinking service wrapping existing extraction and interlinking tools. Clients can query the tools available, getting info on the input format they support and the parameters to configure them. Then, they can issue calls and get suggested links to datasets in the Web of Data for potential inclusion in their contents or for other purposes.

This wrapped tools analyse text with the purpose of find matching terms in target datasets. Actually, the service is working, in general, with the dataset of Agrovoc. Agrovoc is a controlled vocabulary covering all areas of interest to FAO, including food, nutrition, agriculture, fisheries, forestry, environment etc. Tools like KEA uses this dataset to analyse a document of agriculture and find references to URIs in the agrovoc ontology, giving metrics in the process. However, tools like silk only can make relations between the words and the URIs and the metrics should be calculated in a post-process part. Anyway, all final responses of this API are designed to send the information in JSON with this format.
```JSON
{   
  “tool-id” : “<id of the tool invoked>”,
        “timestamp” : “<YYYY-MM-DDThh:mm:ssTZD>”
  “links” : [
  	<Finded occurrences>
  ]
}
```

API design
==========
Following, I will define all the calls that you can make to this service:

Input formats:
* GET /input/supported ->	Lists the supported input formats
This returns a list of input formats supported by at least one of the tools. It is a convenience call. The list can include MIME types or other if a specific formats used. (Output can be easy configurable)
* GET /input/{id}	Provides additional information on an input format.
If applicable and not a simple MIME type, provides additional description on the input format required. (Output can be easy configurable)

Interlinking tools:
* GET /tool/list ->	Lists the tools currently available on the service.
This returns a list of the tools that are currently installed and available for querying. Note that the same external software package can appear as several tools in the service, if it is configured differently
* GET /tool/{id} ->	Gets the information on the tool
This returns a list of the tools that are currently installed and available for querying. Note that the same external software package can appear as several tools in the service, if it is configured differently. The common information for all the tools is the following:
```
{
      “id” : “<tool id>”,
      “inputs-supported” : [ {“id”=””},  {“id”=””} …  ]  
}
```
* GET /tool/{id}/response-fields -> Provides tools specific fields.
This returns the fields of a tool that are not in common with the rest. It can be specific because the field is not provided by all the other tools or because the format given is different.
e.g. The confidence could be given as a percentage from 0 to 100 or using tags like “Equivalent”, “Approximate” … 
The information will be given like this:
```
{
      “id” : “<tool id>”,
      “specific-fields” : [ {“id”=””},  {“id”=””} …  ]  
}
```
* GET /tool/{id}/response-fields/{id} -> Provides information about a specific field from a tool
This returns the information of a specific field of a tool. It can be specific because the field is not provided by all the other tools or because the format given is different. The information provided will be the specific field and its format
The information will be given like this:
```
{
      “id” : “<tool id>”, 
      “id” : “<specific-field id>”,
      “format-specific-field” : [ {“format”},  {“format”} …  ]  
}
```
Simple text interlinking
* POST /fromtext/links/?tool={tool-id}&text=value -> Invokes an interlinking service passing text as input
This returns a list with the words from the text that has links with external datasets. For each item is also shown ‘relevance’ in the text (a double between 0.0 and 1.0 as percentage), ‘count’ (number of occurrences) and ‘confidence’ (to measure the quality of the alignment, measures as relevance)
```
{
      “link” : “<string>”,
      “relevance” : “<double>”,
      “count” : “<integer>”,
      “confidence” : “<double>”
}
```
* POST /text/links/?tool={tool-id}&text=value -> Invokes an interlinking service passing an uri that contains a text as input
This returns a list with the words from a text stored in an uri that has links with external datasets. For each item is also shown ‘relevance’ in the text (a double between 0.0 and 1.0 as percentage), ‘count’ (number of occurrences) and ‘confidence’ (to measure the quality of the alignment, measures as relevance)
```
{
      “link” : “<string>”,
      “relevance” : “<double>”,
      “count” : “<integer>”,
      “confidence” : “<double>”
}
```
* POST /text/top_links/?tool={tool-id}&text=value&limit=value -> Invokes an interlinking service passing an uri that contains a text as input
This returns a list with the words from a text stored in an uri that has links with external datasets. The number of items in the list is limited by the argument “limit” and is ordered from the highest to the lowest. For each item is also shown ‘relevance’ in the text (a double between 0.0 and 1.0 as percentage), ‘count’ (number of occurrences) and ‘confidence’ (to measure the quality of the alignment, measures as relevance)
```
{
      “uri” : “<uri string>”,
      “relevance” : “<double>”,
      “count” : “<integer>”,
      “confidence” : “<double>”
}
```


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
