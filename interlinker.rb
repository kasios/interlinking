#
#  REST API for Interlinking service
#
# => Alcalá University. Jesús Mayor Márquez.

require "sinatra"
require "json"
require "open-uri"
require "rdf"
require "rdf/ntriples"

configure do
  set :startConfig, {
    "silk_path" => "silk253",
    "silk_data_path" => "C:/Users/kasios/.silk", #needed folder datasets inside
    "tempFiles_path" => "tempFiles",
    "testFile" => "testFiles/exampleText",
    "dataMIME" => "config/mimeList.json",
    "dataTools" => "config/toolsList.json"
  }
end


helpers do
  
  def readTextFile(filePath)
    begin
      data = ""
      File.open(filePath, "r").each_line do |line|
        data+=line
      end
      return data
    rescue =>err
      puts "Exception reading text:#{err}"
      err
    end
  end
  
  def writeTextFile(text,pathFile)
    begin
      File.open(pathFile, 'w') {|f| f.write(text) }
      return true
    rescue =>err
      puts "***Exception reading text:#{err}"
      err
      return false
    end
  end
  
  #It reads a local JSON file and parse to a hash
  def readJSONFile(filePath)
    begin
      data = ""
      File.open(filePath, "r").each_line do |line|
        data+=line
      end
      hashData=JSON.parse(data)
      return hashData
    rescue => err
      puts "Exception:#{err}@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      err
    end
    return nil
  end
  
  #TODO: Analyze mime type. Insecure
  def readURI(myURI)
    data = ""
    open(myURI) {|f|
      f.each_line {|line| data += line}
    }
    return data
  end
  
  #Generates a RDF with a input text.
  def textToRDF(text,tempFolder)

    # split the text coming from command line.
    words = text.split
    # prepare the in-memory RDF repository.
    repository = RDF::Repository.new
    i = 0
    words.each do |w|
      begin
        s = RDF::URI.new("http://mytex.org/#{i}")
        p = RDF::SKOS.label
        o = RDF::Literal.new(w)
        stmt = RDF::Statement.new(s, p, o)
        repository.insert(stmt)
        i=i+1
      end
    end
    FileUtils.mkdir_p(settings.startConfig["silk_data_path"]+"/datasets/#{tempFolder}")
    RDF::Writer.open(settings.startConfig["silk_data_path"]+"/datasets/#{tempFolder}/output.nt") do |writer|
      repository.each_statement do |statement|
        writer << statement
      end
    end
    puts repository
    return repository
  end
  
  #
  #Translate a ntriples to a histogram with the occurrences of words.
  #
  def RDFToHisto(text,tempFolder)
    data = StringIO.new(File.read(settings.startConfig["silk_data_path"]+"/output/#{tempFolder}/accepted_links.nt"))
    histo = Hash.new
    words = text.split
    RDF::NTriples::Reader.new(data) do |reader|
      reader.each_statement do |statement|
        if histo[words[statement.[](2).to_s.split("/")[3].to_i].capitalize] == nil
          histo[words[statement.[](2).to_s.split("/")[3].to_i].capitalize] = [
            statement.[](0).to_s
          ]
        else
          histo[words[statement.[](2).to_s.split("/")[3].to_i].capitalize].push(statement.[](0).to_s)
        end
      end
    end
    return histo
  end
  
  
  #If type = nill, response = list of types. Else return the specific
  #of the defined mimeType.
  #
  #config/mimeList.json
  def mimeTypes(type)
    data = readJSONFile(settings.startConfig["dataMIME"])
    result = ""
    if type == nil
      data["mimeTypes"].each do |element|
        result += element["mimeId"]+"\n"
      end
    else
      data["mimeTypes"].each do |element|
        if element["mimeId"] == type
          result = element["desc"]
        end
      end
    end
    return result
  end
  
  #
  #If type = nill, response = list of tools. Else return the specific data
  #of the defined tool in format JSON.
  #
  #config/toolsListg.json
  def tools(toolInfo)
    data = readJSONFile(settings.startConfig["dataTools"])
    result = nil
    if toolInfo == nil
      result = ""
      data["tools"].each do |element|
        result += element["id"]+"\n"
      end
    else
      data["tools"].each do |element|
        if element["id"] == toolInfo
          result ={
            "id" => element["id"],
            "inputs-supported" =>element["inputs-supported"]
          }.to_json
        end
      end
    end
    return result
  end
  
  #
  #If objField = nill, response = list of fields. Else return the specific data
  #of the defined tool in format JSON.
  #
  #config/toolsList.json
  def toolsResponse(toolInfo, objField)
    data = readJSONFile(settings.startConfig["dataTools"])
    result = nil
    if toolInfo != nil
      if objField == nil
        data["tools"].each do |element|
          if element["id"] == toolInfo
            arr = Array.new
            element["specific-fields"].each do |field|
              arr.push({:id=>field["id"]})
            end
            result = {
              "id" => element["id"],
              "specific-fields" =>arr
            }.to_json
          end
        end
      else
        data["tools"].each do |element|
          if element["id"] == toolInfo
            element["specific-fields"].each do |field|
              if field["id"] == objField
                result = { 
                  "id" => element["id"],
                  "specific-fields" => field["id"],
                  "format-specific-field" => field["format-specific-field"]
                }.to_json
              end
            end
          end
        end
      end
    end
    return result
  end
  
  #Calls needed to work with silk+agrovoc
  def runSilk(tempFolder)
    output = `java -DconfigFile=#{tempFolder}/mylsl.xml -jar #{settings.startConfig["silk_path"]}/silk.jar`
    return true
  end
  
  #This method create a new random folder.
  #returns the pathFolder. Needed delete after work.
  def createTempEnv()
    o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    randomFolderName = (0...50).map{ o[rand(o.length)] }.join
    
    path = settings.startConfig["tempFiles_path"]+"/"+randomFolderName
    FileUtils.mkdir_p(path)
    
    return path
  end
 
  #Calls needed to work with kea+agrovoc
  def runKea(text, pathFolder)
    keaOutput = `java KEAKeyphraseExtractor -l #{pathFolder} -v agrovoc -f skos -m modelAgrovoc50docs -d 2>&1 >/dev/null | grep http`
    data = Array.new
    begin
      keaOutput.each_line do |line|
      #File.open(settings.startConfig["tempFiles_path"]+"/"+"fakeOutput", "r").each_line do |line|
        data.push(line.split(','))
      end
    rescue => err
      puts "***Exception:#{err}@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    end
    result = Array.new
    data.each do |line|
      result.push({
        :uri => line[0],
        :phrase => line[1],
        #TFxIDF
        :relevance => line[2],
        :count => text.capitalize.count(line[1]),
        #Probability
        :confidence => line[6],
        :tool_specific =>{
          :rank => line[7],
          :distance => line[3],
          :nodeIndex => line[4],
          :lenghtIndex => line[5]
        }
        #:idkn => line[8]
      })
    end
    return result
  end
  
  def formatSILK(text,data,limit = 0)
    textWords = text.split.length.to_f
    result = Array.new
    countLimit = 1
    data.each do |k,v|
      wordcount=text.downcase.scan(/#{k.downcase}/).length
      arrlinks = v.uniq
      if limit != 0 or limit != nil
        break if (countLimit >= limit.to_i)
      end
      if (wordcount*arrlinks.length)<textWords
        calc = 1-(1/(wordcount*arrlinks.length.to_f))
      else
        calc = 1
      end
      result.push({
        :uri => v[0],
        :phrase => k,
        #TFxIDF
        :relevance => (wordcount/textWords).round(3),
        :count => wordcount,
        #Probability
        :confidence => (calc).round(3),
        :tool_specific =>{
          :alternativeLinks => arrlinks
        }
        #:idkn => line[8]
      })
      countLimit += 1
    end
    return result
  end
  
  #Adds the basic header for all tools.
  def addHeader(tool,body)
    return {
      :toolid => tool,
      :timestamp => Time.now,
      :links => body
    }
  end
  
  #This method switch between tools.
  def interlinker(params, uri= false)
    if uri
      text = readURI(params["text"])
    else
      text = params["text"]
    end
    if params["tool"] and params["text"]
      case params["tool"]
        when "kea-agrovoc"
          tempFolder = createTempEnv()
          writeTextFile(text,tempFolder+"/out.txt")
          begin
            result = runKea(text,tempFolder)
          rescue => err
            puts "****Exception:#{err}@@@@@@@@@@@@@@@@@@@@@@@@@@"
            err
          end
          FileUtils.rm_rf(tempFolder)
          return addHeader(params["tool"],result).to_json
        when "silk-agrovoc"
          tempFolder = createTempEnv()
          lsl = readTextFile(settings.startConfig["silk_path"]+"/lsl.xml")
          writeTextFile(lsl.sub("output.nt", tempFolder+"/output.nt").sub("accepted_links.nt",tempFolder+"/accepted_links.nt"),
              tempFolder+"/mylsl.xml")
          begin
            textToRDF(text,tempFolder)
            runSilk(tempFolder)
            result = formatSILK(text,RDFToHisto(text,tempFolder),params["limit"])
          rescue => err
            puts "***Exception:#{err}@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
            err
          end
          FileUtils.rm_rf(settings.startConfig["silk_data_path"]+"/datasets/#{tempFolder}")
          FileUtils.rm_rf(settings.startConfig["silk_data_path"]+"/output/#{tempFolder}")
          FileUtils.rm_rf(tempFolder)
          return addHeader(params["tool"], result).to_json
      end
    end
    return nil
  end
end

#1.-Input formats

#1.1.-Lists the supported input formats.
#
#This returns a list of input formats supported by at least one of the tools. 
#It is a convenience call. The list can include MIME types or other if a
#specific formats used.
get "/input/supported/?" do
  status 200
  body mimeTypes(nil)
end

#1.2.-Provides additional information on an input format.
#
#If applicable and not a simple MIME type, provides additional description on
#the input format required. 
get "/input/:first/:second" do
  response = mimeTypes(params[:first]+"/"+params[:second])
  if response != nil
    status 200
    body response
  else
    status 400
    body "Input manager: Input type #{params[:id]} hasn't aviable information"
  end
end

#2.-Interlinking tools

#2.1.-Lists the tools currently available on the service.
#
#This returns a list of the tools that are currently installed and available
#for querying. Note that the same external software package can appear as
#several tools in the service, if it is configured differently. 
get "/tool/list/?" do
  status 200
  body tools(nil)
end

#2.2.-Gets the information on the tool.
#
#This returns a list of the tools that are currently installed and available
#for querying. Note that the same external software package can appear as
#several tools in the service, if it is configured differently. 
get "/tool/:id"  do
  response = tools(params[:id])
  if response != nil
    status 200
    body response
  else
    status 400
    body "Interlinker: Tool #{params[:id]} not available"
  end
end

#2.3.-Provides tools specific fields.
#
#This returns the fields of a tool that are not in common with the rest.
#It can be specific because the field is not provided by all the other tools
#or because the format given is different.
get "/tool/:id/response-fields" do
  response = toolsResponse(params[:id],nil)
  if response != nil
    status 200
    body response
  else
    status 400
    body "Interlinker: Tool #{params[:id]} not available"
  end
end

#2.4.-Provides information about a specific field from a tool.
#
#This returns the information of a specific field of a tool. It can be specific
#because the field is not provided by all the other tools or because the format
#given is different. The information provided will be the specific field and
#its format.
get "/tool/:id/response-fields/:idspec" do
  response = toolsResponse(params[:id],params[:idspec])
  if response != nil
    status 200
    body response
  else
    status 400
    body "Interlinker: Tool #{params[:id]} or field #{params[:idspec]} error"
  end
end

#3.-Simple text interlinking

#3.1.-Invokes an interlinking service passing text as input.
#
#This returns a list with the words from the text that has links with external
#datasets. For each item is also shown 
#‘relevance’ in the text (a double between 0.0 and 1.0 as percentage), 
#‘count’ (number of occurrences) and 
#‘confidence’ (to measure the quality of the alignment, measures as relevance)
post "/fromtext/links/" do
  result = interlinker(params)
  if result 
    status 200
    body result
  else
    status 400
    body "Interlinker: Tool #{params[:id]} not available"
  end
end

#3.2.-Invokes an interlinking service passing text as input.
#
#This returns a list with the words from the text that has links with external
#datasets. The number of items in the list is limited by the argument “limit”
#and is ordered from the highest to the lowest. For each item is also shown
#‘relevance’ in the text (a double between 0.0 and 1.0 as percentage),
#‘count’ (number of occurrences) and
#‘confidence’ (to measure the quality of the alignment, measures as relevance)
post "/fromtext/top_links/" do
  result = interlinker(params)
  if result 
    status 200
    body result
  else
    status 400
    body "Interlinker: Tool #{params[:id]} not available"
  end
end

#3.3.-Invokes an interlinking service passing an uri that contains a text as input
#
#This returns a list with the words from a text stored in an uri that has links
#with external datasets. For each item is also shown 
#‘relevance’ in the text (a double between 0.0 and 1.0 as percentage),
#‘count’ (number of occurrences) and
#‘confidence’ (to measure the quality of the alignment, measures as relevance)
post "/text/links/" do
  result = interlinker(params,true)
  if result 
    status 200
    body result
  else
    status 400
    body "Interlinker: Tool #{params[:id]} not available"
  end
end

#3.4.-Invokes an interlinking service passing an uri that contains a text as input
#
#This returns a list with the words from a text stored in an uri that has links
#with external datasets. The number of items in the list is limited by the
#argument “limit” and is ordered from the highest to the lowest. For each item
#is also shown 
#‘relevance’ in the text (a double between 0.0 and 1.0 as percentage),
#‘count’ (number of occurrences) and
#‘confidence’ (to measure the quality of the alignment, measures as relevance)
post "/text/top_links/" do
  result = interlinker(params,true)
  if result 
    status 200
    body result
  else
    status 400
    body "Interlinker: Tool #{params[:id]} not available"
  end
end 
